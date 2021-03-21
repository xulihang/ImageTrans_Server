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
	Dim engine As String=params.Get("engine")
	Dim appid As String=params.Get("appid")
	Dim key As String=params.Get("key")
    Log(base64)
	If base64.Trim="" Then
		resp.SendError(500,"empty data")
		Return
	End If
	resp.CharacterEncoding="UTF-8"
	resp.ContentType="application/json"
	If engine = "youdao" Then
		youdao(base64,appid,key,resp)
	else if engine = "google" Then
		google(base64,key,resp)
	End If
	
	StartMessageLoop
End Sub

Sub youdao(base64 As String,appid As String,key As String, resp As ServletResponse)
	Dim lang As String="auto"
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
		End Try

	End If
	resp.Write(Utils.OCRResults2JSON(results))
	StopMessageLoop
End Sub

Sub google(base64 As String,key As String, resp As ServletResponse)
	resp.Write("done")
	StopMessageLoop
End Sub


