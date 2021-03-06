Framework BRL.StandardIO
Import "lowlevel_setlen.c"

' FIXME: string hash breakage on newer BlitzMax
Extern
	Function setlen(In:String, Length:Int)
End Extern

'
' A partial implementation of Porter stemmer, the same stemmer that Lunr uses
' http://snowball.tartarus.org/algorithms/porter/stemmer.html
' Implements steps 1abc, 2, and 3
'
' This implementation doesn't stick to the original algorithm (Well, neither does the lunr.js variant)
'
' Lunr.js stemmer has following differences from the vanilla algorithm:
' - In step 2, `logi` is replaced into `log`
'
' This stemmer has following differences from the vanilla algorithm:
' - An additional `Restore_Y` step: (m>0) I -> Y
'   Turns `poni` into `pony` and `technologi` into `technology`
'

' Please supply lowercase only
Function PorterStemmer:String(Word:String)
	Local L = Word.length
	
	' Skip very short words
	If L < 3 Then Return Word
	
	' You can take some of the steps out to achieve more precision:
	' Slight preening		Leave only 1ab and Restore_Y
	' Moderate preening		Leave 1abc, 2, 3 and Restore_Y

	Return Restore_Y( Step_3( Step_2( Step_1c( Step_1b( Step_1a( Word ) ) ) ) ) ) End Function

Function Step_1a:String(Word:String)
	Local L = Word.length
	
	If Word.EndsWith("sses")
		setlen(Word, L - 2)
		Return Word
	End If
	
	If Word.EndsWith("ies")
		setlen(Word, L - 2)
		Return Word
	End If
	
	If Word.EndsWith("ss")
		' No change, but prevents the next check from happening
		Return Word
	End If
	
	If Word.EndsWith("s")
		setlen(Word, L - 1)
		Return Word
	End If
	
	Return Word
End Function

Function Step_1b:String(Word:String)
	Local L = Word.length
	
	If Word.EndsWith("eed")
		If Measure(Word, L - 3) > 0
			setlen(Word, L - 1)
		End If
		
		Return Word
	End If
	
	If Word.EndsWith("ed")
		If HasVowels(Word, L - 2)
			setlen(Word, L - 2)
			Return Step_1b_restore(Word)
		Else
			Return Word
		End If
	End If
	
	If Word.EndsWith("ing")
		If HasVowels(Word, L - 3)
			setlen(Word, L - 3)
			Return Step_1b_restore(Word)
		Else
			Return Word
		End If
	End If
	
	Return Word
End Function

Function Step_1b_restore:String(Stem:String)
	Local L:Int = Stem.Length

	If Stem.endsWith("at")
		Return Stem + "e"
	End If
	
	If Stem.endsWith("bl")
		Return Stem + "e"
	End If
	
	If Stem.endsWith("iz")
		Return Stem + "e"
	End If

	If Not (Stem[L - 1] = 108 Or Stem[L - 1] = 115 Or Stem[L - 1] = 122)
		If EndsWith2C(Stem)
			setlen(Stem, L - 1)
			Return Stem
		End If
	End If
	
	If EndsWithCVC(Stem) And Measure(Stem) = 1
		Return Stem + "e"
	End If
	
	Return Stem
End Function

Function Step_1c:String(Stem:String)
	Local L:Int = Stem.Length
	
	If (Stem[L - 1] = 121 And HasVowels(Stem))
		Stem[L - 1] = 105 ' Letter i
	End If
	
	Return Stem
End Function

Function Step_2:String(Stem:String)
	Local L:Int = Stem.Length
	
	' Can't possibly do anything if the word is shorter than 5 letters
	' Minimal sequence to trigger something here is [vc]eli
	' Moreover, less than 2 letters will cause a crash
	If L < 5 Then Return Stem
		
	' Narrow down the string matching using the penultimate letter
	' Really need a native ReplaceLast()...
	Select Stem[L - 2]
		Case 97 ' Penultimate `a`		
			If ( Stem.EndsWith("ational") And Measure(Stem, L - 7) > 0 )
				setlen(Stem, L - 4)
				Stem[L - 5] = 101
				
			Else If ( Stem.EndsWith("tional") And Measure(Stem, L - 6) > 0 )
				setlen(Stem, L - 2)
				
			End If
			
		Case 99 ' Penultimate `c`
			If ( Stem.EndsWith("enci") And Measure(Stem, L - 4) > 0 ) Or ..
			   ( Stem.EndsWith("anci") And Measure(Stem, L - 4) > 0 )
			
				Stem[L - 1] = 101
			End If
			
		Case 101 ' Penultimate `e`
			If ( Stem.EndsWith("izer") And Measure(Stem, L - 4) > 0 )
				setlen(Stem, L - 1)
				
			End If
			
		Case 108 ' Penultimate `l`
			If ( Stem.EndsWith("abli") And Measure(Stem, L - 4) > 0 )
				Stem[L - 1] = 101 
				
			Else If ( Stem.EndsWith("alli")  And Measure(Stem, L - 4) > 0 ) Or ..
			   		( Stem.EndsWith("entli") And Measure(Stem, L - 5) > 0 ) Or .. 
			   		( Stem.EndsWith("eli")   And Measure(Stem, L - 3) > 0 ) Or ..
			   		( Stem.EndsWith("ousli") And Measure(Stem, L - 5) > 0 )
			
				setlen(Stem, L - 2)
			End If
			
		Case 111 ' Penultimate `o`
			If ( Stem.EndsWith("ization") And Measure(Stem, L - 7) > 0 )
				setlen(Stem, L - 4)
				Stem[L - 5] = 101
				
			Else If ( Stem.EndsWith("ation") And Measure(Stem, L - 5) > 0 )
				setlen(Stem, L - 2)
				Stem[L - 3] = 101
				
			Else If ( Stem.EndsWith("ator")  And Measure(Stem, L - 4) > 0 )
				setlen(Stem, L - 1)
				Stem[L - 2] = 101
				
			End If 
			
		Case 115 ' Penultimate `s`
			If ( Stem.EndsWith("alism") And Measure(Stem, L - 5) > 0 )
				setlen(Stem, L - 3)
				
			Else If ( Stem.EndsWith("iveness") Or ..
					  Stem.EndsWith("fulness") Or ..
					  Stem.EndsWith("ousness") ) And Measure(Stem, L - 7) > 0
			
				setlen(Stem, L - 4)
			End If 
			
		Case 116 ' Penultimate `t`
			Local Aliti:Int = Stem.EndsWith("aliti")
			
			If ( Stem.EndsWith("aliti") And Measure(Stem, L - 5) > 0 )
				setlen(Stem, L - 3)
			
			Else If ( Stem.EndsWith("iviti") And Measure(Stem, L - 5) > 0 )
				setlen(Stem, L - 2)
				Stem[L - 3] = 101
					
			Else If Stem.EndsWith("biliti") And Measure(Stem, L - 6) > 0
				setlen(Stem, L - 3)
				Stem[L - 4] = 101
				Stem[L - 5] = 108
				
			End If 
			
	End Select
		
	
	Return Stem
End Function

Function Step_3:String(Stem:String)
	Local L:Int = Stem.Length
	
	' Can't possibly do anything if the word is shorter than 5 letters
	' Minimal sequence to trigger something here is [vc]ful
	If L < 5 Then Return Stem
	
	' Use the last letter to narrow down
	Select Stem[L - 1]
		Case 101 ' Last `e`
			If ( Stem.EndsWith("icate") Or ..
				 Stem.EndsWith("alize") ) And Measure(Stem, L - 5) > 0
				
				setlen(Stem, L - 3)
			Else If ( Stem.EndsWith("ative") And Measure(Stem, L - 5) > 0 )
				setlen(Stem, L - 5)

			End If
			
		Case 105 ' Last `i`
			If ( Stem.EndsWith("iciti") And Measure(Stem, L - 5) > 0 )
				setlen(Stem, L - 3)
				
			End If
			
		Case 108 ' Last `l`
			If ( Stem.EndsWith("ical") And Measure(Stem, L - 4) > 0 )
				setlen(Stem, L - 2)
			
			Else If ( Stem.EndsWith("ful") And Measure(Stem, L - 3) > 0 )
				setlen(Stem, L - 3)
				
			End If
			
		Case 115 ' Last `s`
			If ( Stem.EndsWith("ness") And Measure(Stem, L - 4) > 0 )
				setlen(Stem, L - 4)
				
			End If

	End Select

	Return Stem
End Function

' Partial step 4
' Probably will remanin unused
Function Step_4:String(Stem:String)
	Local L:Int = Stem.Length

	' Can't possibly do anything if the word is shorter than 4 letters
	' Minimal sequence to trigger something here is [vc]ou
	If L < 4 Then Return Stem

	' Use the penultimate letter to narrow down
	Select Stem[L - 2]
		Case 97 ' Penultimate `a`
		Case 99 ' Penultimate `c`
			If ( Stem.EndsWith("ance") And Measure(Stem, L - 4) > 1 )
				setlen(Stem, L - 4)
				
			Else If ( Stem.EndsWith("ence") And Measure(Stem, L - 4) > 1 )
				setlen(Stem, L - 4)
			
			End If

		Case 101 ' Penultimate `e`
		Case 105 ' Penultimate `i`
		Case 108 ' Penultimate `l`
			If ( Stem.EndsWith("able") And Measure(Stem, L - 4) > 1 )
				setlen(Stem, L - 4)
				
			Else If ( Stem.EndsWith("ible") And Measure(Stem, L - 4) > 1 )
				setlen(Stem, L - 3)
				Stem[L - 4] = 101
				
			End If
			
		Case 110 ' Penultimate `n`				
			If ( Stem.EndsWith("ment") And Measure(Stem, L - 4) > 1 )
				setlen(Stem, L - 4)
				
			ElseIf ( Stem.EndsWith("ent") And Measure(Stem, L - 3) > 1 )
				setlen(Stem, L - 3)

			End If
			
		Case 111 ' Penultimate `o`
		Case 115 ' Penultimate `s`
		Case 116 ' Penultimate `t`
			' Modification: `iti` needs (m>2) To fix some failure cases
			If ( Stem.EndsWith("iti") And Measure(Stem, L - 3) > 2 )
				setlen(Stem, L - 3)
			End If
			
		Case 117 ' Penultimate `u`
		Case 118 ' Penultimate `v`
			If ( Stem.EndsWith("ive") And Measure(Stem, L - 3) > 1 )
				setlen(Stem, L - 3)
			End If
			
		Case 122 ' Penultimate `z`
	End Select
	
	Return Stem
End Function

' Restore the y letters that might've been replaced into an i
Function Restore_Y:String(Stem:String)
	Local L:Int = Stem.Length
	
	If ( Stem[L - 1] = 105 And Measure(Stem, L - 1) > 0 )
		Stem[L - 1] = 121
	End If
	
	Return Stem
End Function

Function Consonant(Word:String, Index:Int)
	Select Word[Index]
		Case 97, 101, 105, 111, 117
			Return False
		Case 121
			If Index = 0
				Return True
			Else
				Return Consonant(Word, Index - 1)
			End If
		Default
			Return True
	End Select
End Function

' Ends with double consonant, as in the same letter twice 
Function EndsWith2C(Word:String)
	Local L:Int = Word.Length
	
	If L < 2 Then Return False
	
	If ( Word[L - 1] = Word[L - 2] )
		If Consonant(Word, L - 2)
			Return True
		End If
	End If
	
	Return False
End Function

' Ends with Consonant, Vovel, Consonant*
' * Second consonant can't be W, X or Y
Function EndsWithCVC(Word:String)
	Local L:Int = Word.Length
	Local Last:Int = Word[L - 1]
	
	If L < 3 Then Return False
	If Last = 119 Or Last = 120 Or Last = 121 Then Return False
	
	Return Consonant(Word, L - 1) And (Not Consonant(Word, L - 2)) And Consonant(Word, L - 3)
End Function

' Detect vowels
Function HasVowels(Word:String)
	Local i:Int = Word.Length - 1
	
	While i >= 0
		If Not Consonant(Word, i) Then Return True
		i :- 1
	Wend
	
	Return False
End Function

' Detect vowels, but with a fixed length
Function HasVowels(Word:String, FixedLength:Int)
	Local i:Int = FixedLength - 1
	
	While i >= 0
		If Not Consonant(Word, i) Then Return True
		i :- 1
	Wend
	
	Return False
End Function

' Detect VC sequences
Function Measure(Word:String)	
	Local Offset:Int = 0
	Local Count:Int = 0
	Local L:Int = Word.Length
	
	While True
		If Offset >= L Then Return Count
		If Not Consonant(Word, Offset) Then Exit
		
		Offset :+ 1
	Wend
	
	Offset :+ 1
	
	While True
		While True
			If Offset >= L Then Return Count
			If Consonant(Word, Offset) Then Exit
			
			Offset :+ 1
		Wend
		
		Offset :+ 1
		Count :+ 1
		
		While True
			If Offset >= L Then Return Count
			If Not Consonant(Word, Offset) Then Exit
			
			Offset :+ 1
		Wend
		
		Offset :+ 1
	Wend
End Function

' Detect VC sequences but with a fixed length
Function Measure(Word:String, FixedLength:Int)	
	Local Offset:Int = 0
	Local Count:Int = 0
	Local L:Int = FixedLength
	
	If L < 0
		RuntimeError("Measure: FixedLength is negative!")
	End If
	
	While True
		If Offset >= L Then Return Count
		If Not Consonant(Word, Offset) Then Exit
		
		Offset :+ 1
	Wend
	
	Offset :+ 1
	
	While True
		While True
			If Offset >= L Then Return Count
			If Consonant(Word, Offset) Then Exit
			
			Offset :+ 1
		Wend
		
		Offset :+ 1
		Count :+ 1
		
		While True
			If Offset >= L Then Return Count
			If Not Consonant(Word, Offset) Then Exit
			
			Offset :+ 1
		Wend
		
		Offset :+ 1
	Wend
End Function


Rem
' Step 1a and 1b test set
Print PorterStemmer("feed")
Print PorterStemmer("agreed")
Print PorterStemmer("plastered")
Print PorterStemmer("bled")
Print PorterStemmer("motoring")
Print PorterStemmer("sing")
Print PorterStemmer("sings")
Print PorterStemmer("conflated")
Print PorterStemmer("troubled")
Print PorterStemmer("sized")
Print PorterStemmer("hopping")
Print PorterStemmer("tanned")
Print PorterStemmer("hissing")
Print PorterStemmer("fizzed")
Print PorterStemmer("fizzled")
Print PorterStemmer("fizzlepop")
Print PorterStemmer("failing")
Print PorterStemmer("filing")
End Rem

Rem
' Step 1c test set
Print Step_1c("happy")
Print Step_1c("sky")
End Rem

Rem
' Step 2 test set
Print Step_2("relational")
Print Step_2("conditional")
Print Step_2("rational")
Print Step_2("valenci")
Print Step_2("hesitanci")
Print Step_2("digitizer")
Print Step_2("conformabli")
Print Step_2("radicalli")
Print Step_2("differentli")
Print Step_2("vileli")
Print Step_2("analogousli")
Print Step_2("vietnamization")
Print Step_2("predication")
Print Step_2("operator")
Print Step_2("feudalism")
Print Step_2("decisiveness")
Print Step_2("hopefulness")
Print Step_2("callousness")
Print Step_2("formaliti")
Print Step_2("sensitiviti")
Print Step_2("sensibiliti")


' Step 2 extended test set
' Some made up words
' They all should come out unaltered!
Print Step_2("a")
Print Step_2("bational")
Print Step_2("btional")
Print Step_2("denci")
Print Step_2("danci")
Print Step_2("phizer")
Print Step_2("fabli")
Print Step_2("galli")
Print Step_2("gentli")
Print Step_2("geli")
Print Step_2("gousli")
Print Step_2("hization")
Print Step_2("hation")
Print Step_2("hator")
Print Step_2("ialism")
Print Step_2("diveness")
Print Step_2("dfulness")
Print Step_2("dousness")
Print Step_2("zaliti")
Print Step_2("ziviti")
End Rem

Rem
' Step 3 test set
Print Step_3("triplicate")
Print Step_3("formative")
Print Step_3("formalize")
Print Step_3("electriciti")
Print Step_3("electrical")
Print Step_3("hopeful")
Print Step_3("goodness")

' Step 3 extended test set
Print Step_3("dicate")
Print Step_3("fative")
Print Step_3("galize")
Print Step_3("hiciti")
Print Step_3("jical")
Print Step_3("kful")
Print Step_3("lness")
End Rem

Rem
' Step 4 partial test set
Print Step_4("allowance")
Print Step_4("inference")
Print Step_4("adjustable")
Print Step_4("defensible")
Print Step_4("replacement")
Print Step_4("ajdustment")
Print Step_4("dependent")
Print Step_4("angulariti")
Print Step_4("securiti") ' Failure case
Print Step_4("effective")
End Rem

Rem
' Test with different forms of the same word
Print PorterStemmer("accept")
Print PorterStemmer("accepted")
Print PorterStemmer("accepting")
Print PorterStemmer("acceptance")
End Rem
