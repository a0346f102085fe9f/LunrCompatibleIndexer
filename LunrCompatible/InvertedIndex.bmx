Framework BRL.StandardIO
Import BRL.Map

Import "MiniJSON.bmx"

' One more datatype for terms (This is like the third one already?)
' Contains an ID and the map of documents where the term occurs
'
' Initially IDs were generated at write-time, in ToJSON(), and were only aligned alphabetically as a result
' Now IDs are assigned at document insertion time, and are grouped by document first
' Chances are that the neighbouring IDs will be of terms that were first discovered within the same document
'
' I don't think Lunr utilizes that, but YOU can!
'
Type TInvIdxTerm
	Field ID:Int
	Field InDocuments:TIntMap
End Type


' Lunr-compatible inverted index
' Hardcoded to `a` field
' A little slow
' IntMap could probably be replaced with a linked list to make it a little faster
Type TInvertedIndex
	Field Terms:TStringMap
	Field JSON:MiniJSON
	Field ID:Int
	
	Method Init()
		Terms = New TStringMap
		JSON = New MiniJSON
		ID = 0
	End Method
	
	Method Add(Term:String, DocumentID:Int)
		Local ITerm:TInvIdxTerm = TInvIdxTerm( Terms[Term] )
		
		If ITerm = Null
			ITerm = New TInvIdxTerm
			Terms[Term] = ITerm
			
			ITerm.InDocuments = New TIntMap
			ITerm.ID = ID
			
			ID :+ 1
		End If
		
		ITerm.InDocuments[DocumentID] = New Object
	End Method
	
	Method ToJSON(Stream:TStream)
		Local ITerm:TInvIdxTerm
	
		For Local Term:String = EachIn Terms.Keys
			ITerm = TInvIdxTerm( Terms[Term] )
			
			JSON.EnterSublevel("~q"+Term+"~q")
			' JSON.Add("__proto__", "null")
			JSON.Add("~q_index~q", ITerm.ID)
			JSON.EnterSublevel("~qa~q")
			' JSON.Add("__proto__", "null")
					
			For Local Key:TIntKey = EachIn ITerm.InDocuments.Keys
				JSON.Add("~q"+Key.Value+"~q", "0")
			Next
			
			JSON.ExitSublevel()
			JSON.ExitSublevel()
		Next
		
		JSON.Write(Stream)
	End Method
End Type
