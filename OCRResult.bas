B4J=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=8.9
@EndOfDesignText@
Sub Class_Globals
	Private mText As String
	Private mVertices As OCRVertices
	Private mRect As Rect
	Type Rect(X As Int,Y As Int,width As Int,height As Int)
	Type Vertice(X As Int,Y As Int)
End Sub

'Initializes the object. You can add parameters to this method if needed.
Public Sub Initialize(localizationResults As Object,text As String)
    mText=text
	If localizationResults Is Rect Then
		mRect=localizationResults
	else if localizationResults Is OCRVertices Then
		mVertices=localizationResults
	End If
End Sub

public Sub getText As String
	Return mText
End Sub

public Sub getVertices As OCRVertices
	If mVertices.IsInitialized=False Then
	    Return Utils.Rect2Vertices(mRect)
	Else
		Return mVertices
	End If
	
End Sub

public Sub getRect As Rect
	If mRect.IsInitialized=False Then
	    Return Utils.Vertices2Rect(mVertices)
	Else
		Return mRect	
	End If	
End Sub
