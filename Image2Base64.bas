B4J=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=8.9
@EndOfDesignText@
'Handler class
Sub Class_Globals
	
End Sub

Public Sub Initialize
	
End Sub

Sub Handle(req As ServletRequest, resp As ServletResponse)
	Dim url As String=req.GetParameter("url")
	GetImageBase64(url,resp)
	StartMessageLoop
End Sub

Sub GetImageBase64(link As String,resp As ServletResponse)
	Dim map1 As Map
	map1.Initialize
	Dim job As HttpJob
	job.Initialize("job",Me)
	job.Download(link)
	wait for (job) jobDone(job As HttpJob)
	If job.Success Then		
		Dim out As OutputStream
		out.InitializeToBytesArray(0)
		File.Copy2(job.GetInputStream, out)
		out.Close '<------ very important
		Dim su As StringUtils
		
		map1.Put("data",su.EncodeBase64(out.ToBytesArray))
	Else
		Log(job.ErrorMessage)
	End If
	Dim json As JSONGenerator
	json.Initialize(map1)
	resp.Write(json.ToString)
    StopMessageLoop
End Sub