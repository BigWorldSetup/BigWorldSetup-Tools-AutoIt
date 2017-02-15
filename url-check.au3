AutoItSetOption('WinTitleMatchMode', 2); set a more flexible way to search for windows
AutoItSetOption('GUIResizeMode', 1); resize and reposition GUI-elements according to new window size
AutoItSetOption('GUICloseOnESC', 0);  don't send the $GUI_EVENT_CLOSE message when ESC is pressed
AutoItSetOption('TrayIconDebug', 1); shows the current script line in the tray icon tip to help debugging
AutoItSetOption('GUIOnEventMode', 1); disable OnEvent functions notifications
AutoItSetOption('OnExitFunc','Au3Exit'); sets the name of the function called when AutoIt exits

TraySetIcon (@ScriptDir&'\Pics\BWS.ico'); sets the tray-icon

#Region Global vars
; Global are named with a $g_ , parameters with a $p_ . Normal variables don't have a prefix.
; files and folders
Global $g_BaseDir = StringLeft(@ScriptDir, StringInStr(@ScriptDir, '\', 1, -1)-1), $g_GConfDir, $g_GameDir, $g_ProgName = 'BiG World Setup'
Global $g_ProgDir = $g_BaseDir & '\BiG World Setup', $g_LogDir=$g_ProgDir&'\Logs', $g_DownDir = $g_BaseDir & '\BiG World Downloads'
Global $g_BG1Dir, $g_BG2Dir, $g_BG1EEDIR, $g_BG2EEDIR, $g_IWD1Dir, $g_IWD1EEDir, $g_IWD2Dir, $g_PSTDir, $g_RemovedDir, $g_BackupDir, $g_LogFile = $g_LogDir & '\BiG World Debug.txt'
Global $g_BWSIni = $g_ProgDir & '\Config\Setup.ini', $g_MODIni, $g_UsrIni = $g_ProgDir & '\Config\User.ini'
Global $g_BG1Dir, $g_BG2Dir, $g_BG1EEDIR, $g_BG2EEDIR, $g_IWD1Dir, $g_IWD1EEDir, $g_IWD2Dir, $g_PSTDir, $g_RemovedDir, $g_BackupDir, $g_LogFile = $g_LogDir & '\BiG World Debug.txt'
; select-gui vars
Global $g_GUIFold = IniRead($g_USrIni, 'Options', 'UnFold', '1')
Global $g_Compilation = 'R', $g_LimitedSelection = 0, $g_Tags, $g_ActiveConnections[1], $g_Groups, $g_GameList
Global $g_TreeviewItem[1][1], $g_CHTreeviewItem[1][1], $g_Connections, $g_CentralArray[4000][16]
; Logging, Reading Streams / Process-Window
Global $g_ConsoleOutput = '', $g_STDStream, $g_ConsoleOutput, $g_pQuestion = 0
; program options and misc
Global $g_Setups=_CreateList('s')
Global $g_Order, $g_Setups, $g_Skip, $g_Clip; available setups, items to skip
Global $g_CurrentPackages, $g_fLock, $g_FItem = IniRead($g_BWSIni, 'Options', 'Start', '1')
Global $g_ATrans = StringSplit(IniRead($g_BWSIni, 'Options', 'AppLang', 'EN|GE'), '|'), $g_ATNum = 1, $g_MLang
Global $g_UDll = DllOpen('user32.dll'); we have to use this for detecting the mouse or keboard-usage
Global $g_Down[6][2]; used for updateing download-progressbar
; ---------------------------------------------------------------------------------------------
; New GUI-Builing
; ---------------------------------------------------------------------------------------------
Global $g_UI[5], $g_UI_Static[16][20], $g_UI_Button[16][20], $g_UI_Seperate[16][10], $g_UI_Interact[16][20], $g_UI_Menu[5][50]
Global $g_Search[5], $g_Flags[23] = [1, 0, 0, 0, 0, 0, 0, 0, 0, 1], $g_UI_Handle[10]
Global $g_TRAIni = $g_ProgDir & '\Config\Translation-'&$g_ATrans[$g_ATNum]&'.ini', $g_UI_Message = IniReadSection($g_TRAIni, 'UI-Runtime')
; 1=w: continue without link checking; 2=w: update links; 3=mod language-string; 4=w: mc-disabled 5=Enable Pause / Resume
; 6=overwitten text by pause, 7=popup-sensitivity, 8=current tab is advsel, 9=quickstart, 10=langchange change
; 11=back is pressed, 12=forward is pressed, 13=real exit, 14=show introduction-hint, 15=greet-picture is visible
; 16=treeicon clicked, 17=treelabel clicked, 18=w: bg2only, 19=cmd-started, 20=w: selection-is-higer-than-your-preselection
; 21=use old sorting format, 22=wscreen ID

#EndRegion Global vars
#Region Includes
#include'Includes\01_UDF1.au3'
#include'Includes\02_UDF2.au3'
#include'Includes\03_Admin.au3'
#include'Includes\04_Backup.au3'
#include'Includes\05_Basics.au3'
#include'Includes\06_Depend.au3'
#include'Includes\07_Extract.au3'
#include'Includes\08_GUI.au3'
#include'Includes\09_Install.au3'
#include'Includes\10_Misc-GUI.au3'
#include'Includes\11_NET.au3'
#include'Includes\12_Process.au3'
#include'Includes\13_Select-AI.au3'
#include'Includes\14_Select-GUILoop.au3'
#include'Includes\15_Select-Helper.au3'
#include'Includes\16_Select-Tree.au3'
#include'Includes\17_Testing.au3'
#EndRegion Includes
;#NoTrayIcon

$g_DownDir = IniRead($g_UsrIni, 'Options', 'Download', $g_DownDir)

Global $g_Note='', $g_Error
Global $Prefix[14] = [13, '', 'Add', 'CH-Add', 'CZ-Add', 'EN-Add', 'FR-Add', 'GE-Add', 'IT-Add', 'JP-Add', 'KO-Add', 'PO-Add', 'RU-Add', 'SP-Add']

#cs
$Return=_Net_LinkGetInfo('http://www.shsforums.net/index.php?app=downloads&module=display&section=download&do=confirm_download&id=121', 1)
ConsoleWrite($Return[0] & ' == ' & $Return[1] & ' == ' & $Return[2]&@CRLF)
Exit
#ce
; $g_Flags 1=Write into ini 2=download file 3=show changes/erros only 4=Pause 5=
; 6=current name 7=last shown name in console 8=last shown name in note 9=last shown name in errors


$g_UI[0] = GuiCreate($g_ProgName, 500, 290, -1, -1, $WS_MINIMIZEBOX + $WS_MAXIMIZEBOX + $WS_CAPTION + $WS_POPUP + $WS_SYSMENU + $WS_SIZEBOX)

GUISetFont(8, 400, 0, 'MS Sans Serif')
GUISetOnEvent($GUI_EVENT_CLOSE, "_Check_OnEvent")
GUISetIcon (@ScriptDir&'\Pics\BWS.ico', 0); sets the GUIs icon

$g_UI_Static[1][1] = GuiCtrlCreateLabel("Mod", 10, 10, 480, 20, $SS_CENTER+$SS_CENTERIMAGE)
GUICtrlSetFont(-1, 10, 800, 0, 'MS Sans Serif')
GUICtrlSetResizing(-1, 512+32); => top, no height-change
$g_UI_Interact[1][1] = GuiCtrlCreateProgress(10, 50, 480, 10)
GUICtrlSetResizing(-1, 512+32); => top, no height-change
$g_UI_Interact[1][6] = GuiCtrlCreateProgress(10, 65, 480, 10)
GUICtrlSetResizing(-1, 512+32); => top, no height-change
GUICtrlSetState(-1, $GUI_HIDE)
$g_UI_Interact[1][2] = GuiCtrlCreateEdit("", 10, 80, 480, 140)
_GUICtrlEdit_SetLimitText($g_UI_Interact[1][2], 64000)
GUICtrlSetResizing(-1, 2+4+32+64); => left,right, top, bottom
$g_UI_Interact[1][3] = GuiCtrlCreateCheckbox("Veränderungen speichern", 10, 230, 150, 20)
GUICtrlSetResizing(-1, 512+64); => bottom, no height-change
GUICtrlSetOnEvent(-1, '_Check_OnEvent')
$g_UI_Interact[1][4] = GuiCtrlCreateCheckbox("Veränderte Daten laden", 175, 230, 150, 20)
GUICtrlSetResizing(-1, 512+64); => bottom, no height-change
GUICtrlSetOnEvent(-1, '_Check_OnEvent')
$g_UI_Interact[1][5] = GuiCtrlCreateCheckbox("Nur Veränderungen zeigen", 340, 230, 150, 20)
GUICtrlSetResizing(-1, 512+64); => bottom, no height-change
GUICtrlSetOnEvent(-1, '_Check_OnEvent')
$g_UI_Button[1][1] = GuiCtrlCreateButton("Start", 10, 255, 150, 20)
GUICtrlSetResizing(-1, 512+64); => bottom, no height-change
GUICtrlSetOnEvent(-1, '_Check_OnEvent')
$g_UI_Button[1][2] = GuiCtrlCreateButton("Export", 175, 255, 150, 20)
GUICtrlSetResizing(-1, 512+64); => bottom, no height-change
GUICtrlSetOnEvent(-1, '_Check_OnEvent')
$g_UI_Button[1][3] = GuiCtrlCreateButton("Exit", 340, 255, 150, 20)
GUICtrlSetResizing(-1, 512+64); => bottom, no height-change
GUICtrlSetOnEvent(-1, '_Check_OnEvent')

GuiSetState()

Local $Start = TimerInit()

GUICtrlSetState($g_UI_Interact[1][6], $GUI_SHOW)

For $s=1 to $g_Setups[0][0]
	While $g_Flags[4] = 0
		Sleep(10)
	WEnd
;~ 	If Not StringInStr('|BG1NPC|', '|'&$g_Setups[$s][0]&'|') Then ContinueLoop; only test a few
	_CheckURL($g_Setups[$s][0], $g_Setups[$s][1], $s)
Next

If $g_Flags[3] = 0 Then; show output
	_Check_SetScroll(@CRLF&'Done. Time:'&Round(TimerDiff($Start), 3)&@CRLF, 0)
	_Check_SetScroll(@CRLF&'NOTE:'&@CRLF&$g_Note&@CRLF&'ERROR:'&@CRLF&$g_Error, 0)
Else
	$g_Flags[3] = 1
	_Check_SetScroll(@CRLF&'Done. Time:'&Round(TimerDiff($Start), 3)&@CRLF, 0)
EndIf

While 1
	Sleep(10)
WEnd
Exit

; ---------------------------------------------------------------------------------------------
; OnEvent actions for the gui
; ---------------------------------------------------------------------------------------------
Func _Check_OnEvent()
	Switch @GUI_CtrlId
		Case $GUI_EVENT_CLOSE
			Exit
		Case $g_UI_Interact[1][3]
			$g_Flags[1]=GUICtrlRead($g_UI_Interact[1][3]); Test
		Case $g_UI_Interact[1][4]
			$g_Flags[2]=GUICtrlRead($g_UI_Interact[1][4]); Download
			If $g_Flags[2] = 1 Then
				GUICtrlSetState($g_UI_Interact[1][6], $GUI_SHOW)
			Else
				GUICtrlSetState($g_UI_Interact[1][6], $GUI_HIDE)
			EndIf
		Case $g_UI_Interact[1][5]
			$g_Flags[3]=GUICtrlRead($g_UI_Interact[1][5]); Suppress
		Case $g_UI_Button[1][1]
			If $g_Flags[4]=0 Then; Start/Stop
				GUICtrlSetData($g_UI_Button[1][1], 'Pause')
				$g_Flags[4]=1
			Else
				GUICtrlSetData($g_UI_Button[1][1], 'Start')
				$g_Flags[4]=0
			EndIf
		Case $g_UI_Button[1][2]; Export
			_Check_Output2Html()
		Case $g_UI_Button[1][3]; Exit
			Exit
	EndSwitch
EndFunc   ;==>__Check_OnEvent

; ---------------------------------------------------------------------------------------------
; Dump the value of the Edit-control into a formated html-file
; ---------------------------------------------------------------------------------------------
Func _Check_Output2Html()
	$File = FileSaveDialog($g_ProgName&': Speichern', @ScriptDir, 'HTML files (*.html)',  16, 'Export_'&@YEAR&@MON&@MDAY&'.html', $g_UI[0])
	$Handle = FileOpen($File, 2)
	If $Handle = -1 Then Return SetError(1)
	FileWriteLine($Handle, '<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">')
	FileWriteLine($Handle, '<html xmlns="http://www.w3.org/1999/xhtml">')
	FileWriteLine($Handle, '<head>')
	FileWriteLine($Handle, '<title>'&$File&'</title>')
	FileWriteLine($Handle, '<style type="text/css">')
	FileWriteLine($Handle, 'span {')
	FileWriteLine($Handle, "font-family: 'Courier New';")
	FileWriteLine($Handle, 'color: #000000;')
	FileWriteLine($Handle, 'font-size: 10pt;')
	FileWriteLine($Handle, '}')
	FileWriteLine($Handle, '</style>')
	FileWriteLine($Handle, '</head>')
	FileWriteLine($Handle, '<body bgcolor="#FFFFFF">')
	FileWriteLine($Handle, '<span>')
	$Array=StringSplit(StringStripCR(GUICtrlRead($g_UI_Interact[1][2])), @LF)
	For $a=1 to $Array[0]
		$Sign=StringLeft($Array[$a], 1)
		$Color = ''
		If $Sign = '-' Then $Color='ff8800'
		If $Sign = '>' Then $Color='0000ff'
		If $Sign = '+' Then $Color='007f00'
		If $Sign = '!' Then $Color='f70000'
		If $Color <> '' Then
			If $Sign='-' And StringRight($Array[$a], 4) = '.TP2' Then
				FileWriteLine($Handle, '<FONT COLOR="#'&$Color&'"><a href="'&_StringTranslate(StringTrimLeft($Array[$a], 1))&'">'&_StringTranslate(StringTrimLeft($Array[$a], 1))&'</a></FONT><br />')
			Else
				FileWriteLine($Handle, '<FONT COLOR="#'&$Color&'">'&_StringTranslate(StringTrimLeft($Array[$a], 1))&'</FONT><br />')
			EndIf
		Else
			FileWriteLine($Handle, _StringTranslate($Array[$a])&'<br />')
		EndIf
	Next
	FileWriteLine($Handle, '</span>')
	FileWriteLine($Handle, '</BODY>')
	FileWriteLine($Handle, '</HTML>')
	FileClose($Handle)
	ShellExecute($File)
EndFunc

; ---------------------------------------------------------------------------------------------
; Append and scroll some text
; ---------------------------------------------------------------------------------------------
Func _Check_SetScroll($p_Text, $p_IsChange)
	Local $Num=0
	If $g_Flags[3] = 1 And $p_IsChange = 0 Then Return 0; show changes only if wished
	If $p_IsChange = 1 Then
		If Not ($g_Flags[6] == $g_Flags[8]) Then
			$g_Note&=@CRLF&$g_Flags[6]; modname has not been shown in note-variable
			$g_Flags[8]=$g_Flags[6]
		EndIf
		$g_Note&=@CRLF&$p_Text
	ElseIf	$p_IsChange = 2 Then
		If Not ($g_Flags[6] == $g_Flags[9]) Then
			$g_Error&=@CRLF&$g_Flags[6]; modname has not been shown in error-variable
			$g_Flags[9]=$g_Flags[6]
		EndIf
		$g_Error&=@CRLF&$p_Text
	EndIf
	If Not ($g_Flags[6] == $g_Flags[7]) Then; modname has not been shown in edit-contol
		$p_Text=@CRLF&$g_Flags[6]&@CRLF&$p_Text
		$g_Flags[7]=$g_Flags[6]
		$Num=2
	EndIf
	_GUICtrlEdit_AppendText($g_UI_Interact[1][2], $p_Text & @CRLF)
	_GUICtrlEdit_LineScroll($g_UI_Interact[1][2], 0, 1+$Num)
EndFunc

; ---------------------------------------------------------------------------------------------
; Check if the downloads are still available and/or have changed
; ---------------------------------------------------------------------------------------------
Func _CheckURL($p_Setup, $p_String='', $p_Num=0)
	Local $s
	$Section=IniReadSection($g_ProgDir&'\Config\Global\'&$p_Setup&'.ini', 'Mod')
	$g_Flags[6] = _IniRead($Section, 'Name', '')&' ['&$p_Setup&']'
	GUICtrlSetData($g_UI_Static[1][1], $g_Flags[6])
	GUICtrlSetData($g_UI_Interact[1][1], ($p_Num*100)/$g_Setups[0][0])
	For $s=1 to $Section[0][0]
		If Not StringInStr($Section[$s][0], 'Down') Then ContinueLoop
		$Prefix=StringReplace($Section[$s][0], 'Down', '')
		$Update=0
		$URL=_IniRead($Section, $Prefix&'Down', '')
		;If Not StringInStr($URL, 'baldursgatemods.com') Then ContinueLoop
		If $URL = '' Or $URL = 'Manual' Then ContinueLoop
		ConsoleWrite($p_Setup&' ['&$Prefix&'Down]'&@CRLF)
		$File=_IniRead($Section, $Prefix&'Save', '')
		$Size=_IniRead($Section, $Prefix&'Size', '')
		$Return=_Net_LinkGetInfo($URL, 1)
		If $Return[0] = 0 Then
			_Check_SetScroll('!Vermisst: ['&$Prefix&'Down] unter '& $URL, 2)
			ContinueLoop
		Else
			_Check_SetScroll('+Gefunden: ['&$Prefix&'Down]', 0)
		EndIf
		If $Return[2] <> 0 Then; don't change the filesize if it is zero
			If $Return[2] <>$Size Then
				ConsoleWrite('>"'&$Size&'"'&@CRLF&'"' & $Return[2]&'"'&@CRLF)
				$Update=1
				If $g_Flags[1] = 1 Then IniWrite($g_ProgDir&'\Config\Global\'&$p_Setup&'.ini', 'Mod', $Prefix&'Size', $Return[2])
				_Check_SetScroll('-Größe geändert: ['&$Prefix&'Size] von ' & $Size & ' nach ' & $Return[2], 1)
			EndIf
		EndIf
		$Return[1]=StringReplace(StringReplace($Return[1], '%20', ' '), '\', ''); set correct space
		If StringLower($Return[1]) <> StringLower($File) Then; name changed
			ConsoleWrite('>"'&$File&'"'&@CRLF&'"' & $Return[1]&'"'&@CRLF)
			$Update=1
			If $g_Flags[1] = 1 Then IniWrite($g_ProgDir&'\Config\Global\'&$p_Setup&'.ini', 'Mod', $Prefix&'Save', $Return[1])
			_Check_SetScroll('-Name geändert: ['&$Prefix&'Save] von ' & $File & ' nach ' & $Return[1], 1)
		EndIf
		If $g_Flags[2] = 1 And $Update = 1 Then
			If $Return[1] = '' Then
				_Check_SetScroll('!Der Name ist leer.', 1)
				ContinueLoop
			EndIf
			If $Return[2] = 0 Then $Return[2]=_IniRead($Section, $Prefix&'Size', 1)
			If FileExists($g_DownDir & '\' & $Return[1]) Then; remove old files
				If FileGetSize($g_DownDir & '\' & $Return[1]) = $Return[2] Then
					ContinueLoop
				Else
					While 1
						$Test=FileDelete($g_DownDir & '\' & $Return[1])
						If $Test = 0 Then
							$Test=MsgBox(16+5, $g_ProgName&': Löschen', 'Konnte '&$g_DownDir & '\' & $Return[1]&' nicht entfernen.', 0, $g_UI[0])
							If $Test = 2  Then Exit
						Else
							ExitLoop
						EndIf
					WEnd
				EndIf
			EndIf
			$PID=Run('"' & $g_ProgDir & '\Tools\wget.exe" --tries=3 --no-check-certificate --continue --progress=dot:binary  --output-file="'&@TempDir&'\'&$Return[1]&'.log" --output-document="' & $g_DownDir & '\' & $Return[1] & '" "' & $URL & '"', @ScriptDir, @SW_HIDE)
			$DoUpdate=StringRegExp(@OSVersion, 'WIN_VISTA|WIN_2008R2|WIN_7|WIN_2008')
			While ProcessExists($PID)
				If $DoUpdate Then FileRead($g_DownDir & '\' & $Return[1], 1); files are not updated on windows 7. Use this as a workaround.
				GUICtrlSetData($g_UI_Interact[1][6], (FileGetSize($g_DownDir & '\' & $Return[1])*100)/$Return[2])
				Sleep(1000)
			WEnd
			GUICtrlSetData($g_UI_Interact[1][6], 0)
			$Log=FileRead(@TempDir&'\'&$Return[1]&'.log')
			If StringInStr($Log, 'saved ['&$Return[2]&'/'&$Return[2]&']') Then
				FileDelete(@TempDir&'\'&$Return[1]&'.log'); all ok
			ElseIf StringRegExp($Log, 'saved\s\x5b\d*\x5d') Then
				If $g_Flags[1] = 1 Then IniWrite($g_ProgDir&'\Config\Global\'&$p_Setup&'.ini', 'Mod', $Prefix&'Size', FileGetSize($g_DownDir & '\' & $Return[1])); save size for later
			Else
				ShellExecute(@TempDir&'\'&$Return[1]&'.log'); show error-log
			EndIf
		EndIf
	Next
EndFunc

; ---------------------------------------------------------------------------------------------
; Convert spaces for HTML
; ---------------------------------------------------------------------------------------------
Func _StringTranslate($p_String)
	Local $Old, $Return
	$Array=StringSplit($p_String, '')
	For $a=1 to $Array[0]
		If $Array[$a]=' ' Then
			If $Old = ' ' Then
				$Return&='&nbsp;'
			Else
				$Return&=' '
				$Old=' '
			EndIf
		Else
			$Return&=$Array[$a]
			$Old=''
		EndIf
	Next
	Return $Return
EndFunc


#cs
DNT0.9.rar
1195373035_rukrakiav0.7.7z
NMT-V2.0.zip
+135 Calling A
#ce

#cs
$Return=_Net_LinkGetInfo('http://gx005d.mofile.com/OTE3MjIzMDI0ODg1NDEwODo0NjcwNTQ2NjAzOTg0Mjk3OkRpc2sxLzczLzczNDMyOTkxNjAvMi8yNDk4MTA5NzI5MDEzNTU6MTo1MTIwMDowOjEyOTM0NDc4NDg0NjE./43447BCB53D12881B55D6F13F4F74C08/DNT0.9.rar')
ConsoleWrite($Return[1] & @CRLF)
$Return=_Net_LinkGetInfo('http://club.paran.com/club/bbsdownload.do?clubno=1130917&menuno=2667641&file_seq=1195373035&file_name=1195373035_rukrakiav0.7.7z&p_eye=club^ccl^cna^clu^htpdown')
ConsoleWrite($Return[1] & @CRLF)
$Return=_Net_LinkGetInfo('http://nmi.forum-free.net/download/file.php?id=22')
ConsoleWrite($Return[1] & @CRLF)
Exit
#ce

#Region URL-check
$Note=''
Dim $Prefix[14] = [13, '', 'Add', 'CH-Add', 'CZ-Add', 'EN-Add', 'FR-Add', 'GE-Add', 'IT-Add', 'JP-Add', 'KO-Add', 'PO-Add', 'RU-Add', 'SP-Add']

#cs
$Test=StringSplit('imoenfriendship', '|')
Auden|BEAR_ANIMATIONS_D2|bgqe|BGT|BWS-Update|BWS-URLUpdate|cliffkey|DNT|Eilistraee|gavin|gavin_bg2|HARPSCOUT|HOUYI|Hubelpot|imoenfriendship|item_rev|iwditempack|JanQuest|Kari|KHALID|level1npcs|LOHMod|ModKitRemover|Nikita|NML|NMR-HAPPY|NMT|NMTP|randomiser|SAGAMAN|SDMODS|SWYLIF|TheUndying|UoT|VolcanicArmoury|Wikaede|WSR|
For $t=1 to $Test[0]
	_CheckURL($Test[$t])
	;_CheckDownload($Test[$t])
Next
ConsoleWrite(@CRLF&@CRLF&$Note)
Exit
#ce

For $s=1 to $g_Setups[0][0]
	;ConsoleWrite($g_Setups[$s][0] & @CRLF)
	;If $g_Setups[$s][0] <> 'alternatives' Then ContinueLoop

	_CheckURL($g_Setups[$s][0], $g_Setups[$s][1], $s)
Next
ConsoleWrite(@CRLF&@CRLF&$Note)
Exit


Exit
#EndRegion URL-check

; ---------------------------------------------------------------------------------------------
; If you place Au3Exit=X in the Order-section, the setup will close at this point. If X=0, the setup will ask you to start with the next key of the "current-package"-section.
; Usefull if you want to do some things manually, test things until a certain point...
; ---------------------------------------------------------------------------------------------
Func Au3Exit($p_Num = 0)
	_PrintDebug('+' & @ScriptLineNumber & ' Calling Au3Exit')
	DllClose($g_UDll); close the dll for detecting "space"-keypresses
	If $g_STDStream <> '' Then; close the backend-cmd-instance
		StdinWrite($g_STDStream, 'exit' & @CRLF)
		StdinWrite($g_STDStream, @CRLF)
	EndIf
	Exit
EndFunc    ;==>Au3Exit

; ---------------------------------------------------------------------------------------------
; Get the core-settings for the current installation
; ---------------------------------------------------------------------------------------------
Func Au3GetVal($p_Num = 0)
	_PrintDebug('+' & @ScriptLineNumber & ' Calling Au3GetVal')
	$g_Order = IniReadSection($g_BWSIni, 'Order'); reload this to get the new selected functions
	$g_BG1Dir = IniRead($g_UsrIni, 'Options', 'BG1', '')
	$g_BG2Dir = IniRead($g_UsrIni, 'Options', 'BG2', '')
	$g_DownDir = IniRead($g_UsrIni, 'Options', 'Download', '')
	$g_CurrentPackages = IniReadSection($g_UsrIni, 'Current')
	AutoItSetOption('GUIOnEventMode', 1)
	If IniRead($g_BWSIni, 'Order', 'Au3Select', 1) = 0 And GUICtrlRead($g_UI_Button[0][1]) = '' Then; this is a restart > show the question-dialog
		_Misc_SetLang()
		GUICtrlSetState($g_UI_Seperate[8][0], $GUI_SHOW)
		For $o = 1 To $g_Order[0][0]
			If $g_Order[$o][1] = '0' Then ContinueLoop
			If StringRegExp('Au3BuildGui,Au3Detect,Au3GetVal,Au3ResetEdit', '(\A|\x2c)'&$g_Order[$o][0]&'(\z|\x2c)') Then ContinueLoop
			$Nextstep=$g_Order[$o][0]
			ExitLoop
		Next
		If StringRegExp($g_FItem, '\A\d{1,}\z') Then
			$Array = StringSplit(StringStripCR(FileRead($g_ProgDir&'\Config\Select.txt')), @LF)
			If IniRead($g_UsrIni, 'Options', 'GroupInstall', 0) =  1 Then $Array = _Install_ModifyForGroupInstall($Array); always install in groups
			$a=$g_FItem
			While StringRegExp($Array[$a], '(?i)\A(CMD|ANN|DWN|GRP)') And $a<$Array[0]
				$a+=1
			WEnd
			$Split=StringSplit($Array[$a], ';')
			$Name=$Split[2]
			$Name=IniRead($g_MODIni, $Name, 'Name', $Name); SetupName
			$Comp=$Split[3]; CompNumber
			$Answer = _Misc_MsgGUI(2, $g_ProgName, StringFormat(_GetTR($g_UI_Message, '0-L4'), $Nextstep, $Name&', #'&$Comp), 2, _GetTR($g_UI_Message, '0-B1'), _GetTR($g_UI_Message, '0-B2')); => continue installation?
		Else
			$Name=IniRead($g_MODIni, $g_FItem, 'Name', $g_FItem); SetupName
			$Answer = _Misc_MsgGUI(2, $g_ProgName, StringFormat(_GetTR($g_UI_Message, '0-L4'), $Nextstep, $Name), 2, _GetTR($g_UI_Message, '0-B1'), _GetTR($g_UI_Message, '0-B2')); => continue installation?
		EndIf
		If $Answer = 2 Then;Continue
			$g_Flags[14]=IniRead($g_UsrIni, 'Options', 'AppType', ''); need this to populate tree for dependencies
			_Misc_SetLang()
			_Tree_Populate(0)
			_Tree_Reload(0)
			If $Nextstep <> 'Au3Net' Then _Process_Gui_Create(2)
			GUICtrlSetState($g_UI_Button[0][1], $GUI_DISABLE)
			GUICtrlSetState($g_UI_Button[0][2], $GUI_DISABLE)
		ElseIf $Answer = 1 Then ; No
			$g_FItem = 1
			IniDelete($g_BWSIni, 'Faults'); remove old errors
			_ResetInstall()
			$g_Order = IniReadSection($g_BWSIni, 'Order'); Reread to be aware of the changes
			$g_CurrentOrder = 2
			GUICtrlSetState($g_UI_Seperate[2][0], $GUI_SHOW); show the fileselection-dialog
			AutoItSetOption('GUIOnEventMode', 0)
		EndIf
	Else
		GUICtrlSetState($g_UI_Button[0][1], $GUI_DISABLE)
		GUICtrlSetState($g_UI_Button[0][2], $GUI_DISABLE)
	EndIf
EndFunc   ;==>Au3GetVal

; ---------------------------------------------------------------------------------------------
; Generate the current list of exe's in the section-list
; ---------------------------------------------------------------------------------------------
Func _CreateList($p_Num='s'); $a=Type ('s' = setup, 'c' = chapters)
	$Array=_FileSearch($g_ProgDir&'\Config\Global', '*')
	Local $Setups[$Array[0]+1][2]
	For $a=1 to $Array[0]
		$Array[$a]=StringRegExpReplace($Array[$a], '\x2eini\z', '')
		$Setups[0][0]+=1
		$Setups[$Setups[0][0]][0]=$Array[$a]
		$Setups[$Setups[0][0]][1]=IniRead($g_ProgDir&'\Config\Global\'&$Array[$a]&'.ini', 'Mod', 'Name', $Array[$a])
	Next
	_ArraySort($Setups, 0, 1)
	Return $Setups
EndFunc   ;==>_CreateList

; ---------------------------------------------------------------------------------------------
; Generate the current list of exe's in the section-list
; ---------------------------------------------------------------------------------------------
Func _GetCurrent()
	$Current = IniReadSection($g_UsrIni, 'Current')
	If @error Then
		Local $Current[1][2]
		$Current[0][0] = 0
	EndIf
	If $g_Flags[21] = '' Then Return $Current; BWS will not install BG1EE-mods and EET
	$Num = StringRegExpReplace($g_Flags[14], '(?i)\ABG|EE\z', '')
	Local $Return[$Current[0][0] + 1][2]
	For $c = 1 To $Current[0][0]
		If StringRegExp($g_Flags[20 + $Num], '(?i)(\A|\x7c)' & $Current[$c][0] & '(\z|\x7c)') Then; trim selection to BG1EE/BG2EE mods only
			$Return[0][0] += 1
			$Return[$Return[0][0]][0] = $Current[$c][0]
			$Return[$Return[0][0]][1] = $Current[$c][1]
		EndIf
	Next
	ReDim $Return[$Return[0][0] + 1][2]
	Return $Return
EndFunc   ;==>_GetCurrent

; ---------------------------------------------------------------------------------------------
; Gather all the information from single small mod-files and write them into the bigger ini-files
; ---------------------------------------------------------------------------------------------
Func _GetGlobalData($p_Game='')
	Local $LastMod, $Mods='|', $Lang=StringSplit('EN|GE|RU', '|'), $LCodes[13]=[12, 'GE','EN','FR','PO','RU','IT','SP','CZ','KO','CH','JP','PR']
	Local $Edit, $GameLen=StringLen($p_Game), $GameToken=''; 'BCIP'
	If $p_Game <> '' Then; Enable testing of this function or use defaults...
		$g_GConfDir=$g_ProgDir&'\Config\'&$p_Game
	Else
		$p_Game=$g_Flags[14]
	EndIf
	If FileExists($g_GConfDir&'\Mod.ini') Then Return
	$Current = GUICtrlRead($g_UI_Seperate[0][0])+1
	_Misc_ProgressGUI(_GetTR($g_UI_Message, '0-T2'), _GetTR($g_UI_Message, '0-L2')); => building dependencies-table
	GUISwitch($g_UI[0])
	$Text=FileRead($g_GConfDir&'\Select.txt')
	; Get tokens (first letter) of games, should be BCIP (BG/CA/IWD/PST-games)
	$Array=_FileSearch($g_ProgDir&'\Config', '*')
	For $a=1 to $Array[0]
		If StringRegExp($Array[$a], '(?i)\x2e|Global') Then ContinueLoop
		$Token=StringLeft($Array[$a], 1)
		If Not StringInStr($GameToken, $Token) Then $GameToken&=$Token
	Next
	; Get mods used in select.txt
	$Text=StringRegExpReplace($Text, '(?i)(\A|\n)(DWN|MUC|STD|SUB)', '--')
	$Array=StringRegExp($Text, '--\x3b[^\x3b]*\x3b' , 3)
	For $a=0 to UBound($Array)-1
		$Mod=StringRegExpReplace($Array[$a], '\A.{3}|.\z', '')
		If $Mod=$LastMod Then ContinueLoop
		$Mods&=$Mod&'|'
		$LastMod=$Mod
	Next
	$Array=StringSplit($Mods, '|')
	_ArraySort($Array, 0, 1)
	GUICtrlSetData($g_UI_Interact[9][1], 5); set the progress
	GUICtrlSetData($g_UI_Static[9][2], '5 %')
	; Open file-handles
	If Not FileExists($g_GConfDir) Then DirCreate($g_GConfDir)
	$h_Mod=FileOpen($g_GConfDir&'\Mod.ini', 2)
	For $l=1 to $Lang[0]
		Assign('h_Mod_'&$Lang[$l], FileOpen($g_GConfDir&'\Mod-'&$Lang[$l]&'.ini', 1)); don't overwrite file, contains [Preselection]
		FileWrite(Eval('h_Mod_'&$Lang[$l]), @CRLF&@CRLF&'[Description]'&@CRLF)
	Next
	For $l=1 to $LCodes[0]
		Assign('h_WeiDU_'&$LCodes[$l], FileOpen($g_GConfDir&'\WeiDU-'&$LCodes[$l]&'.ini', 2))
	Next
	; copy/write content of files to different file-handles
	For $a=2 to $Array[0]
		GUICtrlSetData($g_UI_Interact[9][1], 5+($a * 95 / $Array[0])); set the progress
		If _MathCheckDiv($a, 10) = 2 Then GUICtrlSetData($g_UI_Static[9][2], Round(5+($a * 95 / $Array[0]), 0) & ' %')
		If $Array[$a]=$Array[$a-1] Then ContinueLoop
		$Text=FileRead($g_ProgDir&'\Config\Global\'&$Array[$a]&'.ini')
		If @error Then ConsoleWrite($Array[$a]&' not found'&@CRLF)
		$Text=StringSplit(StringStripCR($Text), @LF)
		For $t=1 to $Text[0]
			$LineType=StringLeft($Text[$t], 1)
			If $LineType = '@' Then; translations don't need special attention
			ElseIf $LineType = '[' Then; that's a section -> adjust to different handle
				$File=StringReplace(StringRegExpReplace($Text[$t], '\A(\s|)\x5b|\x5d(|\s)\z', ''), '-', '_')
				If $File='Description' Then; special handling for mods descriptions
					While 1
						$t+=1
						If $t>$Text[0] Or StringLeft($Text[$t], 1) = '[' Then ExitLoop
						$Desc=StringRegExpReplace($Text[$t], '\A[^=]*=', '')
						If @extended Then
							If StringRegExp($Text[$t], '\A[^=]*_') Then; exception found
								If StringLeft($Text[$t], $GameLen) = $p_Game Then; fitting for this game
									$Split=StringInStr($Text[$t], '=')
									$Key=StringMid($Text[$t], $GameLen+2, $Split-$GameLen-2)
									If $Desc='' Then $Desc=' '
									$Edit&=$Key&'|Description|'& $Array[$a]&'|'&$Desc&'||'; save for later
								EndIf
							EndIf
							FileWrite(Eval('h_Mod_'&StringMid($Text[$t], 5, 2)), $Array[$a]&'='&$Desc&@CRLF)
						EndIf
					WEnd
					$t-=1
				Else
					FileWrite(Eval('h_'&$File), '['&$Array[$a]&']'&@CRLF)
				EndIf
				ContinueLoop
			ElseIf StringInStr($GameToken, $LineType) Then; this could be some line with a special adjustment for certain games
				If StringRegExp($Text[$t], '\A[^=]*_') Then; found
					If StringLeft($Text[$t], $GameLen) = $p_Game Then; fitting for this game
						$Split=StringInStr($Text[$t], '=')
						$Key=StringMid($Text[$t], $GameLen+2, $Split-$GameLen-2)
						$Value=StringRegExpReplace($Text[$t], '\A[^=]*=', '')
						If $Value='' Then $Value=' '
						$Edit&=StringReplace($File, '_', '-')&'|'&$Array[$a]&'|'&$Key&'|'&$Value&'||'; save for later
					EndIf
					ContinueLoop
				EndIf
			EndIf
			FileWrite(Eval('h_'&$File), $Text[$t]&@CRLF); write current line
		Next
	Next
	; Close handles
	FileClose($h_Mod)
	For $l=1 to $Lang[0]
		FileClose(Eval('h_Mod_'&$Lang[$l]))
	Next
	For $l=1 to $LCodes[0]
		FileClose(Eval('h_WeiDU_'&$LCodes[$l]))
	Next
	; Handle exceptions
	$Edit=StringSplit($Edit, '||', 1)
	For $e=1 to $Edit[0]-1
		$Split=StringSplit($Edit[$e], '|')
		If $Split[4]=' ' Then
			IniDelete($g_GConfDir&'\'&$Split[1]&'.ini', $Split[2], $Split[3])
		Else
			IniWrite($g_GConfDir&'\'&$Split[1]&'.ini', $Split[2], $Split[3], $Split[4])
		EndIf
	Next
	_Misc_SetTab($Current)
EndFunc    ;==>_GetGlobalData

; ---------------------------------------------------------------------------------------------
; Well, print a debug message. :D
; ---------------------------------------------------------------------------------------------
Func _PrintDebug($p_String, $p_Show = 0)
	ConsoleWrite($p_String & @CR)
	If $p_Show = 1 Then MsgBox(64, $g_ProgName, $p_String)
EndFunc   ;==>_PrintDebug

; ---------------------------------------------------------------------------------------------
; Set all values to start a new install
; ---------------------------------------------------------------------------------------------
Func _ResetInstall($p_DeletePause=1)
	IniWrite($g_BWSIni, 'Order', 'Au3Select', '1'); Enable the start of the selection-gui
	IniWrite($g_BWSIni, 'Order', 'Au3PrepInst', '1'); remove cds
	IniWrite($g_BWSIni, 'Order', 'Au3CleanInst', '1'); backup
	IniWrite($g_BWSIni, 'Order', 'Au3Net', '1'); download
	IniWrite($g_BWSIni, 'Order', 'Au3NetFix', '1'); post-download-processess
	IniWrite($g_BWSIni, 'Order', 'Au3NetTest', '1'); download test
	IniWrite($g_BWSIni, 'Order', 'Au3Extract', '1'); extract
	IniWrite($g_BWSIni, 'Order', 'Au3ExFix', '1'); extract
	IniWrite($g_BWSIni, 'Order', 'Au3ExTest', '1'); extract test
	IniWrite($g_BWSIni, 'Order', 'Au3RunFix', '1'); fixes and patches
	IniWrite($g_BWSIni, 'Order', 'Au3Install', '1'); install
	IniWrite($g_BWSIni, 'Options', 'Start', '1')
	FileMove($g_LogDir & '\*.txt', $g_LogDir & '\Bak\', 9); save old logs
	If DirGetSize($g_LogDir & '\Bak') > 0 Then
		DirMove($g_LogDir & '\Bak', $g_LogDir & '\Bak-'& @YEAR & @MON & @MDAY & @HOUR & @MIN)
	Else
		DirRemove($g_LogDir & '\Bak')
	EndIf
	IniDelete($g_UsrIni, 'RemovedFromCurrent'); delete old failures-mesages
	If $p_DeletePause = 1 Then IniDelete($g_UsrIni, 'Pause'); delete old pauses
EndFunc   ;==>_ResetInstall