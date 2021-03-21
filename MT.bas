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
	else if engine="tencent" Then
		tencent(textList,sourceLang,targetLang,appid,key,resp)
	else if engine = "googlewithoutapikey" Then
		google(textList,sourceLang,targetLang,False,resp)
	else if engine = "googlewithoutapikey_cn" Then
		google(textList,sourceLang,targetLang,True,resp)
	else if engine = "google" Then
		google2(textList,sourceLang,targetLang,key,resp)
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



Sub google(textList As List,sourceLang As String,targetLang As String,useCN As Boolean,resp As ServletResponse)
	Dim tgtList As List
	tgtList.Initialize
	For Each source As String In textList
		Dim target As String
		Dim url As String
		Log("useCN")
		Log(useCN)
		If useCN Then
			url="https://translate.google.cn/translate_a/t?client=dict-chrome-ex"
		Else
			url="https://translate.google.com/translate_a/t?client=dict-chrome-ex"
		End If
		Dim params As String
		Dim su As StringUtils
		source=su.EncodeUrl(source,"UTF8")
		params="dt=t&dj=1&sl="&sourceLang&"&tl="&targetLang&"&q="&source
		Dim job As HttpJob
		job.Initialize("job",Me)
		job.Download(url&"&"&params)
		job.GetRequest.SetContentEncoding("UTF8")
		job.GetRequest.SetHeader("User-Agent", "Mozilla/5.0 (IE 11.0; Windows NT 6.3; WOW64; Trident/7.0; Touch; rv:11.0) like Gecko")
		job.GetRequest.SetHeader("Accept", "text/html,application/xhtml+xml;q=0.9,image/webp,*/*;q=0.8")
		job.GetRequest.SetHeader("Accept-Encoding", "gzip, deflate, br")
		job.GetRequest.SetHeader("Connection", "keep-alive")
		job.GetRequest.SetHeader("Cookie", "BL_D_PROV= BL_T_PROV=Google")
		job.GetRequest.SetHeader("Host", "translate.googleapis.com")
		job.GetRequest.SetHeader("Referer", "https://translate.google.com/")
		job.GetRequest.SetHeader("TE", "Trailers")
		job.GetRequest.SetHeader("Upgrade-Insecure-Requests", "1")
		wait For (job) JobDone(job As HttpJob)
		If job.Success Then
			Dim OS As OutputStream 'Get the bytes from Job.InputStream
			OS.InitializeToBytesArray(1000)
			File.Copy2(job.GetInputStream, OS)
			Dim Buffer() As Byte
			Buffer = OS.ToBytesArray
			Dim compress As CompressedStreams
			Dim decompressed() As Byte
			decompressed = compress.DecompressBytes(Buffer, "gzip")
			Dim DecompressedString As String 'convert Bytes to String again
			DecompressedString=BytesToString(decompressed, 0, decompressed.Length, "UTF8")
			Log(DecompressedString)
			Dim json As JSONParser
			json.Initialize(DecompressedString)
			Dim sb As StringBuilder
			sb.Initialize
			Dim results As List=json.NextObject.Get("results")
			Dim result As Map= results.Get(0)
			Dim sentences As List=result.Get("sentences")
			For Each sentence As Map In sentences
				sb.Append(sentence.GetDefault("trans",""))
			Next
			target=sb.ToString.Trim
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

Sub tencent(textList As List,sourceLang As String,targetLang As String,id As String,key As String,resp As ServletResponse)
	If key="" And id="" Then
		key=File.ReadString(File.DirApp,"tencent_key").Trim
		id=File.ReadString(File.DirApp,"tencent_id").Trim
	End If
	Dim tgtList As List
	tgtList.Initialize
	For Each source As String In textList
		Sleep(200)
		Dim target As String	
		Dim su As StringUtils
		Dim params As String
		Dim nounce As Int
		Dim timestamp As Int=DateTime.Now/1000
		nounce=Rnd(1000,2000)
		params="Action=TextTranslate&Nonce="&nounce&"&ProjectId=0&Region=ap-shanghai&SecretId="&id&"&Source="&sourceLang&"&SourceText="&source&"&Target="&targetLang&"&Timestamp="&timestamp&"&Version=2018-03-21"
		'add signature
		source=su.EncodeUrl(source,"UTF-8")
		params="Action=TextTranslate&Nonce="&nounce&"&ProjectId=0&Region=ap-shanghai&SecretId="&id&"&Signature="&getSignature(key,params)&"&Source="&sourceLang&"&SourceText="&source&"&Target="&targetLang&"&Timestamp="&timestamp&"&Version=2018-03-21"
		'Log(params)
		Dim job As HttpJob
		job.Initialize("job",Me)
		job.Download("https://tmt.ap-shanghai.tencentcloudapi.com/?"&params)
		wait For (job) JobDone(job As HttpJob)
		If job.Success Then
			Log(job.GetString)
			Try
				Dim json As JSONParser
				json.Initialize(job.GetString)
				Dim Response As Map
				Response=json.NextObject.Get("Response")
				target=Response.Get("TargetText")
			Catch
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

Sub getSignature(key As String,params As String) As String
	Dim mactool As Mac
	Dim k As KeyGenerator
	k.Initialize("HMACSHA1")
	Dim su As StringUtils
	Dim combined As String="GETtmt.ap-shanghai.tencentcloudapi.com/?"&params
	k.KeyFromBytes(Bconv.StringToBytes(key,"UTF-8"))
	mactool.Initialise("HMACSHA1",k.Key)
	mactool.Update(combined.GetBytes("UTF-8"))
	Dim bb() As Byte
	bb=mactool.Sign
	Dim base As Base64
	Dim sign As String=base.EncodeBtoS(bb,0,bb.Length)
	sign=su.EncodeUrl(sign,"UTF-8")
	Return sign
End Sub

Sub google2(textList As List,sourceLang As String,targetLang As String,key As String,resp As ServletResponse)
	Dim tgtList As List
	tgtList.Initialize
	For Each source As String In textList
		Dim target As String
		Dim su As StringUtils
		Dim job As HttpJob
		job.Initialize("job",Me)
		Dim params As String
		params="?key="&key& _
				"&q="&su.EncodeUrl(source,"UTF-8")&"&format=text&source="&sourceLang&"&target="&targetLang
		job.Download("https://translation.googleapis.com/language/translate/v2"&params)
		Log(params)
		wait For (job) JobDone(job As HttpJob)
		If job.Success Then
			Try
				Log(job.GetString)
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
