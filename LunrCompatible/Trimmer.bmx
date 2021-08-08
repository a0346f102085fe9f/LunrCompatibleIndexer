Framework BRL.StandardIO

' Trim non-word characters from the start of a null-terminated string
' Returns offset you need to adjsut with
Function TrimStart:UInt(Source:Byte Ptr)
	Local Symbol:Byte = Source[0]
	Local Offset:UInt = 0
	
	While Symbol > 0
		If Symbol > 96 And Symbol < 123 Then Exit ' Exit on lowercase
		If Symbol > 64 And Symbol < 91 Then Exit ' Exit on uppercase
		If Symbol > 47 And Symbol < 58 Then Exit ' Exit on numbers
		If Symbol > 127 Then Exit ' Exit on unicode
		
		Offset :+ 1
		Symbol = Source[Offset]
	Wend
	
	Return Offset
End Function

' Trim non-word characters from the end of a null-terminated string
' Replaces all non-word characters with 0
Function TrimEnd(Source:Byte Ptr)
	Local LastGood:UInt = 0
	Local Symbol:Byte = Source[0]
	Local Offset:UInt = 0
	
	' Find a null-terminator first
	While Symbol > 0
		If Symbol > 96 And Symbol < 123 Then LastGood = Offset
		If Symbol > 64 And Symbol < 91 Then LastGood = Offset
		If Symbol > 47 And Symbol < 58 Then LastGood = Offset
		If Symbol > 127 Then LastGood = Offset + 1
	
		Offset :+ 1
		Symbol = Source[Offset]
	Wend
	
	LastGood :+ 1
	
	While LastGood < Offset
		Source[LastGood] = 0
		LastGood :+ 1
	Wend
	
End Function

' Takes a pointer to a null-terminated string
' Checks whether the string can be used as a JSON key without encapsulating in into quotation marks
Function IsFineWithJSON(Source:Byte Ptr)
	Local Symbol:Byte = Source[0]
	Local Offset:UInt = 0


	' First symbol is not a letter not ok
	If Not (Symbol > 96 And Symbol < 123) ' Not a lowercase letter
		If Not (Symbol > 64 And Symbol < 91) ' Not an uppercase letter
			Return False
		End If
	End If

	
	While Symbol > 0
		' No control characters allowed
		If Symbol < 32 Then Return False
		
		' No unicode
		If Symbol > 127 Then Return False
		
		If Not (Symbol > 96 And Symbol < 123) ' Not a lowercase letter
			If Not (Symbol > 64 And Symbol < 91) ' Not an uppercase letter
				If Not (Symbol > 47 And Symbol < 58) ' Not a number
					If Not (Symbol = 95) ' And finally, not an underscore
						If Not (Symbol = 39) ' Also allow the '
							Return False
						End If
					End If
				End If
			End If
		End If
		
		Offset :+ 1
		Symbol = Source[Offset]
	Wend
	
	Return True
End Function
