Framework BRL.StandardIO
Import BRL.Map

Import "MiniJSON.bmx"

Type TTerm
	Field Count:Int = 0
End Type

' Secondary index that stores each unique term and its occurence count for each Document ID
Type TermFrequencyIndex
	Field JSON:MiniJSON
	
	Method Init()
		JSON = New MiniJSON
	End Method
	
	Method Add(DocumentID:Int, Terms:TStringMap)
		JSON.EnterSublevel("~qa/" + DocumentID + "~q")
				
		For Local Term:String = EachIn Terms.Keys
			JSON.Add(Term, TTerm(Terms[Term]).Count)
		Next
		
		JSON.ExitSublevel()
	End Method
	
	Method ToJSON(Stream:TStream)
		JSON.Write(Stream)
	End Method
End Type

' Tertiary index that stores total term count for each Document ID
Type TermCountIndex
	Field JSON:MiniJSON
	
	Method Init()
		JSON = New MiniJSON
	End Method
	
	Method Add(DocumentID:Int, Count:Int)
		JSON.Add("~qa/" + DocumentID + "~q", Count)
	End Method
	
	Method ToJSON(Stream:TStream)
		JSON.Write(Stream)
	End Method
End Type
