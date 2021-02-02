Framework BRL.StandardIO

' Simplistic JSON builder
' 

Type MiniJSON
	Field Following:MiniJSON = Null
	Field Head:MiniJSON = Null
	Field Tail:MiniJSON = Null
	
	Field Key:String
	Field Value:String
	Field SkipSeparator:Int = 0
	
	Method Add(Key:String, Value:String)
		Local Node:MiniJSON = New MiniJSON
		
		If Tail = Null
			Head = Node
			Tail = Node
		Else
			Tail.Following = Node
			Tail = Node
		End If
		
		Node.Key = Key
		Node.Value = Value
	End Method
	
	Method EnterSublevel(Key:String)
		Add(Key, "")
		Add(Null, "{")
	End Method
	
	Method ExitSublevel()
		Add(Null, "}")
	End Method

	
	Method Write(Stream:TStream)
		WriteString(Stream, "{")
		
		Local Node:MiniJSON = Head
		Local First:Int = 1
		
		While Node
			If Node.Key <> Null
				If Not First
					If Not Node.SkipSeparator
						WriteString(Stream, ",")
					End If
				Else
					First = 0
				End If

			
				WriteString(Stream, Node.Key)
				WriteString(Stream, ":")
				
			Else
				If Node.Following
					If Node.Value <> "}"
						Node.Following.SkipSeparator = 1
					End If
				End If
			End If
			
			WriteString(Stream, Node.Value)

			Node = Node.Following
		Wend
		
		WriteString(Stream, "}~n")
	End Method
End Type



'Local Test:MiniJSON = New MiniJSON
'
'Test.Add("hello", "0")
'Test.Add("more_pairs", "1")
'Test.Add("two", "2")
'Test.Add("three", "3")
'Test.Add("sublevel", "")
'Test.Add(Null, "{")
'Test.Add("lazy_implementation_of_sublevels", "4")
'Test.Add("more_sublevel_tests", "5")
'Test.Add("about_to_close", "6")
'Test.Add(Null, "}")
'
'Test.Write()