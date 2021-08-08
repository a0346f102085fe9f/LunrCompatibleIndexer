Framework BRL.StandardIO
Import BRL.Map

Import "FasterHashmap.bmx"
Import "MiniJSON.bmx"

' Secondary index that stores each unique term and its occurence count for each Document ID
Type TermFrequencyIndex
	Field JSON:MiniJSON
	
	Method Init()
		JSON = New MiniJSON
	End Method
	
	Method Add(DocumentID:Int, Terms:TTermHashmap)
		JSON.EnterSublevel("~qa/" + DocumentID + "~q")
				
		For Local Term:String = EachIn Terms.Keys
			JSON.Add("~q" + Term + "~q", Terms[Term].Count)
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
