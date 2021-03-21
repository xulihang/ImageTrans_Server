B4J=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=8.9
@EndOfDesignText@
'Handler class
Sub Class_Globals
	Private BConv As ByteConverter
End Sub

Public Sub Initialize
	
End Sub

Sub Handle(req As ServletRequest, resp As ServletResponse)
	'Dim su As StringUtils
	'Dim base64 As String=su.EncodeBase64(File.ReadBytes(File.DirApp,"test.jpg"))
	If req.Method <> "POST" Then
		resp.SendError(500, "method not supported.")
		Return
	End If
	If req.ContentType.StartsWith("application/json") Then
		Dim bytes() As Byte = Bit.InputStreamToBytes(req.InputStream)
		Dim data As String=BytesToString(bytes,0,bytes.Length,"UTF-8")
		Dim json As JSONParser
		json.Initialize(data)
		Dim params As Map=json.NextObject
	Else
		resp.SendError(500, "content-type not supported.")
		Return
	End If
	Dim base64 As String=params.Get("img")
	Dim lang As String=params.Get("lang")
	Dim engine As String=params.Get("engine")
	Dim appid As String=params.Get("appid")
	Dim key As String=params.Get("key")
	If base64.Trim="" Then
		resp.SendError(500,"empty data")
		Return
	End If
	resp.CharacterEncoding="UTF-8"
	resp.ContentType="application/json"
	If engine = "youdao" Then
		youdao(base64,lang,appid,key,resp)
	else if engine = "google" Then
		google(base64,lang,key,resp)
	End If	
	StartMessageLoop
End Sub

Sub youdao(base64 As String,lang As String,appid As String,key As String, resp As ServletResponse)
	Dim sign As String
	Dim results As List
	results.Initialize
	Dim salt As Int
	salt=Rnd(1,1000)
	DateTime.SetTimeZone(0)
	Dim timestamp As String=DateTime.Now
	timestamp=timestamp.SubString2(0,timestamp.Length-3)
	'Log(timestamp)
	Dim before, after As String
	before=base64.SubString2(0,10)
	'Log(before.Length)
	after=base64.SubString2(base64.Length-10,base64.Length)
	'Log(after.Length)
	Dim input As String
	input=before&base64.Length&after
	Dim curtime As Int=timestamp
	'Log(input)
	sign=appid&input&salt&curtime&key
	Dim md As MessageDigest
	sign=BConv.HexFromBytes(md.GetMessageDigest(BConv.StringToBytes(sign,"UTF-8"),"SHA-256"))
	'sign=sign.ToLowerCase
	Log(sign)
	Dim su As StringUtils
	Dim params As String
	base64=su.EncodeUrl(base64,"UTF-8")
	params="img="&base64&"&langType="&lang&"&detectType=10012&imageType=1&appKey="&appid&"&docType=json&signType=v3&curtime="&curtime&"&salt="&salt&"&sign="&sign
	Dim job As HttpJob
	job.Initialize("",Me)
	job.PostString("https://openapi.youdao.com/ocrapi",params)
	wait for (job) JobDone(job As HttpJob)
	If job.Success Then
		Try
			Log(job.GetString)
			Dim json As JSONParser
			json.Initialize(job.GetString)
			Dim map1 As Map
			map1=json.NextObject
			Dim result As Map = map1.Get("Result")
			Dim regions As List
			regions=result.Get("regions")
			For Each region As Map In regions
				Dim sb As StringBuilder
				sb.Initialize
				Dim lines As List
				lines=region.Get("lines")
				For Each line As Map In lines
					sb.Append(line.Get("text"))
					sb.Append(CRLF)
				Next
				Dim boundingBox As String
				boundingBox=region.Get("boundingBox")
				Dim boundings As List
				boundings=Regex.Split(",",boundingBox)
				Dim verticeList As List
				verticeList.Initialize
				For i=0 To 3
					Dim v As Vertice
					v.Initialize
					Dim keyX As String=i*2
					Dim keyY As String=i*2+1
					v.X=boundings.Get(keyX)
					v.Y=boundings.Get(keyY)
					verticeList.Add(v)
				Next
				Dim vertices As OCRVertices
				vertices.Initialize(verticeList)
				Dim r As OCRResult
				r.Initialize(vertices,sb.ToString)
				results.Add(r)
			Next
		Catch
			Log(LastException)
			resp.SendError(500,LastException.Message)
		End Try
	End If
	resp.Write(Utils.OCRResults2JSON(results))
	StopMessageLoop
End Sub

Sub google(base64 As String,lang As String,key As String, resp As ServletResponse)
	Dim detectionType As String="DOCUMENT_TEXT_DETECTION"
	Dim boxes As List
	boxes.Initialize
	Dim resultMap As Map
	resultMap.Initialize
	Dim job As HttpJob
	job.Initialize("",Me)
	Dim requests As List
	requests.Initialize
	Dim body As Map
	body.Initialize
	body.Put("requests",requests)
	Dim request As Map
	request.Initialize
	Dim imageMap As Map
	imageMap.Initialize
	imageMap.Put("content",base64)
	Dim features As List
	features.Initialize
	Dim feature As Map
	feature.Initialize
	feature.Put("type",detectionType)
	features.Add(feature)
	request.Put("image",imageMap)
	request.Put("features",features)
	If lang.StartsWith("auto")=False Then
		Dim hints As List
		hints.Initialize
		hints.Add(lang)
		Dim context As Map
		context.Initialize
		context.Put("languageHints",hints)
		request.Put("imageContext",context)
	End If
	requests.Add(request)
	Dim jsonG As JSONGenerator
	jsonG.Initialize(body)
	job.PostString("https://vision.googleapis.com/v1/images:annotate?key="&key,jsonG.ToString)
	'job.GetRequest.SetHeader("Authorization","Bearer "&key)
	job.GetRequest.SetContentType("application/json; charset=utf-8")
	wait for (job) JobDone(job As HttpJob)
	If job.Success Then
		Try
			Log(job.GetString)
			'File.WriteString(File.DirApp,"out.json",job.GetString)
			Dim responses As List
			Dim json As JSONParser
			json.Initialize(job.GetString)
			responses=json.NextObject.Get("responses")
			Dim response As Map=responses.Get(0)
			Dim fullTextAnnotation As Map=response.Get("fullTextAnnotation")
			Dim pages As List=fullTextAnnotation.Get("pages")
			For Each page As Map In pages
				Dim blocks As List = page.Get("blocks")
				Log(blocks.Size&" blocks")
				
				For Each block As Map In blocks
					Dim paragraphs As List=block.Get("paragraphs")
					Log(paragraphs.Size&" paras")
					For Each paragraph As Map In paragraphs
						boxes.Add(Paragraph2Box(paragraph))
					Next
				Next
			Next
		Catch
			Log(LastException)
			resp.SendError(500,LastException.Message)
		End Try
	End If
	RemoveOverlapped(boxes)
	Dim results As List
	results.Initialize
	For Each box As Map In boxes
		results.Add(Utils.Box2OCRResult(box))
	Next
	resp.Write(Utils.OCRResults2JSON(results))
	StopMessageLoop
End Sub

Sub Paragraph2Box(paragraph As Map) As Map
	Dim box As Map
	box.Initialize
	Dim boundingBox As Map=paragraph.Get("boundingBox")
	Dim vertices As List=boundingBox.Get("vertices")
	Dim minX,maxX,minY,maxY As Int
	Dim index As Int=0
	For Each point As Map In vertices
		Dim x As Int=point.Get("x")
		Dim y As Int=point.Get("y")
		If index=0 Then
			minX=x
			minY=y
		Else
			minX=Min(minX,x)
			minY=Min(minY,y)
		End If
		maxX=Max(x,maxX)
		maxY=Max(y,maxY)
		index=index+1
	Next
	Dim boxGeometry As Map
	boxGeometry.Initialize
	boxGeometry.Put("X",minX)
	boxGeometry.Put("Y",minY)
	boxGeometry.Put("width",maxX-minX)
	boxGeometry.Put("height",maxY-minY)
	box.Put("geometry",boxGeometry)
	
	Dim sb As StringBuilder
	sb.Initialize
	Dim words As List=paragraph.Get("words")
	For Each word As Map In words
		Dim HasSpace As Boolean=True
		If word.ContainsKey("property") Then
			Dim property As Map=word.Get("property")
			Dim detectedLanguages As List=property.Get("detectedLanguages")
			For Each language As Map In detectedLanguages
				Dim langcode As String=language.Get("languageCode")
				If langcode.StartsWith("zh") Or langcode.StartsWith("ja") Then
					HasSpace=False
				End If
			Next
		End If
		Dim symbols As List=word.Get("symbols")
		For Each symbol As Map In symbols
			sb.Append(symbol.Get("text"))
		Next
		If HasSpace Then
			sb.Append(" ")
		End If
	Next
	box.Put("text",sb.ToString.Trim)
	Return box
End Sub

Sub RemoveOverlapped(boxes As List)
	Dim new As List
	new.Initialize
	For i=0 To boxes.Size-1
		Dim shouldRemove As Boolean=False
		Dim box1 As Map=boxes.Get(i)
		Dim geometry1 As Map
		geometry1=box1.Get("geometry")
		For j=0 To boxes.Size-1
			Dim box2 As Map=boxes.Get(j)
			Dim geometry2 As Map
			geometry2=box2.Get("geometry")
			If Utils.OverlappingPercent(geometry1,geometry2)>0.5 Then
				If GetArea(geometry1)<GetArea(geometry2) Then
					shouldRemove=True
				End If
			End If
		Next
		If shouldRemove=False Then
			new.Add(box1)
		End If
	Next
	boxes.Clear
	boxes.Addall(new)
End Sub

Sub GetArea(boxGeometry As Map) As Int
	Dim width,height As Int
	width=boxGeometry.Get("width")
	height=boxGeometry.Get("height")
	Return width*height
End Sub