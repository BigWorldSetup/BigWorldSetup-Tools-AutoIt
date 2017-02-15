Set wshshell = WScript.CreateObject ("wscript.shell")
wshshell.run """Tools\AutoIt3.exe""" &" " & """Partial-URL-Update.au3""", 6, True
set wshshell = nothing