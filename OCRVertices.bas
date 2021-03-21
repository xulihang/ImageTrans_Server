B4J=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=8.9
@EndOfDesignText@
Sub Class_Globals
	Public v1 As Vertice
	Public v2 As Vertice
	Public v3 As Vertice
	Public v4 As Vertice
End Sub

'Initializes the object. You can add parameters to this method if needed.
Public Sub Initialize(vertices As Object)
	If vertices Is List Then
		Dim verticeList As List=vertices
		v1=verticeList.Get(0)
		v2=verticeList.Get(1)
		v3=verticeList.Get(2)
		v4=verticeList.Get(3)
	Else
		Dim verticesArray() As Vertice=vertices
		v1=verticesArray(0)
		v2=verticesArray(1)
		v3=verticesArray(2)
		v4=verticesArray(3)
	End If
End Sub

Public Sub AsArray As Vertice()
	Return Array As Vertice(v1,v2,v3,v4)
End Sub
