Framework BRL.StandardIO
Import BRL.Math

Function IDF:Double(DocumentCount:Int, DocumentsWithTerm:Int)
	Return Log(1 + Abs( (DocumentCount - DocumentsWithTerm + 0.5) / (DocumentsWithTerm + 0.5)))
End Function
