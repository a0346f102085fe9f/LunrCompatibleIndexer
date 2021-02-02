Framework BRL.StandardIO


Const Sym_Tab = 9
Const Sym_Space = 32
Const Sym_Dash = 45
Const Sym_CR = 13
Const Sym_LF = 10

' Low level tokenizer
' Operates directly on memory
' Returns an array of offsets into the memory
' Alters the memory
Function Tokenize:Int[](Memory:Byte Ptr, Size: Size_T)	
	Local Result:Int[Size / 2]
	
	' Stage 1:
	' Zeroize all separator characters
	Local Symbol:Byte
	
	For Local i:Int = 0 Until Size
		Symbol = Memory[i]
		
		Select Symbol
			Case Sym_Tab, Sym_Space, Sym_Dash, Sym_CR, Sym_LF
				Memory[i] = 0
		End Select
	Next
	
	
	' Stage 2:
	' Find sequences of non-zero characters
	Local RunLength:Int = 0
	Local Matches:UInt = 0
	
	For Local i:Int = 0 Until Size
		Symbol = Memory[i]

		If Symbol > 0
			RunLength :+ 1
		Else
			If RunLength > 0
				Result[Matches] = (i - RunLength)
				Matches :+ 1
			End If
		
			RunLength = 0
		End If
	Next
	
	If Matches = 0 Then RuntimeError("Tokenizer: couldn't find a single token.")
	If Matches >= (Size / 2) Then RuntimeError("Tokenizer: whoops, out-of-bounds write. FIXME.")
	If RunLength > 0 Then RuntimeError("Tokenizer: you didn't properly null-terminate your data")
	
	Return Result[..Matches]
End Function
