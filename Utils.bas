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

Public Sub Box2OCRResult(box As Map) As OCRResult
	Dim result As OCRResult
	result.Initialize(Geometry2Rect(box.Get("geometry")),box.Get("text"))
	Return result
End Sub

Public Sub Geometry2Rect(geometry As Map) As Rect
	Dim r As Rect
	r.Initialize
	r.X=geometry.Get("X")
	r.Y=geometry.Get("Y")
	r.width=geometry.Get("width")
	r.height=geometry.Get("height")
	Return r
End Sub

Public Sub Rect2Box(r As Rect) As Map
	Dim Box As Map
	Box.Initialize
	Dim Geometry As Map
	Geometry.Initialize
	Geometry.Put("X",r.X)
	Geometry.Put("Y",r.Y)
	Geometry.Put("width",r.width)
	Geometry.Put("height",r.height)
	Box.Put("geometry",Geometry)
	Box.Put("text","")
	Return Box
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

Sub OverlappingPercent(boxGeometry1 As Map,boxGeometry2 As Map) As Double
	'Log("boxGeometry1"&boxGeometry1)
	'Log("boxGeometry2"&boxGeometry2)
	Dim X1,Y1,W1,H1 As Int
	X1=boxGeometry1.Get("X")
	Y1=boxGeometry1.Get("Y")
	W1=boxGeometry1.Get("width")
	H1=boxGeometry1.Get("height")
	Dim X2,Y2,W2,H2 As Int
	X2=boxGeometry2.Get("X")
	Y2=boxGeometry2.Get("Y")
	W2=boxGeometry2.Get("width")
	H2=boxGeometry2.Get("height")
	Dim theSmallerX,theBiggerX,theSmallerXWidth,theBiggerXWidth As Int
	If theSmallerOneIndex(X1,X2)=0 Then
		theSmallerX=X1
		theBiggerX=X2
		theSmallerXWidth=W1
		theBiggerXWidth=W2
	Else
		theSmallerX=X2
		theBiggerX=X1
		theSmallerXWidth=W2
		theBiggerXWidth=W1
	End If
	Dim theSmallerY,theBiggerY,theSmallerYHeight,theBiggerYHeight As Int
	If theSmallerOneIndex(Y1,Y2)=0 Then
		theSmallerY=Y1
		theBiggerY=Y2
		theSmallerYHeight=H1
		theBiggerYHeight=H2
	Else
		theSmallerY=Y2
		theBiggerY=Y1
		theSmallerYHeight=H2
		theBiggerYHeight=H1
	End If

	If theSmallerX+theSmallerXWidth>=theBiggerX And theSmallerY+theSmallerYHeight>=theBiggerY Then
		'overlapping
		Dim overlappingArea As Double = (theSmallerOne(X1+W1,X2+W2)-theBiggerX)*(theSmallerOne(Y1+H1,Y2+H2)-theBiggerY)
		Dim area1,area2 As Double
		area1=W1*H1
		area2=W2*H2
		Dim theSmallArea As Int=theSmallerOne(area1,area2)
		'Log("overlappingArea:"&overlappingArea)
		'Log("theSmallArea:"&theSmallArea)
		'Log("overlapping percent:")
		'Log(overlappingArea/theSmallArea)
		Return overlappingArea/theSmallArea
	Else
		Return 0
	End If
End Sub

Sub theSmallerOneIndex(X1 As Int,X2 As Int) As Int
	If X1<X2 Then
		Return 0
	Else
		Return 1
	End If
End Sub

Sub theSmallerOne(X1 As Int,X2 As Int) As Int
	If X1<X2 Then
		Return X1
	Else
		Return X2
	End If
End Sub
