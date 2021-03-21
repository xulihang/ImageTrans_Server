B4J=true
Group=Default Group
ModulesStructureVersion=1
Type=StaticCode
Version=8.9
@EndOfDesignText@
Sub Process_Globals
	
End Sub

Public Sub OCRResults2JSON(results As List) As String
	Dim json As JSONGenerator
	Dim resultMap As Map
	resultMap.Initialize
	Dim newResults As List
	newResults.Initialize
	For Each r As OCRResult In results
		newResults.Add(OCRResult2Map(r))
	Next
	resultMap.Put("boxes",newResults)
	json.Initialize(resultMap)
	Return json.ToString
End Sub

Public Sub OCRResult2Map(r As OCRResult) As Map
	Dim result As Map
	result.Initialize
	Dim index As Int=0
	For Each v As Vertice In r.Vertices.AsArray
		result.Put("x"&index,v.X)
		result.Put("y"&index,v.Y)
		index=index+1
	Next
	result.Put("text",r.Text)
	Return result
End Sub

Public Sub Rect2Vertices(r As Rect) As OCRVertices
	Dim v1 As Vertice=CreateVertice(r.X,r.Y)
	Dim v2 As Vertice=CreateVertice(r.X+r.width,r.Y)
	Dim v3 As Vertice=CreateVertice(r.X+r.width,r.Y+r.height)
	Dim v4 As Vertice=CreateVertice(r.X,r.Y+r.height)
	Dim vertices As OCRVertices
	vertices.Initialize(Array As Vertice(v1,v2,v3,v4))
	Return vertices
End Sub

Public Sub Vertices2Rect(vertices As OCRVertices) As Rect
	Dim minX,minY,maxX,maxY As Int
	minX=vertices.v1.X
	minY=vertices.v1.Y
	For Each vertice As Vertice In vertices.AsArray
		minX=Min(minX,vertice.X)
		minY=Min(minY,vertice.Y)
		maxX=Max(maxX,vertice.X)
		maxY=Max(maxY,vertice.Y)
	Next
	Return CreateRect(minX,minY,maxX-minX,maxY-minY)
End Sub

Public Sub CreateRect (x As Int, y As Int, width As Int, height As Int) As Rect
	Dim t1 As Rect
	t1.Initialize
	t1.x = x
	t1.y = y
	t1.width = width
	t1.height = height
	Return t1
End Sub

Public Sub CreateVertices (v1 As Vertice, v2 As Vertice, v3 As Vertice, v4 As Vertice) As OCRVertices
	Dim t1 As OCRVertices
	t1.Initialize(Array As Vertice(v1,v2,v3,v4))
	Return t1
End Sub

Public Sub CreateVertice (x As Int, y As Int) As Vertice
	Dim t1 As Vertice
	t1.Initialize
	t1.x = x
	t1.y = y
	Return t1
End Sub