﻿B4J=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=7.8
@EndOfDesignText@
'Handler class
Sub Class_Globals
	
End Sub

Public Sub Initialize
	
End Sub

Sub Handle(req As ServletRequest, resp As ServletResponse)
	If Main.Running Then
		resp.Write("An instance is running. Please wait.")
		Return
	End If
	
	If req.RemoteAddress<>Null Then
		If Main.RecordAccess(req.RemoteAddress)=False Then
			resp.Write("Exceed today's limit which is 5 images per day.")
			Return
		End If
	End If
	
	Dim config As String
	Dim usePrevious As String="true"
	Dim detectOnly As String="false"
	Dim filename As String
	Dim uploadedPath As String=File.Combine(File.DirApp,"uploaded")
	If File.Exists(uploadedPath,"")=False Then
		File.MakeDir(uploadedPath,"")
	End If
	
	If req.ContentType.StartsWith("multipart/form-data") Then
		Dim parts As Map = req.GetMultipartData(File.DirApp & "/uploaded", 10000000)
		Dim filepart As Part = parts.Get("image")
		Dim configpart As Part = parts.Get("config")
		config=configpart.GetValue(req.CharacterEncoding)		
		If parts.ContainsKey("detectonly") Then
			Dim detectpart As Part = parts.Get("detectonly")
			If detectpart.GetValue(req.CharacterEncoding)="on" Then
				detectOnly="true"
			Else
				detectOnly="false"
			End If
		End If
		
		If parts.ContainsKey("useprevious") Then
			Dim usepreviouspart As Part = parts.Get("useprevious")
			'Log("useprevious:"&usepreviouspart.GetValue(req.CharacterEncoding))
			If usepreviouspart.GetValue(req.CharacterEncoding)="on" Then
				usePrevious="true"
			Else
				usePrevious="false"
			End If
		Else
			usePrevious="false"
		End If

		Log("detect only:"&detectOnly)
		Log("usePrevious:"&usePrevious)
		Dim returntype As String
		Dim returntypePart As Part=parts.Get("returntype")
		returntype=returntypePart.GetValue(req.CharacterEncoding)
		Dim hash As String=MD5(filepart.TempFile,"")
		If DataExists(File.Combine(Main.tempDir,hash)) And usePrevious="true" Then
			returnResult(returntype,hash,resp)
			Return
		End If
		File.Copy(filepart.TempFile,"",uploadedPath,filepart.SubmittedFilename)
		File.Delete(filepart.TempFile,"")

		filename=filepart.SubmittedFilename
		
		If isSupported(filename.ToLowerCase)=False Then
			resp.Write("Only bmp, jpg and png are supported.")
			Return
		End If
		
	Else if req.ContentType.StartsWith("application/json") Then
		Dim bytes() As Byte = Bit.InputStreamToBytes(req.InputStream)	
		Dim data As String=BytesToString(bytes,0,bytes.Length,"UTF-8")
		Dim json As JSONParser
		json.Initialize(data)
		Dim params As Map=json.NextObject
		filename=params.Get("filename")
		config=params.Get("config")
		usePrevious=params.Get("useprevious")
		detectOnly=params.Get("detectonly")
		
		Dim base64Data As String=params.Get("data")
		'data:image/jpeg;base64,
		base64Data=Regex.Replace("data.*?base64,",base64Data,"")
		Dim su As StringUtils
		File.WriteBytes(uploadedPath,filename,su.DecodeBase64(base64Data))
		hash=MD5(uploadedPath,filename)
		
		returntype="base64"
		If DataExists(File.Combine(Main.tempDir,hash)) And usePrevious="true" Then
			returnResult(returntype,hash,resp)
			Return
		End If
		

	Else
		resp.Write("wrong")
		Return
	End If
	
	If File.Size(uploadedPath,filename)>3*1024*1024 Then
		resp.Write("File is too large.")
		Return
	End If
	
	Log(filename)
	Dim configPath As String=WriteConfigFile(config,hash)
	Dim fileListPath As String=WriteFileList(File.Combine(uploadedPath,filename))
	Run(resp,configPath,fileListPath,usePrevious,detectOnly,hash,returntype)
	StartMessageLoop '<---
End Sub

Sub isSupported(filename As String) As Boolean
	If filename.EndsWith(".jpg") Or filename.EndsWith(".bmp") Or filename.EndsWith(".png") Then
		Return True
	End If
	Return False
End Sub

Sub WriteConfigFile(config As String,hash As String) As String
	Dim path As String=File.Combine(Main.tempDir,hash&".json")
	File.WriteString(path,"",config)
	Return path
End Sub

Sub WriteFileList(filename As String) As String
	Dim path As String=File.Combine(Main.tempDir,DateTime.Now&".txt")
	File.WriteString(path,"",filename)
	Return path
End Sub

Sub Run(resp As ServletResponse,configPath As String,fileListPath As String,usePrevious As String,detectOnly As String,hash As String,returntype As String)
	' .\config.json true true .\temp2\ .\fileList.txt
	Try
		Dim sh As Shell
		sh.Initialize("sh","java",Array As String("-jar","ImageTrans.jar",configPath,usePrevious,detectOnly,Main.tempDir,fileListPath))
		sh.WorkingDirectory=File.DirApp
		sh.Encoding=GetSystemProperty("file.encoding","UTF8")
		sh.run(1000000)
		Main.shs.Add(sh)
		Main.Running=True
		wait for sh_ProcessCompleted (Success As Boolean, ExitCode As Int, StdOut As String, StdErr As String)
		If Success And ExitCode = 0 Then
			Log("Success")
			Log(StdOut)
			returnResult(returntype,hash,resp)
		Else
			Log(StdOut)
			resp.Write(StdErr)
			resp.Write(StdOut)
		End If
	Catch
		Log(LastException)
		resp.Write(LastException.Message)
	End Try
	Main.Running=False
	StopMessageLoop
End Sub

Sub returnResult(returntype As String,hash As String,resp As ServletResponse)
	Dim workDir As String=File.Combine(Main.tempDir,hash)
	Log(returntype)
	Log(hash)
	If returntype="json" Then
		resp.ContentType="application/json"
		If File.Exists(workDir,"auto.json") Then
			resp.Write(File.ReadString(workDir,"auto.json"))
		Else
			resp.Write("[]")
		End If
	Else if returntype="html" Then
		resp.ContentType="text/html"
		resp.Write($"<img src="/temp/${hash}/image.jpg-output.jpg"  alt="result" />"$)
	else if returntype="img" Then
		Dim img() As Byte = File.ReadBytes(File.Combine(Main.tempDir,hash),"image.jpg-output.jpg")
		Dim In As InputStream
		In.InitializeFromBytesArray(img, 0, img.Length)
		File.Copy2(In, resp.OutputStream)
	else if returntype="base64" Then
		resp.ContentType="application/json"
		Dim su As StringUtils
		Dim map1 As Map
		map1.Initialize
		map1.Put("data",su.EncodeBase64(File.ReadBytes(File.Combine(Main.tempDir,hash),"image.jpg-output.jpg")))
		Dim json As JSONGenerator
		json.Initialize(map1)
		Log(json.ToString)
		resp.Write(json.ToString)
	End If
End Sub

Sub MD5(dir As String,filename As String) As String
	Dim in As InputStream
	in = File.OpenInput(dir,filename)
	Dim buffer(File.Size(dir, filename)) As Byte
	in.ReadBytes(buffer, 0, buffer.length)
	Dim Bconv As ByteConverter
	Dim data(buffer.Length) As Byte
	Dim md As MessageDigest
	data = md.GetMessageDigest(buffer, "MD5")
	Return Bconv.HexFromBytes(data)
End Sub

Sub DataExists(workDir As String) As Boolean
	Dim result As Boolean=True
	If File.Exists(workDir,"image.jpg")=False Then
		result=False
	End If
	If File.Exists(workDir,"image.jpg-output.jpg")=False Then
		result=False
	End If
	If File.Exists(workDir,"auto.json")=False Then
		result=False
	End If
	Return result
End Sub

