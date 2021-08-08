Framework BRL.StandardIO
Import BRL.Map


' Term datatype that's using during the parsing step
' Contains only the hitcount
Type TTerm
	Field Count:Int = 0
End Type

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
	Field Count:Int
End Type


' Here's some trickery to squeeze more performance out of TStringMap
' Usually you'll have to call bbObjectDowncast() on an object whenever you want to extract something
' This can be sidestepped by declaring a custom type that sets/gets TTerm instead of Object

Extern
	' GCC won't be very happy due to return type "struct _m_FasterHashmap_TTerm_obj*" instead of "BBOBJECT", so let's override it with ="..."
	' Let's give it a different name to boot, this also works
	' Declaring two different names for the same function ALSO WORKS...
	Function TTermHashmapExtract:TTerm(key:String, root:Byte Ptr Ptr)="BBOBJECT bmx_map_stringmap_valueforkey(BBSTRING,BBBYTE**)"
	Function TInvIdxTermHashmapExtract:TInvIdxTerm(key:String, root:Byte Ptr Ptr)="BBOBJECT bmx_map_stringmap_valueforkey(BBSTRING,BBBYTE**)"
	
	' These are unused for now
	' I want to compare the performance with/without this "optimization"
	Function TTermNodeValue:TTerm(nodePtr:Byte Ptr)="BBOBJECT bmx_map_stringmap_value(BBBYTE*)"
	Function TInvIdxNodeValue:TInvIdxTerm(nodePtr:Byte Ptr)="BBOBJECT bmx_map_stringmap_value(BBBYTE*)"
End Extern

Type TTermHashmap Extends TStringMap
	Method Operator[]:TTerm(Key:String) Override
		Key.Hash()
		Return TTermHashmapExtract(key, Varptr _root)
	End Method
End Type

Type TInvIdxTermHashmap Extends TStringMap
	Method Operator[]:TInvIdxTerm(Key:String) Override
		Key.Hash()
		Return TInvIdxTermHashmapExtract(key, Varptr _root)
	End Method
End Type
