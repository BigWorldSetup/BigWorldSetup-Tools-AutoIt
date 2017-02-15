Set wshshell = WScript.CreateObject ("wscript.shell")
wshshell.run """Tools\AutoIt3.exe""" &" " & """url-check.au3""", 6, True
set wshshell = nothing