Framework BRL.StandardIO

'
' A partial implementation of Porter stemmer, the same stemmer that Lunr uses
' http://snowball.tartarus.org/algorithms/porter/stemmer.html
' Implements only steps 1ab (Out of more than 5 steps)
'

' Please supply lowercase only
Function PorterStemmer:String(Word:String)
	Local WLen = Word.length
	
	' Skip very short words
	If WLen < 3 Then Return Word
	
	
	Return Step_1b(Step_1a(Word))
End Function

Function Step_1a:String(Word:String)
	Local WLen = Word.length
	
	If Word.EndsWith("sses")
		Return Word[..WLen - 2]
	End If
	
	If Word.EndsWith("ies")
		Return Word[..WLen - 2]
	End If
	
	If Word.EndsWith("ss")
		' No change, but prevents the next check from happening
		Return Word
	End If
	
	If Word.EndsWith("s")
		Return Word[..WLen - 1]
	End If
	
	Return Word
End Function

Function Step_1b:String(Word:String)
	Local WLen = Word.length
	Local Stem:String
	
	If Word.EndsWith("eed")
		Stem = Word[..WLen - 3]
		
		If Measure(Stem) > 0
			Return Word[..WLen - 1]
		End If
		
		Return Word
	End If
	
	If Word.EndsWith("ed")
		Stem = Word[..WLen - 2]
		
		If HasVowels(Stem)
			Return Step_1b_restore(Stem)
		End If
		
		Return Word
	End If
	
	If Word.EndsWith("ing")
		Stem = Word[..WLen - 3]
		
		If HasVowels(Stem)
			Return Step_1b_restore(Stem)
		End If
		
		Return Word
	End If
	
	Return Word
End Function

Function Step_1b_restore:String(Stem:String)
	Local SLen:Int = Stem.Length

	If Stem.endsWith("at")
		Return Stem + "e"
	End If
	
	If Stem.endsWith("bl")
		Return Stem + "e"
	End If
	
	If Stem.endsWith("iz")
		Return Stem + "e"
	End If

	If Not (Stem.endsWith("l") Or Stem.endsWith("s") Or Stem.endsWith("z"))
		If EndsWithCC(Stem)
			Return Stem[..SLen - 1]
		End If
	End If
	
	If Measure(Stem) = 1
		If EndsWithCVC(Stem)
			Return Stem + "e"
		End If
	End If
	
	Return Stem
End Function

Function Consonant(Word:String, Index:Int)
	If Index >= Word.Length Or Index < 0 Then RuntimeError("Bad index")

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

Function EndsWithCC(Word:String)
	Local WLen:Int = Word.Length
	
	Return Consonant(Word, WLen - 1) And Consonant(Word, WLen - 2)
End Function

Function EndsWithCVC(Word:String)
	Local WLen:Int = Word.Length
	Local Last:Int = Word[WLen - 1]
	
	If WLen < 3 Then Return False
	If Last = 119 Or Last = 120 Or Last = 121 Then Return False
	
	Return Consonant(Word, WLen - 1) And (Not Consonant(Word, WLen - 2)) And Consonant(Word, WLen - 3)
End Function

Function HasVowels(Word:String)
	Local i:Int = Word.Length - 1
	
	While i >= 0
		If Not Consonant(Word, i) Then Return True
		i :- 1
	Wend
	
	Return False
End Function

' Detect VC sequences
Function Measure(Word:String)
	Local WLen = Word.length
	Local Offset:Int = 0
	Local Count:Int = 0
	
	While True
		If Offset >= WLen Then Return Count
		If Not Consonant(Word, Offset) Then Exit
		
		Offset :+ 1
	Wend
	
	Offset :+ 1
	
	While True
		While True
			If Offset >= WLen Then Return Count
			If Consonant(Word, Offset) Then Exit
			
			Offset :+ 1
		Wend
		
		Offset :+ 1
		Count :+ 1
		
		While True
			If Offset >= WLen Then Return Count
			If Not Consonant(Word, Offset) Then Exit
			
			Offset :+ 1
		Wend
		
		Offset :+ 1
	Wend
End Function

Rem
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
