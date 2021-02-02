SuperStrict

Framework BRL.Filesystem
Import BRL.StandardIO
Import BRL.Threads
Import BRL.ThreadPool
Import BRL.Map

Import "LunrCompatible/Tokenizer.bmx"
Import "LunrCompatible/Trimmer.bmx"
Import "LunrCompatible/Stopwords.bmx"
Import "LunrCompatible/Stemmer.bmx"
Import "LunrCompatible/IDF.bmx"

Import "LunrCompatible/InvertedIndex.bmx"
Import "LunrCompatible/TermFreq.bmx"


' Custom types
'===========================================================================================
Type TTask Extends TRunnable
	Field Thread:TThread
	
	Field Filename:String
	Field ID:Int
	
	Method Run()
		ProcessFile(Self)
	End Method
End Type

Type TDocument
	Field Filename:String
	Field TermsTotal:Int = 0
	Field Terms:TStringMap
	Field ID:Int
End Type
'===========================================================================================

Local StartMS:ULong = MilliSecs()

Local Directory:String[] = LoadDir(".")
Global Documents:TDocument[] = New TDocument[Directory.length]

Global TermsInDocuments:TStringMap = New TStringMap
Global WriteMutex:TMutex = CreateMutex()


Local Task:TTask
Local DocumentCount:Int = 0

Local Pool:TThreadPoolExecutor = TThreadPoolExecutor.newFixedThreadPool(4)

For Local Filename:String = EachIn Directory
	
	' We're only interested in .txt files
	If ExtractExt(Filename) <> "txt" Then Continue
	
	' Spawn a new task
	Task = New TTask
	
	Task.Filename = Filename
	Task.ID = DocumentCount
	
	Pool.execute(Task)
	
	DocumentCount :+ 1
Next

Pool.shutdown()

' Slice away the unused slots
Documents = Documents[..DocumentCount]

Print "Performance: " + DocumentCount + " documents parsed in " + (MilliSecs() - StartMS) + "ms"
StartMS = MilliSecs()

Local Output:TStream = WriteFile("json_v1.js")

' ===== Calculate lunr inverse index and TF tables =====
Local TermFrequencyIdx:TermFrequencyIndex = New TermFrequencyIndex
Local InvertedIdx:TInvertedIndex = New TInvertedIndex
Local TermCntIdx:TermCountIndex = New TermCountIndex

TermFrequencyIdx.Init()
InvertedIdx.Init()
TermCntIdx.Init()

For Local Document:TDocument = EachIn Documents
	Local Hashmap:TStringMap = Document.Terms
	
	TermCntIdx.Add(Document.ID, Document.TermsTotal)
	TermFrequencyIdx.Add(Document.ID, Hashmap)
	
	For Local Key:String = EachIn Hashmap.Keys
		InvertedIdx.Add(Key, Document.ID)
	Next
Next


WriteString(Output, "// Prebaked Lunr Index v1.0~n")
WriteString(Output, "var z = {}~n")
WriteString(Output, "search.idx = {}~n")

WriteString(Output, "search.idx.invertedIndex = ")
InvertedIdx.ToJSON(Output)

WriteString(Output, "search.idx.fieldTermFrequencies = ")
TermFrequencyIdx.ToJSON(Output)

WriteString(Output, "search.idx.fieldLengths = ")
TermCntIdx.ToJSON(Output)



WriteString(Output, "search.idx.id_to_filename = {")
For Local Document:TDocument = EachIn Documents
	WriteUTF8String(Output, Document.ID + ":~q" + Document.Filename + "~q, ")	
Next
WriteString(Output, "}~n")

WriteString(Output, "search.idx.documentCount = " + DocumentCount + "~n")
WriteString(Output, "search.idx.termIndex = " + InvertedIdx.ID + "~n")
WriteString(Output, "search.init_lunr_from_prebaked()~n")

Print "Performance: " + (StreamPos(Output) / 1024) + " KB of worth of output produced in " + (MilliSecs() - StartMS) + "ms"

CloseFile(Output)


'
' Here the magic resides!
'  1. Reading the file into the memory
'  2. Tokenization											ON RAW MEMORY
'  3. Trimming the head										ON RAW MEMORY
'  4. Checking whether there's still a word left			ON RAW MEMORY
'  5. Trimming the tail										ON RAW MEMORY
'  6. Stop-list filtering									ON RAW MEMORY
'  7. Parsing as UTF-8
'  8. Find&replace sequences not allowed in JSON
'  9. Converting to lowercase
' 10. Stemming
' 11. Building document's term hashmap
'
' Current list of tradeoffs
' 1. All unicode leads to trimmer disengagement
' 2. All tokens with JSON-unfriendly symbols are thrown away
' 3. JSON-unfriendly EXCEPT the [ ' ] symbol, the [ ' ] is replaced into an empty
'
'
Function ProcessFile:Object(Arg:Object)
	Local Task:TTask = TTask(Arg)
	Local Filename:String = Task.Filename
	Local File:TStream
			
	' Process data
	File = OpenFile(Filename)
	
	If Not File
		RuntimeError "Couldn't open " + Filename + "; File is locked?."
	End If
	
	Local Size:Size_T = StreamSize(File)
	Local Buffer:Byte Ptr = MemAlloc(Size + 1)
	Local Status:Int = File.Read(Buffer, Size)
	
	If Status < Size
		RuntimeError "Read error"
	End If
	
	CloseFile(File)
	
	' Null terminate forcibly
	Buffer[Size] = 0
	
	
	' Tokenize
	Local Offsets:Int[] = Tokenize(Buffer, Size + 1)
	
	Local Hashmap:TStringMap = New TStringMap
	Local Total:Int = 0
	
	For Local TokenOffset:Int = EachIn Offsets
		' 1. Trim non-word characters from the start
		' 2. Null terminator run-in check
		' 3. Trim non-word characters from the end
		' 4. Stop word list check
		
		TokenOffset :+ TrimStart(Buffer + TokenOffset)
		If Buffer[TokenOffset] = 0 Then Continue
		TrimEnd(Buffer + TokenOffset)
		If Not is_word_allowed(Buffer + TokenOffset) Then Continue
		If Not IsFineWithJSON(Buffer + TokenOffset) Then Continue
		
		' Parse as UTF-8
		Local Token:String = String.FromUTF8String(Buffer + TokenOffset)        '.Replace("\", "\\").Replace("~q", "\~q")
		
		' Register into the hashmap
		' Skip empty strings
		If Token = "" Then RuntimeError("Preprocessing missed something: an empty string was parsed")
		
		' Make all lowercase and pass through the stemmer
		Local Stem:String = PorterStemmer(Token.ToLower().Replace("'", ""))
		
		' If stemmer annihilated the word, well...
		If Stem = "" Then RuntimeError("Stemmer destroyed a word")
		
		Local Term:TTerm = TTerm( Hashmap[Stem] )
		
		' Create if doesn't yet exist
		If Term = Null
			Term = New TTerm
			Hashmap[Stem] = Term
		End If
		
		Term.Count :+ 1
		Total :+ 1
	Next
	
	MemFree Buffer
	
	
	' Commit the results
	' Thread synchronization can be placed here
	Local Document:TDocument = New TDocument
	
	Document.Filename = Filename
	Document.TermsTotal = Total
	Document.Terms = Hashmap
	Document.ID = Task.ID
	
	LockMutex(WriteMutex)
	Documents[Document.ID] = Document
	
	UnlockMutex(WriteMutex)
End Function


' Fighting standard library bugs: WriteString() destroys unicode
' Pull the C strlen()
Extern 
	Function strlen:Size_T(str:Byte Ptr)
End Extern

' Make a custom write function for UTF-8 strings
Function WriteUTF8String(Stream:TStream, Str:String)
	Local UTF8String:Byte Ptr = Str.ToUTF8String()
	Stream.Write(UTF8String, strlen(UTF8String))
	MemFree(UTF8String)
End Function



