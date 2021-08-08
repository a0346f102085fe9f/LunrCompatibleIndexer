Framework BRL.StandardIO
Import BRL.LinkedList
Import BRL.Map

Import "MiniJSON.bmx"
Import "FasterHashmap.bmx"

' Lunr-compatible inverted index
' Hardcoded to `a` field
' A little slow
' IntMap could probably be replaced with a linked list to make it a little faster
Type TInvertedIndex
	Field Terms:TInvIdxTermHashmap
	Field JSON:MiniJSON
	Field ID:Int
	
	Method Init()
		Terms = New TInvIdxTermHashmap
		JSON = New MiniJSON
		ID = 0
	End Method
	
	Method Add(Term:String, DocumentID:Int, Count:Int)
		Local ITerm:TInvIdxTerm = Terms[Term]
		
		If ITerm = Null
			ITerm = New TInvIdxTerm
			Terms[Term] = ITerm
			
			ITerm.InDocuments = New TIntMap
			ITerm.ID = ID
			
			ID :+ 1
		End If
		
		ITerm.InDocuments[DocumentID] = New Object
		ITerm.Count :+ Count
	End Method
	
	
	Method ToJSON(Stream:TStream)
		Local HitMap:TIntMap = New TIntMap
	
		' Stage 1: Sort
		For Local Term:String = EachIn Terms.Keys
			Local ITerm:TInvIdxTerm = Terms[Term]
			Local ListID:Int = $7FFFFFFF - ITerm.Count ' Trick to have largest values come first within the tree
			
			Local List:TList = TList( HitMap[ListID] )
			
			If List = Null
				List = New TList
				HitMap[ListID] = List
			End If
			
			List.AddLast(Term)
		Next
		
		' Stage 2: Output
		For Local Node:TIntNode = EachIn HitMap
			Local List:TList = TList( Node.Value() )
		
			While List.First()
				Local Term:String = String( List.RemoveFirst() )
				Local ITerm:TInvIdxTerm = Terms[Term]
								
				JSON.EnterSublevel("~q"+Term+"~q")
				JSON.Add("~q_index~q", ITerm.ID)
				
				JSON.EnterSublevel("~qa~q")
				
				For Local Key:TIntKey = EachIn ITerm.InDocuments.Keys
					JSON.Add("~q"+Key.Value+"~q", "0")
				Next
				
				JSON.ExitSublevel()
				JSON.ExitSublevel()
			Wend
		Next
		
		JSON.Write(Stream)
	End Method
	
	
	' Old v1.1 variant
	Method ToJSON_Unsorted(Stream:TStream)
		Local ITerm:TInvIdxTerm
	
		For Local Term:String = EachIn Terms.Keys
			ITerm = Terms[Term]
			
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
