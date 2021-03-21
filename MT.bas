B4J=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=8.9
@EndOfDesignText@
'Handler class
Sub Class_Globals
	Private Bconv As ByteConverter
End Sub

Public Sub Initialize
	
End Sub

Sub Handle(req As ServletRequest, resp As ServletResponse)
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
	Dim textList As List=params.Get("text")
	Dim targetLang As String=params.Get("tgt")
	Dim sourceLang As String=params.Get("src")
	Dim engine As String=params.Get("engine")
	Dim appid As String=params.Get("appid")
	Dim key As String=params.Get("key")
	resp.CharacterEncoding="UTF-8"
	resp.ContentType="application/json"
	If engine = "youdao" Then
		youdao(textList,sourceLang,targetLang,appid,key,resp)
	else if engine = "google" Then
		google(textList,sourceLang,targetLang,key,resp)
	End If
	StartMessageLoop
End Sub


Sub youdao(textList As List,sourceLang As String,targetLang As String,appid As String,key As String,resp As ServletResponse)
	Dim tgtList As List
	tgtList.Initialize
	For Each source As String In textList
		Dim salt As Int
		salt=Rnd(1,1000)
		Dim sign As String
		sign=appid&source&salt&key
		Dim md As MessageDigest
		sign=Bconv.HexFromBytes(md.GetMessageDigest(Bconv.StringToBytes(sign,"UTF-8"),"MD5"))
		sign=sign.ToLowerCase
	
		Dim su As StringUtils
		source=su.EncodeUrl(source,"UTF-8")
		Dim param As String
		param="?appKey="&appid&"&q="&source&"&from="&sourceLang&"&to="&targetLang&"&salt="&salt&"&sign="&sign
		Dim job As HttpJob
		job.Initialize("job",Me)
		job.Download("https://openapi.youdao.com/api"&param)
		wait for (job) JobDone(job As HttpJob)
		Dim target As String=""
		If job.Success Then
			Log(job.GetString)
			Try
				Dim json As JSONParser
				json.Initialize(job.GetString)
				Dim result As Map
				result=json.NextObject
				If result.Get("errorCode")="0" Then
					Dim translationList As List
					translationList=result.Get("translation")
					target=translationList.Get(0)
				End If
			Catch
				Log(LastException)
			End Try
		End If
		job.Release
		tgtList.Add(target)
	Next
	Dim jsonG As JSONGenerator
	jsonG.Initialize2(tgtList)
	resp.Write(jsonG.ToString)
	StopMessageLoop
End Sub


Sub google(textList As List,sourceLang As String,targetLang As String,key As String,resp As ServletResponse)
	Dim tgtList As List
	tgtList.Initialize
	For Each source As String In textList
		Dim target As String
		Dim su As StringUtils
		Dim job As HttpJob
		job.Initialize("job",Me)
		Dim params As String
		params="?key="&key&"&q="&su.EncodeUrl(source,"UTF-8")&"&format=text&source="&sourceLang&"&target="&targetLang
		job.Download("https://translation.googleapis.com/language/translate/v2"&params)
		wait For (job) JobDone(job As HttpJob)
		If job.Success Then
			Try
				Dim result,data As Map
				Dim json As JSONParser
				json.Initialize(job.GetString)
				result=json.NextObject
				data=result.Get("data")
				Dim translations As List
				translations=data.Get("translations")
				Dim map1 As Map
				map1=translations.Get(0)
				target=map1.Get("translatedText")
			Catch
				target=""
				Log(LastException)
			End Try
		Else
			target=""
		End If
		job.Release
		tgtList.Add(target)
	Next
    Dim jsonG As JSONGenerator
	jsonG.Initialize2(tgtList)
	resp.Write(jsonG.ToString)
	StopMessageLoop
End Sub
