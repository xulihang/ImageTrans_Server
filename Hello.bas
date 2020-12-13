B4J=true
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
	resp.ContentType="text/html"
	resp.Write(GetSystemProperty("os.name", ""))
	'resp.Write("</br>")
	'resp.Write(GetSystemProperty("java.library.path",""))
	'resp.Write("</br>")
	'resp.Write(GetSystemProperty("java.version",""))
End Sub