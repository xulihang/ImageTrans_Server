B4J=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=7.8
@EndOfDesignText@
'Filter class
Sub Class_Globals
	
End Sub

Public Sub Initialize
	
End Sub

'Return True to allow the request to proceed.
Public Sub Filter(req As ServletRequest, resp As ServletResponse) As Boolean
	' Test if the request is for a static file, only static files will be cached.
	' File.Combine(File.DirApp, "www") is just for example purposes. Replace this with your StaticFilesFolder (StaticFilesFolder property from your server object)
	If File.Exists(File.Combine(File.DirApp, "www"), req.RequestURI) Then
		' if the request was made for myfile.ext then we set response header to disable caching for this file
		Dim name As String=File.GetName(req.RequestURI)
		If name.Contains(".jpg") Or name.Contains("upload.html")  Then
			resp.SetHeader("Cache-Control", "no-cache, no-store") ' disables cache for HTTP 1.1
			resp.SetHeader("Pragma", "no-cache") ' disables cache for HTTP 1.0
			resp.SetHeader("Expires", "0") ' disables cache for Proxies
			Return True ' exit the sub and allow the request to proceed
		End If
		' we set the response header to cache the requested resource for 7 days - max-age is in seconds
		resp.SetHeader("Cache-Control", "public, max-age=604800")
	End If
	Return True
End Sub