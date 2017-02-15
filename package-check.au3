#cs
	20.03.2012 -- Added checks for missing MUC/SUB-Headers in Select.txt, find STD that are MUCs and
				  mods with manual downloads that are not disabled.
				  Adjusted Select_Connection_Exist and Select_Subs to new CSV-format.
	21.03.2012 -- Rewrote Select_Dupes to speed things up (40 times faster)
#ce

AutoItSetOption('WinTitleMatchMode', 2); set a more flexible way to search for windows
AutoItSetOption('GUIResizeMode', 1); resize and reposition GUI-elements according to new window size
AutoItSetOption('TrayIconDebug', 1); shows the current script line in the tray icon tip to help debugging

; Global are named with a $g_ , parameters with a $p_ . Normal variables don't have a prefix.
; files and folders
Global $g_BaseDir = StringLeft(@ScriptDir, StringInStr(@ScriptDir, '\', 1, -1) - 1), $g_ProgName = 'BiG World Setup'
Global $g_ProgDir = $g_BaseDir & '\BiG World Setup', $g_LogDir = $g_ProgDir & '\Logs', $g_DownDir = $g_BaseDir & '\BiG World Downloads'
Global $g_RemovedDir = $g_BaseDir & '\BiG World Old Files', $g_BackupDir = $g_BaseDir & '\BiG World Clean Install'
Global $g_BWSIni = $g_ProgDir & '\Config\Setup.ini', $g_UsrIni = $g_ProgDir & '\Config\User.ini'
Global $g_ModIni, $g_LogFile = @ScriptDir & '\BWS Check.txt', $g_Flags[30]

#cs
Global $g_BG1Dir, $g_BG2Dir, $g_TextDir, $g_FixDir,
Global $g_ATrans = StringSplit(IniRead($g_BWSIni, 'Options', 'AppLang', 'EN|GE|SP'), '|'), $g_ATNum = 1, $g_MLang
Global $g_TRAIni = $g_ProgDir & '\Config\Translation-' & $g_ATrans[$g_ATNum] & '.ini'
#ce

#cs
WeiDU_CompareTranslation()

Func WeiDU_CompareTranslation()
	$Path='D:\Download\9.4.X\BiG World Installpack v9.4.3\BiG World Installpack'
	$TraL=StringSplit('English|German|Spanish|Russian', '|')
	$TraS=StringSplit('En|Ge|Sp|Ru', '|')
	For $t=1 to $TraL[0]
		$TraL[$t]=FileRead($Path&'\'&$TraL[$t]&'\Tra.txt')
	Next
	$Section = IniReadSectionNames($g_ModIni)
	For $s=1 to $Section[0]
		;ConsoleWrite('>'&$Section[$s] & @CRLF)
		$Show=0
		$Tra=IniRead($g_ModIni, $Section[$s], 'Tra', '')
		For $t=1 to $TraS[0]
			If StringInStr($Tra, $TraS[$t]) Or StringInStr($Tra, '--') Then
				$TempI=_GetTRA($Tra, $TraS[$t])
				$TempT=StringRegExp($TraL[$t], '(?i)'&$Section[$s]&'=\d\s\D', 3)
				If Not IsArray($TempT) Then
					ConsoleWrite('>Fehlender Eintrag in dem BWP: '&$Section[$s] & ':' & $TraS[$t] & @CRLF)
					ContinueLoop
				EndIf
				;ConsoleWrite($TempT[0] & @CRLF)
				If StringRight($TempT[0], 1) <> 'N' Then ConsoleWrite('-Hier ist eine native Übersetzung verfügbar: Mod '&$Section[$s] &', Sprache '&$TraS[$t] & ' mit Nummer ' &$TempT[0] & @CRLF)
				$TempT=StringRegExpReplace($TempT[0], '(?i)\A.*=|\s\D\z', '')
				If $TempI = $TempT Then
					;ConsoleWrite('+'&$TempI&':'&$TraS[$t] & @CRLF)
				Else
					ConsoleWrite('!Hier unterscheiden sich die Nummern im BWS und BWP: Mod '&$Section[$s] &', Sprache '&$TraS[$t] & ' im BWP '&$TempT & ', BWS ' & $TempI&@CRLF)
				EndIf
			EndIf
		Next
	Next

	For $t=1 to $TraL[0]
		ConsoleWrite('>>>>>>'&$TraS[$t]&'>>>>>>>' & @CRLF)
		$Temp = StringSplit(StringStripCR($TraL[$t]), @LF)
		For $r=1 to $Temp[0]
			$TempT=StringRegExpReplace($Temp[$r], '(?i)=.*\z', '')
			$Found=0
			For $s=1 to $Section[0]
				If $Section[$s] = $TempT Then
					$Found=1
					ExitLoop
				EndIf
			Next
			If $Found = 0 Then ConsoleWrite('!'&$TempT & @CRLF)
		Next
	Next
EndFunc

Exit
#ce


#include'Includes\01_UDF1.au3'

$g_GUI=GuiCreate('BWS Check: v0.6', 630, 330, -1, -1, $WS_MINIMIZEBOX + $WS_MAXIMIZEBOX + $WS_CAPTION + $WS_POPUP + $WS_SYSMENU + $WS_SIZEBOX)

Global $g_Tests[19]=[18, 'Code_AbandonedFunc','Code_ANSI','Code_ProperEndFunc','Code_ProperGetTra','Mod_Test', 'Mod_Sort','Select_Dupes','Select_Connection_Exist','Select_HasHeader','Select_IsMUC','Select_ManualDisabled','Select_Subs','Trans_Missing','Trans_Compare','Weidu_Abandoned','Weidu_Missing', 'Weidu_NoTXT', 'Weidu_Sort']; => All functions
Global $g_TestsD[19]=[18, 'Lists unused code-functions', 'List non-std characters', 'Puts hints into EndFunc-line', 'Looks for translation-hints', 'Checks testing conditions', 'Sort the mod.ini', 'Get duplicated entries', 'Find out if connections are defined in select.txt', 'Check if MUC and SUB-headers exist', 'Check if STD may be a MUC', 'List mods that are selected per default but only have manual downloads', 'List MUC/SUB which have a different selection than the header','Check if a translation used in the code cannot be found','Check if translations can be found in all languages','List WeiDU-entries that are not used any more','List missing WeiDU-entries', 'List false no-text TRA-entries', 'Sort Weidu-entries']; => All descriptions

$g_Start=0

$g_Tab=GUICtrlCreateTab(15, 10, 600, 70)
$g_Tools_Tab=GUICtrlCreateTabItem('Tools')
	$g_Button1 = GuiCtrlCreateButton('Enable All', 30, 45, 100, 20)
	$g_Button2 = GuiCtrlCreateButton('Disable All', 145, 45, 100, 20)
	$g_Button3 = GuiCtrlCreateButton('Recycle Backups', 260, 45, 100, 20)
	If Not FileExists('Config\*.bak') Then GUICtrlSetState($g_Button3, $GUI_DISABLE)
	$g_Combo = GUICtrlCreateCombo('', 380, 45, 220, 20)

$g_Code_Tab=GUICtrlCreateTabItem('Code')
$g_Mod_Tab=GUICtrlCreateTabItem('Mod')
$g_Select_Tab=GUICtrlCreateTabItem('Select')
$g_Trans_Tab=GUICtrlCreateTabItem('Translation')
$g_WeiDU_Tab=GUICtrlCreateTabItem('WeiDU')
$g_Output_Tab=GUICtrlCreateTabItem('Output')
	$g_Label1 = GuiCtrlCreateLabel('Start', 30, 40, 570, 20)
	GUICtrlSetFont($g_Label1, 8, 800, 4, 'MS Sans Serif')
	$g_Label2 = GuiCtrlCreateLabel('', 30, 60, 570, 20)
GUICtrlCreateTabItem('')
$g_Progress1 = GuiCtrlCreateProgress(15, 75, 600, 15)
$g_Progress2 = GuiCtrlCreateProgress(15, 100, 600, 15)
$g_Edit = GuiCtrlCreateEdit('', 15, 120, 600, 170)
$g_Button = GuiCtrlCreateButton('Start', 15, 290, 600, 20)
GUICtrlSetState($g_Button, $GUI_FOCUS+$GUI_DEFBUTTON)

_GUICtrlEdit_SetLimitText($g_Edit, 64000)

; place checkboxes in the correct tabs, add tips and assign them to a variable
Local $OldTab=''
For $g=1 to $g_Tests[0]
	$Tab=StringRegExpReplace($g_Tests[$g], '_.*', '')
	If $Tab <> $OldTab Then
		GuiSwitch($g_GUI, Eval('g_'&$Tab&'_Tab'))
		$OldTab = $Tab
		$X=0
	EndIf
	$Name=StringRegExpReplace($g_Tests[$g], '\A[^_]*_', '')
	$Len=25+StringLen($Name)*6
	Assign ($g_Tests[$g], GUICtrlCreateCheckbox($Name, 30+$X, 45, $Len))
	;GUICtrlSetState(-1, $GUI_CHECKED)
	GUICtrlSetTip(-1, $g_TestsD[$g])
	$X+=$Len+10
Next

$Games=''
Local $File = _FileSearch('Config', '*')
For $f=1 to $File[0]
	If Not StringInStr(FileGetAttrib('Config\'&$File[$f]), 'D') Then ContinueLoop
	$Games &= '|'&$File[$f]
Next
GUICtrlSetData($g_Combo, $Games)


GuiSetState()
While 1
	$g_msg = GuiGetMsg()
	Switch $g_msg
	Case $GUI_EVENT_CLOSE
		ExitLoop
	Case $g_Button
		;If $g_Start  = 1 Then Exit
		$g_Flags[14]=GUICtrlRead($g_Combo)
		$g_GConfDir=@ScriptDir&'\Config\'&$g_Flags[14]
		If $g_GConfDir = @ScriptDir&'\Config\' Then ContinueLoop
		$g_ModIni = $g_GConfDir & '\Mod.ini'
		FileClose(FileOpen($g_LogFile, 2))
		While ControlCommand($g_GUI, '', $g_Tab, "CurrentTab", "") < 7; move to output-tab
			ControlCommand($g_GUI, '', $g_Tab, "TabRight", "")
		WEnd
		For $g_t = 1 to $g_Tests[0]
			$State=GUICtrlRead(Eval($g_Tests[$g_t])); see if the item is check or not
			If $State = 4 Then ContinueLoop
			_Process_Log(@CRLF&@CRLF&'>>>'& $g_Tests[$g_t]&'<<<')
			Call($g_Tests[$g_t])
			GUICtrlSetData($g_Progress1, $g_t*100/$g_Tests[0])
		Next
		_Process_Log('Finished')
		GUICtrlSetData($g_Label1, 'Finished')
		GUICtrlSetData($g_Label2, '')
		GUICtrlSetData($g_Progress1, 100)
		GUICtrlSetData($g_Progress2, 100)
		If Not FileExists('Config\*.bak') Then
			GUICtrlSetState($g_Button3, $GUI_DISABLE)
		Else
			GUICtrlSetState($g_Button3, $GUI_ENABLE)
		EndIf
		;GUICtrlSetData($g_Button, 'Exit')
		;$g_Start = 1
	Case $g_Button1
		For $g_t=1 to $g_Tests[0]
			$State=GUICtrlSetState(Eval($g_Tests[$g_t]), $GUI_CHECKED); see if the item is check or not
		Next
	Case $g_Button2
		For $g_t=1 to $g_Tests[0]
			$State=GUICtrlSetState(Eval($g_Tests[$g_t]), $GUI_UNCHECKED); see if the item is check or not
		Next
	Case $g_Button3
		Local $File = _FileSearch('Config', '*.bak')
		For $f=1 to $File[0]
			FileRecycle(@ScriptDir&'\Config\'&$File[$f])
		Next
		GUICtrlSetState($g_Button3, $GUI_DISABLED)
	Case Else
		;;;
	EndSwitch
WEnd
Exit

#Region BWS
; ---------------------------------------------------------------------------------------------
; Fetch ansi-strings in the source-code
; ---------------------------------------------------------------------------------------------
Func Code_ANSI()
	GUICtrlSetData($g_Label1, 'BWS-Code: Ansi-characters')
	_CheckANSI('Debug.au3')
	_CheckANSI('BiG World Setup.au3')

	$search = FileFindFirstFile("Includes\*.au3")
	If $search <> -1 Then
		While 1
			$file = FileFindNextFile($search)
			If @error Then ExitLoop
			_CheckANSI('Includes\' & $file)
		WEnd
	EndIf
	FileClose($search)
EndFunc   ;==>Code_ANSI

; ---------------------------------------------------------------------------------------------
; Add the functions name as a comment to the EndFunc-line
; ---------------------------------------------------------------------------------------------
Func Code_ProperEndFunc()
	GUICtrlSetData($g_Label1, 'BWS-Code: Proper EndFunc-entries')
	Local $File = _FileSearch('Includes', '*')
	$File[0]+=1
	ReDim $File[$File[0]+1]
	$File[$File[0]] = 'BiG World Setup.au3'
	For $f=1 To $File[0]
		GUICtrlSetData($g_Label2, $File[$f])
		GUICtrlSetData($g_Progress2, $f*100/$File[0])
		If StringRegExp(StringLeft($File[$f], 1), '\d') Then $File[$f] = 'Includes\' & $File[$f]
		$Array = StringSplit(StringStripCR(FileRead($File[$f])), @LF)
		$Handle = FileOpen($File[$f], 2)
		For $a = 1 To $Array[0]
			If StringRegExp($Array[$a], '(?i)\AFunc\s') Then
				$Func = StringRegExpReplace($Array[$a], '(?i)\AFunc\s|\S\s.*|\x28.*', '')
			ElseIf StringRegExp($Array[$a], '(?i)\AEndFunc(\s|\z)') And Not StringInStr($Array[$a], '==>') Then
				$Array[$a] = 'EndFunc    ;==>' & $Func
				_Process_Log($Func & ' ('&$File[$f]&') corrected')
			EndIf
			If $a = $Array[0] Then
				FileWrite($File[$f], $Array[$a])
			Else
				FileWriteLine($File[$f], $Array[$a])
			EndIf
		Next
		FileClose($Handle)
	Next
EndFunc   ;==>Code_ProperEndFunc

; ---------------------------------------------------------------------------------------------
; Look for short translation-hints/info missing in the source-code
; ---------------------------------------------------------------------------------------------
Func Code_ProperGetTra()
	GUICtrlSetData($g_Label1, 'BWS-Code: Proper GetTR-entries')
	Local $File = _FileSearch('Includes', '*')
	$File[0]+=1
	ReDim $File[$File[0]+1]
	$File[$File[0]] = 'BiG World Setup.au3'
	For $f=1 To $File[0]
		GUICtrlSetData($g_Progress2, $f*100/$File[0])
		GUICtrlSetData($g_Label2, $File[$f])
		If StringRegExp(StringLeft($File[$f], 1), '\d') Then $File[$f] = 'Includes\' & $File[$f]
		$Array = StringSplit(StringStripCR(FileRead($File[$f])), @LF)
		For $a = 1 To $Array[0]
			If StringInStr($Array[$a], '_GetTR') Or StringInStr($Array[$a], '_GetSTR') Then
				If StringInStr($Array[$a], '_GetTRA') Then ContinueLoop
				If StringRegExp($Array[$a], '\A(Func|EndFunc)') = 1 Then ContinueLoop
				If Not StringInStr($Array[$a], '=>') Then
					If StringInStr($Array[$a], 'GetTR($p_Handle, $p_Num') Then ContinueLoop
					_Process_Log($File[$f]&':'& $a & ':' & StringStripWS($Array[$a], 3))
				EndIf
			EndIf
		Next
	Next
EndFunc   ;==>Code_ProperGetTra

; ---------------------------------------------------------------------------------------------
; Search for abandoned functions
; ---------------------------------------------------------------------------------------------
Func Code_AbandonedFunc($p_Func='')
	GUICtrlSetData($g_Label1, 'BWS-Code: Search abandoned functions')
	Local $File = _FileSearch('Includes', '*')
	$File[0]+=1
	ReDim $File[$File[0]+1]
	$File[$File[0]] = 'BiG World Setup.au3'
	For $f=1 To $File[0]
		If StringRegExp(StringLeft($File[$f], 1), '\d') Then $File[$f] = 'Includes\' & $File[$f]
		$Array = StringSplit(StringStripCR(FileRead($File[$f])), @LF)
		Assign('Array'&$f, $Array, 2)
	Next
	If $p_Func <> '' Then
		_SearchFunc($p_Func, $File)
		Return
	EndIf
	For $f=1 To $File[0]
		GUICtrlSetData($g_Label2, $File[$f])
		GUICtrlSetData($g_Progress2, $f*100/$File[0])
		If StringRegExp ($File[$f], '(01|02)_') Then ContinueLoop
		$Array = Eval('Array'&$f)
		For $a=1 to $Array[0]
			If StringLeft($Array[$a], 4) = 'Func' Then
				$Func = StringRegExpReplace($Array[$a], '(?i)Func\s{1,}', '')
				$Func = StringRegExpReplace($Func, '(\s|\x28){1,}.*', '')
				$Found = _SearchFunc($Func, $File, 0)
				If $Found = 0 Then
					If $Func = '_Install_BatchRun' And StringInStr(FileRead('Includes\09_Install.au3'), "AutoItSetOption('OnExitFunc','_Install_BatchRun')") Then ContinueLoop
					If StringInStr($Func, '_Test_CheckRequieredFiles_') And StringInStr(FileRead('Includes\17_Testing.au3'), "Call ('_Test_CheckRequieredFiles_'&$g_Flags[14])") Then ContinueLoop
					If $Func = '_PrintDebug' Then ContinueLoop
					_Process_Log($Func & ' is not used')
				Else
					;ConsoleWrite('+' & $Func & ' is used ' & $Found & ' times' & @CRLF)
				EndIf
			EndIf
		Next
	Next
EndFunc   ;==>Code_SearchFunc
#EndRegion BWS
#Region Mod.ini
; ---------------------------------------------------------------------------------------------
; Check Test-conditions in the mod.ini
; ---------------------------------------------------------------------------------------------
Func Mod_Test($p_File=$g_ModIni)
	GUICtrlSetData($g_Label2, 'Mod.ini')
	GUICtrlSetData($g_Label1, 'Mod.ini: Test')
	$DownloadOnly = IniRead($g_GConfDir&'\Game.ini', 'Options', 'DownloadOnly', '')
	$Array=IniReadSectionNames($g_ModIni)
	For $a=1 to $Array[0]
		GUICtrlSetData($g_Progress2, $a*100/$Array[0])
		If StringRegExp($DownloadOnly, '(\A|,)'&$Array[$a]&'(,|\z)') Then ContinueLoop
		$ReadSection=IniReadSection($g_ModIni, $Array[$a])
		For $r=1 to $ReadSection[0][0]
			If StringInStr($ReadSection[$r][0], 'AddDown') Then
				$Test= _IniRead($ReadSection, StringReplace($ReadSection[$r][0], 'Down', 'Test'), '')
				If StringRegExp ($Test, '\A[^.]{1,}\x2e') = 0 Then
					_Process_Log($Array[$a] & ' = ' & $ReadSection[$r][0])
					_Process_Log('No vaild teststring declared')
				ElseIf StringInStr($Test, ':') = 0 Then
					_Process_Log($Array[$a] & ' = ' & $ReadSection[$r][0])
					_Process_Log('Teststring without size-condition')
				Else
					$SubString = StringSplit($Test, ':')
					If $SubString[1] = '' Then
						_Process_Log($Array[$a] & ' = ' & $ReadSection[$r][0])
						_Process_Log('File for testing is not declared')
					ElseIf StringRegExp($SubString[2], '\A([0123456789]*|-)\z') = 0 Then
						_Process_Log($Array[$a] & ' = ' & $ReadSection[$r][0])
						_Process_Log('Size for testing is not declared correctly.')
					EndIf
				EndIf
			EndIf
		Next
	Next
EndFunc

; ---------------------------------------------------------------------------------------------
; Sort the mod.ini
; ---------------------------------------------------------------------------------------------
Func Mod_Sort($p_File=$g_ModIni)
	GUICtrlSetData($g_Label1, 'Mod.ini: Sort')
	Local $Prefixes[15] = [14, '', 'Add', 'CH-Add','CZ-Add', 'EN-Add', 'FR-Add', 'GE-Add', 'IT-Add', 'JP-Add', 'KO-Add', 'PO-Add', 'PR-Add', 'RU-Add', 'SP-Add']
	Local $Entries[13] = [12, 'Name', 'Rev', 'Type', 'Link', 'Down', 'Save', 'Size', 'Test', 'Ren', 'Tra', 'NotFixed', 'Wiki']
	_SortIni($p_File)
	$Handle = FileOpen($p_File & '.new', 2)
	$Array = StringSplit(StringStripCR(FileRead($p_File)), @LF)
	For $a = 1 To $Array[0]
		GUICtrlSetData($g_Label2, 'Mod.ini')
		GUICtrlSetData($g_Progress2, $a*100/$Array[0])
		If StringRegExp($Array[$a], '\A\x5b') Then
			FileWriteLine($Handle, $Array[$a])
			Global $SearchArray = '', $SortArray = ''
			For $t = $a + 1 To $Array[0]
				If $Array[$t] = '' Then ContinueLoop
				If StringRegExp($Array[$t], '\A\x5b') Then ExitLoop
				$SearchArray &= '|||' & $Array[$t]
			Next
			$SearchArray = StringSplit(StringTrimLeft($SearchArray, 3), '|||', 1)
			For $e = 1 To 4
				_SortRead($SortArray, $SearchArray, $Entries[$e])
			Next
			For $p = 1 To $Prefixes[0]
				For $e = 5 To 9
					_SortRead($SortArray, $SearchArray, $Prefixes[$p] & $Entries[$e])
				Next
			Next
			For $e = 10 To 12
				_SortRead($SortArray, $SearchArray, $Entries[$e])
			Next
			$SortArray = StringSplit(StringTrimLeft($SortArray, 3), '|||', 1)
			For $s = 1 To $SortArray[0]
				FileWriteLine($Handle, $SortArray[$s])
			Next
			FileWriteLine($Handle, '')
			$a = $t - 1
		EndIf
	Next
	FileClose($Handle)
	FileMove($p_File, $g_GConfDir&'\Bak\', 9)
	FileMove($p_File & '.new', $p_File)

	$File=_FileSearch($g_GConfDir, 'Mod-*.ini')
	For $f=1 to $File[0]
		FileCopy($File[$f], $g_GConfDir&'\Bak\'&$File[$f], 1)
		$Description=_IniReadSection($g_GConfDir&'\'&$File[$f], 'Description')
		_ArraySort($Description, 0, 1)
		IniWriteSection($g_GConfDir&'\'&$File[$f], 'Description', $Description)
	Next
EndFunc   ;==>Mod_Sort
#EndRegion Mod.ini
#Region Select
; ---------------------------------------------------------------------------------------------
; Look for doubled installation-entries in the select.txt
; ---------------------------------------------------------------------------------------------
Func Select_Dupes()
	GUICtrlSetData($g_Label1, 'Select.ini: Dupes')
	Local $Found='|'
	$Array = StringSplit(StringStripCR(FileRead($g_GConfDir&'\Select.txt')), @LF)
	Local $Setup[100] = [99]
	For $s=1 to $Setup[0]
		$Setup[$s]='|'
	Next
	For $a = 1 To $Array[0]
		GUICtrlSetData($g_Progress2, $a*100/$Array[0])
		$Split=StringSplit($Array[$a], ';')
		If StringInStr('DWN|CMD|ANN|GRP|IF |FI |ELS', $Split[1]) Then ContinueLoop
		If $Split[3] = 'Init' Then ContinueLoop
		$Setup[Asc(StringUpper(StringLeft($Split[2], 1)))]&=$Split[2]&';'&$Split[3]&';|'; SetupName:Comp
	Next
	For $s=1 to $Setup[0]
		If $Setup[$s] = '|' Then ContinueLoop
		$Split=StringSplit($Setup[$s], '|')
		For $p=2 to $Split[0]-1
			$Test=StringInStr($Setup[$s], '|'&$Split[$p]&'|', 0, 2)
			If $Test = 0 Then ContinueLoop
			If StringInStr($Found, '|'&$Split[$p]&'|') Then ContinueLoop
			$Found &=$Split[$p]&'|'
			_Process_Log('Multiple entries: '&$Split[$p])
			For $a=1 to $Array[0]
				If StringInStr('DWN|CMD|ANN|GRP|IF |FI |ELS', $Split[1]) Then ContinueLoop
				If $Split[3] = 'Init' Then ContinueLoop
				If StringInStr($Array[$a], $Split[$p]) Then _Process_Log('Config\Select.txt:'&$a&':'&$Array[$a])
			Next
		Next
	Next
EndFunc   ;==>Select_Dupes

; ---------------------------------------------------------------------------------------------
; Look for missing / false entries in connections(conflicts, dependencies)
; ---------------------------------------------------------------------------------------------
Func Select_Connection_Exist()
	GUICtrlSetData($g_Label1, 'Select.ini: Connections')
	$Sel = FileRead($g_GConfDir&'\Select.txt')
	$Con = IniReadSection($g_GConfDir&'\Game.ini', 'Connections')
	For $c=1 to $Con[0][0]
		GUICtrlSetData($g_Progress2, $c*100/$Con[0][0])
		$Con[$c][1] = StringTrimLeft($Con[$c][1], 2)
		$Array=StringSplit($Con[$c][1], '')
		Local $Mod='', $Comp=''
		For $a=1 to $Array[0]
			If StringRegExp($Array[$a], '\x3a|\x3e|\x26|\x7c') Then ; :>&|
				Local $Mod = '', $Comp=''
				ContinueLoop
			ElseIf $Array[$a] = '(' Then
				$Comp = ''
				While $Array[$a+1] <> ')'
					$a+=1
					$Comp&=$Array[$a]
				WEnd
				;ConsoleWrite('>'&$Mod & ' ==> ' & $Comp & @CRLF)
				$Num=StringSplit($Comp, '&|')
				For $n=1 to $Num[0]
					If $Num[$n] = '-' Then $Num[$n] = '\d'
					If StringInStr($Num[$n], '?') Then $Num[$n]=StringReplace($Num[$n], '?', '\x3f')
					If StringRegExp($Sel, '(?i)(DWN|STD|MUC|SUB);'&$Mod&';'&$Num[$n]) Then
						;ConsoleWrite('+'&$Mod & ' ' & $Num[$n] & @CRLF)
					Else
						ConsoleWrite('(?i)(DWN|STD|MUC|SUB);'&$Mod&';'&$Num[$n]&@CRLF)
						_Process_Log($Con[$c][0]&'='&$Con[$c][1])
						_Process_Log($Mod & ' ' & $Num[$n])
					EndIf
				Next
				Local $Mod = '', $Comp=''
			Else
				$Mod&=$Array[$a]
			EndIf
		Next
	Next
EndFunc   ;==>Select_Connection_Exist

; ---------------------------------------------------------------------------------------------
; Check if the MUC/SUB-components have the correct headline. Also checks the components decription-strings for MUCs
; ---------------------------------------------------------------------------------------------
Func Select_HasHeader()
	Local $OldMod=''
	$Array=StringSplit(StringStripCR(FileRead($g_GConfDir&'\Select.txt')), @LF)
	For $a=1 to $Array[0]
		$Split=StringSplit($Array[$a], ';')
		If StringRegExp($Split[1], '(?i)\A(ANN|DWN|CMD|IF |GRP|FI |ELS|STD)\z') Then ContinueLoop; skip stuff
		If $Split[1] = 'MUC' Then
			If $Split[3] = 'Init' Then; MUC has to start with Select-line
				$Mod = $Split[2]
				If $OldMod<> $Mod Then; get new translations
					$Tra=IniReadSection($g_GConfDir&'\WeiDU-'&StringLeft(IniRead($g_ModIni, $Mod, 'Tra', ''), 2)&'.ini', $Mod)
					$OldMod=$Mod
				EndIf
				$Test=StringSplit($Array[$a+1], ';'); get current option
				$Selection=StringRegExpReplace(_IniRead($Tra, '@'&$Test[3], ''), '\s?->.*\z', '')
				While 1
					If StringRegExp($Array[$a+1], '\AMUC') = 0 Then ExitLoop; leave loop if MUC ends
					$Test=StringSplit($Array[$a+1], ';')
					If $Test[3] = 'Init' Then ExitLoop; leave when new MUC starts
					If Not StringInStr(_IniRead($Tra, '@'&$Test[3], ''), $Selection&' ->') Then _Process_Log('Missing Init Between MUC: '&$Array[$a+1]); show missing headlines for new option
					If $Test[4] <> $Split[4] Then  _Process_Log('Theme changed within MUC: '&$Array[$a+1]); show theme-change
					$a+=1
				WEnd
				ContinueLoop
			Else
				_Process_Log('Missing Init before MUC: '& $Split[2] & ' ' & $Split[3]); didn't start correctly
			EndIf
		ElseIf $Split[1] = 'SUB' Then
			If StringInStr($Split[3], '?') = 0  Then; SUB start with "main-component"
				While 1
					If StringInStr($Array[$a+1], '?') = 0 Then ExitLoop
					$Test=StringSplit($Array[$a+1], ';')
					If $Test[4] <> $Split[4] Then  _Process_Log('Theme changed within SUB: '&$Array[$a+1]); show theme-change
					$a+=1
				WEnd
				ContinueLoop
			Else
				_Process_Log('Missing main before SUB-components: '& $Split[2] & ' ' & $Split[3]); that's not right
			EndIf
		EndIf
	Next
EndFunc   ;==>Select_HasHeader

; ---------------------------------------------------------------------------------------------
; Check if the component may be one of multiple choices by looking for an -> in the components decription-string
; ---------------------------------------------------------------------------------------------
Func Select_IsMUC()
	Local $OldMod=''
	$Array=StringSplit(StringStripCR(FileRead($g_GConfDir&'\Select.txt')), @LF)
	For $a=1 to $Array[0]
		$Split=StringSplit($Array[$a], ';')
		If StringRegExp($Split[1], '(?i)\A(ANN|DWN|CMD|IF |GRP|FI |ELS)\z') Then ContinueLoop; skip stuff without translations
		If $Split[1] = 'MUC' And $Split[3] = 'Init' Then ContinueLoop
		$Mod = $Split[2]
		If $OldMod<> $Mod Then; get translations for new mod
			$Translation=IniReadSection($g_GConfDir&'\WeiDU-'&StringLeft(IniRead($g_ModIni, $Mod, 'Tra', ''), 2)&'.ini', $Mod)
			$OldMod=$Mod
		EndIf
		If UBound($Split) < 4 Then; skip if badly formated
			_Process_Log('Badly formated: '&$Array[$a])
			ContinueLoop
		EndIf
		$Component = $Split[3]
; don't check for some known "issues"
		If $Mod = 'scs' And $Component = 3001 Then ContinueLoop; other option is tutu
		If $Mod = 'RevisedBattles' And StringRegExp($Component, '10|11|12') Then ContinueLoop; Firkraag compatibility patches
		If $Mod = 'NMR' And $Component = 8 Then ContinueLoop; other option is ascension compatibility
		If $Mod = '1pp_female_dwarves' And $Component = 0 Then ContinueLoop; other options are for other games
		If $Mod = '1pp_thieves_galore' And $Component = 1 Then ContinueLoop; other options are for other games
		If $Mod = 'infinityanimations' And $Component = 9000 Then ContinueLoop; just has that string in its name
		If $Mod = 'iiProjectileR' And $Component = 2002 Then ContinueLoop;; other option is tutu
		$Test = _IniRead($Translation, '@'&$Component, '')
		If $Test = '' Then; empty translation string
			_Process_Log('Config\'&$g_Flags[14]&'\Select.txt:' & $a & ': ' & $Mod &' ==> ' & $Component)
		ElseIf $Split[1] = 'SUB' Then; don't show subs. Sometimes use those "->" tokens
			ContinueLoop
		ElseIf StringInStr($Test, '->') And $Split[1] <> 'MUC' Then; show items with "->" token that aren't listed as MUC
			_Process_Log('Config\'&$g_Flags[14]&'\Select.txt:' & $a & ': ' & $Mod &': ' & $Component&' ==> ' &$Test)
		EndIf
	Next
EndFunc   ;==>Select_IsMUC

; ---------------------------------------------------------------------------------------------
; Check if mods are disabled that have to be downloaded manually
; ---------------------------------------------------------------------------------------------
Func Select_ManualDisabled()
	$Names=IniReadSectionNames($g_ModIni)
	$Array=StringSplit(StringStripCR(FileRead($g_GConfDir&'\Select.txt')), @LF)
	For $n=1 to $Names[0]
		$Test=StringUpper(IniRead($g_ModIni, $Names[$n], 'Down', ''))
		If $Test <> 'MANUAL' Then ContinueLoop
		For $a=1 to $Array[0]
			$Split=StringSplit($Array[$a], ';')
			If StringRegExp($Split[1], '(?i)\A(ANN|CMD|IF |GRP|FI |ELS)\z') Then ContinueLoop
			If $Split[2] <> $Names[$n] Then ContinueLoop
			If StringRegExp($Names[$n], 'aurpatch|BG1PatchSound|BGTMusic|BWPDF|BWTextpack|CtB_FF|'& _
			'CtB-Chores|gavin_bg2_bgt|gavin_kickout_hotfix|Innate_Fix|res_fixer') Then ContinueLoop; don't bring up known stuff that is located in fixpacks or something
			If StringInStr($Split[5], '1') Then
				_Process_Log('Config\'&$g_Flags[14]&'\Select.txt:'&$a&': Unavailable mod is selected: '&$Names[$n])
				ExitLoop
			EndIf
		Next
	Next
EndFunc   ;==>Select_ManualDisabled

; ---------------------------------------------------------------------------------------------
; Look for false preselections in SUB and MUC-lines
; ---------------------------------------------------------------------------------------------
Func Select_SUBs()
	Local $First, $OldFirst, $Num, $Sum, $cSUB, $oVer, $oSUB, $Version[50][8], $Versions[5]=[4, 'R', 'S', 'T', 'E']
	GUICtrlSetData($g_Label1, 'Select.ini: Preselections')
	$Array = StringSplit(StringStripCR(FileRead($g_GConfDir & '\Select.txt')), @LF)
	ReDim $Array[$Array[0]+2]
	$Array[0]+=1
	$Array[$Array[0]]='MUC;GUI;Init;20;0000;'
	For $a = 1 To $Array[0]
		GUICtrlSetData($g_Progress2, $a*100/$Array[0])
		$Split=StringSplit($Array[$a], ';')
		If StringRegExp($Split[1], '(?i)DWN|CMD|ANN|GRP|STD|IF |FI |ELS') Then ContinueLoop
		$Type = $Split[1]; Type
		$Mod = $Split[2]; SetupName
		$Comp = $Split[3]; CompNumber
		$Sel = $Split[5]; Select per default
		If $Type = 'SUB' And Not StringInStr($Comp, '?') Then $First=1
		If $Comp = 'Init' Then $First=1
		If $First Then
			; show old stuff
			For $t=1 to 4
				$Sum=0
				For $n=1 to $Num
					$Sum+=$Version[$n][$t]
					If $Version[$n][7] = 'SUB' And $Version[$n][$t] = 1 Then
						$cSUB=StringRegExpReplace($Version[$n][6], '_.*', '')
						If $cSUB = $oSUB And $t=$oVer Then _Process_Log('Config\'&$g_Flags[14]&'\Select.txt:'&$OldFirst&': SUB: ' & $Version[0][5] &' ('&  $oSUB &'_*) '& $Versions[$t]& ': Multiple SUBs')
						$oSUB = $cSUB
						$oVer=$t
					EndIf
				Next
				If $Sum=1 And $Version[0][7] = 'MUC' And $Version[0][$t] <> 1 Then
					_Process_Log('Config\'&$g_Flags[14]&'\Select.txt:'&$OldFirst&': MUC ' & $Version[0][5] &' ('& $Version[0][6]&') '& $Versions[$t]& ': No Select for component')
				ElseIf $Sum>0 And $Version[0][7] = 'SUB' And $Version[0][$t] = 0 Then
					_Process_Log('Config\'&$g_Flags[14]&'\Select.txt:'&$OldFirst&': SUB ' & $Version[0][5] &' ('& $Version[0][6]&') '& $Versions[$t]& ': No component for SUB')
				ElseIf $Sum = 0 And $Version[0][$t] <> 0 Then
					_Process_Log('Config\'&$g_Flags[14]&'\Select.txt:'&$OldFirst&': '& $Version[0][7] & ' ' & $Version[0][5] &' ('& $Version[0][6]&') '& $Versions[$t]& ': Component without SUBs')
				EndIf
			Next
			$OldFirst = $a
			$First=0
			$Num=-1
		EndIf
		$Num+=1
		$Temp=StringSplit($Sel, '')
		$Version[$Num][0]=$a
		For $t=1 to 4
			$Version[$Num][$t]=$Temp[$t]
		Next
		$Version[$Num][5]=$Mod
		$Version[$Num][6]=$Comp
		$Version[$Num][7]=$Type
	Next
EndFunc   ;==>Select_SUBs
#EndRegion Select

#Region Translation
; ---------------------------------------------------------------------------------------------
; Look for translation-strings missing in the translation-files. Note: _GetTR is case-sensitive
; ---------------------------------------------------------------------------------------------
Func Trans_Missing()
	GUICtrlSetData($g_Label1, 'Translation: Missing expressions')
	$g_TRAIni = 'Config\Translation-GE.ini'
	Local $File = _FileSearch('Includes', '*')
	$File[0]+=1
	ReDim $File[$File[0]+1]
	$File[$File[0]] = 'BiG World Setup.au3'
	$g_UI_Message = IniReadSection($g_TRAIni, 'UI-Runtime')
	$Admin = IniReadSection($g_TRAIni, 'Admin')
	$Install = IniReadSection($g_TRAIni, 'IN-Au3RunFix')
	For $f=1 To $File[0]
		GUICtrlSetData($g_Label2, $File[$f])
		GUICtrlSetData($g_Progress2, $f*100/$File[0])
		If StringRegExp(StringLeft($File[$f], 1), '\d') Then $File[$f] = 'Includes\' & $File[$f]
		$Array = StringSplit(StringStripCR(FileRead($File[$f])), @LF)
		For $a = 1 To $Array[0]
			If StringInStr($Array[$a], 'Section($g_TRAIni') Then;
				$Tra = StringRegExpReplace($Array[$a], "\A.*i,\s\x27|\x27\x29.*", '')
				$Section = StringRegExpReplace(StringRegExpReplace($Array[$a], '\s=\sIniRead.*', ''), '\A.*\x24', '')
				If $Section = 'g_UI_Message' Then
					ContinueLoop
				ElseIf $Section = 'Message' Then
					$Sec = IniReadSection($g_TRAIni, $Tra)
					If @error Then
						_Process_Log($File[$f] & ':' & $a & ':TRA ' & $Tra & ' ' & $Array[$a])
					EndIf
				Else
					ConsoleWrite('>'&$Section & @CRLF)
				EndIf
			ElseIf StringInStr($Array[$a], '_GetTR(') Then
				$eNum = UBound(StringRegExp($Array[$a], '(?i)_GetTR\x28', 3)); get the number of included translations
				If $eNum = 1 And StringInStr($Array[$a], '_GetTRA') Then ContinueLoop; this is a line with another function
				$cNum = 0
				$Tmp = StringSplit($Array[$a], "_GetTR(", 1)
				For $t = 2 To $Tmp[0]
					$Exp = StringRegExpReplace($Tmp[$t], '\x27\x29.*', '')
					If @extended = 0 Then $Exp = StringLeft($Tmp[$t], StringInStr($Tmp[$t], ')')-1)
					If StringInStr($Exp, '$g_UI_Message') Then
						$TraSection='g_UI_Message'
					ElseIf StringInStr($Exp, '$p_Message') And $File[$f] = 'Includes\03_Admin.au3' Then
						$TraSection='Admin'
					ElseIf StringInStr($Exp, '$p_Message') And $File[$f] = 'Includes\09_Install.au3' Then
						$TraSection='Install'
					Else
						$TraSection='Sec'
					EndIf
					$Exp = StringRegExpReplace($Exp, "\A.*'", '')
					$Out = _IniRead(Eval($TraSection), $Exp, '')
					If $Out = '' And StringRegExp($Array[$a], '\A(Func|EndFunc)') = 0 And StringInStr($Exp, '$') = 0 Then; don't report function-lines and expressions that include variables
						_Process_Log($File[$f] & ':' & $a & ': Expression ['&$Exp&'] not found in [' & $Tra & '] >> ' & StringStripWS($Array[$a], 3))
					EndIf
					$cNum += 1
				Next
				If $cNum <> $eNum And StringRegExp($Array[$a], '\A(Func|EndFunc)') = 0 Then _Process_Log($File[$f] & ':' & $a & ': Function-mismatch using [' & $Tra & '] '&$cNum &'|'& $eNum&' >> ' & StringStripWS($Array[$a], 3))
			EndIf
		Next
	Next
EndFunc   ;==>Trans_Missing

; ---------------------------------------------------------------------------------------------
; Look for missing translation-strings by comparing the translations to the german one
; ---------------------------------------------------------------------------------------------
Func Trans_Compare()
	GUICtrlSetData($g_Label1, 'Translation: Compare to German')
	$g_TRAIni = 'Config\Translation-GE.ini'
	Local $TRAs[3] = [1, 'EN']; , 'SP']
	$Sec = IniReadSectionNames($g_TRAIni)
	For $s = 1 To $Sec[0]
		GUICtrlSetData($g_Label2, $Sec[$s])
		GUICtrlSetData($g_Progress2, $s*100/$Sec[0])
		$GArray = IniReadSection($g_TRAIni, $Sec[$s])
		For $t = 1 To $TRAs[0]
			$CArray = IniReadSection('Config\Translation-' & $TRAs[$t] & '.ini', $Sec[$s])
			If @error Then
				_Process_Log('-' & $TRAs[$t] & ' [' & $Sec[$s]&']')
				ContinueLoop
			EndIf
			For $g = 1 To $GArray[0][0]
				$Found=0
				For $c = 1 To $CArray[0][0]
					If $CArray[$c][0] = $GArray[$g][0] Then
						$Found=1
						ExitLoop
					EndIf
				Next
				If $Found = 0 Then _Process_Log('-' & $TRAs[$t] & ' ' & $GArray[$g][0] & ' (' & $Sec[$s]& ')')
			Next
		Next
	Next
EndFunc   ;==>_Trans_Compare
#EndRegion Translation

#Region WeiDU
; ---------------------------------------------------------------------------------------------
; Search for abandoned Weidu-Translation-Entries
; ---------------------------------------------------------------------------------------------
Func Weidu_Abandoned()
	GUICtrlSetData($g_Label1, 'WeiDU: Abandoned strings')
	$MSections = IniReadSectionNames($g_ModIni)
	$Weidu = _FileSearch($g_GConfDir, 'Weidu*.ini')
	For $w = 1 To $Weidu[0]
		GUICtrlSetData($g_Label2, $Weidu[$w])
		GUICtrlSetData($g_Progress2, $w*100/$Weidu[0])
		$Array = StringSplit(StringStripCR(FileRead($g_GConfDir & '\' & $Weidu[$w])), @LF)
		$WSections = IniReadSectionNames($g_GConfDir & '\' & $Weidu[$w])
		For $s = 1 To $WSections[0]
			$Found = 0
			For $m = 1 To $MSections[0]
				If $WSections[$s] = $MSections[$m] Then
					$Found = 1
					ExitLoop
				EndIf
			Next
			If $Found = 0 Then
				For $a = 1 To $Array[0]
					If StringInStr($Array[$a], '[' & $WSections[$s] & ']') Then
						_Process_Log('Config\'&$g_Flags[14]&'\'&$Weidu[$w] & ':' & $a & ':' & $WSections[$s])
						$Found = 1
						ExitLoop
					EndIf
				Next
				If $Found = 0 Then _Process_Log('Fault: ' & $WSections[$s])
			EndIf
		Next
	Next
EndFunc   ;==>Weidu_Abandoned

; ---------------------------------------------------------------------------------------------
; Look for translations that are missing in the weidu-files by using mod.ini
; ---------------------------------------------------------------------------------------------
Func Weidu_Missing()
	Local $OldMod
	GUICtrlSetData($g_Label1, 'WeiDU.ini: Missing')
	$Array = StringSplit(StringStripCR(FileRead($g_GConfDir & '\Select.txt')), @LF)
	For $a = 1 To $Array[0]
		GUICtrlSetData($g_Progress2, $a*100/$Array[0])
		$Split=StringSplit($Array[$a], ';')
		If StringRegExp($Split[1], '(?i)\A(CMD|ANN|GRP|IF |FI |ELS)') Then ContinueLoop
		$Mod = $Split[2]; SetupName
		If $Mod <> $OldMod Then
			$Tra=IniRead($g_ModIni, $Mod, 'Tra', '')
			If $Tra = '' Then
				_Process_Log('Config\'&$g_Flags[14]&'\Select.txt:' & $a & ': Fault: No translation for '&$Mod)
				ContinueLoop
			EndIf
			$Tra=StringRegExp($Tra, '[[:alpha:]]{2}', 3)
			$OldMod = $Mod
		EndIf
		$Comp = $Split[3]; CompNumber
		If $Comp = 'Init' Then ContinueLoop

		For $t=0 to UBound($Tra)-1
			$Weidu=IniRead($g_GConfDir&'\Weidu-'&$Tra[$t]&'.ini', $Mod, '@'&$Comp, '')
			If $Weidu = '' Then _Process_Log('Config\'&$g_Flags[14]&'\Select.txt:' & $a & ': Fault: Missing '& $Tra[$t] &' for ' & $Mod & ' (' & $Comp & ')')
		Next
	Next
EndFunc   ;==>Weidu_Missing

; ---------------------------------------------------------------------------------------------
; Sort the Weidu-XX.ini
; ---------------------------------------------------------------------------------------------
Func Weidu_Sort()
	GUICtrlSetData($g_Label1, 'WeiDU: Sort')
	$Weidu = _FileSearch($g_GConfDir, 'Weidu*.ini')
	For $w = 1 To $Weidu[0]
		GUICtrlSetData($g_Progress2, $w*100/$Weidu[0])
		GUICtrlSetData($g_Label2, $Weidu[$w])
		_SortWeiduIni($g_GConfDir & '\' & $Weidu[$w])
	Next
EndFunc   ;==>Weidu_Sort

; ---------------------------------------------------------------------------------------------
; Look if No-Text entries point to a valid translation
; ---------------------------------------------------------------------------------------------
Func Weidu_NoTXT()
	GUICtrlSetData($g_Label1, 'WeiDU: No Text')
	$Sec = IniReadSectionNames($g_ModIni)
	$Array = StringSplit(StringStripCR(FileRead($g_ModIni)), @LF)
	For $s = 1 To $Sec[0]
		GUICtrlSetData($g_Label2, $Sec[$s])
		GUICtrlSetData($g_Progress2, $s*100/$Sec[0])
		$Tra=IniRead($g_ModIni, $Sec[$s], 'Tra', '')
		$Num = StringRegExp($Tra, '(?i)--:\d{1,}', 3)
		If Not IsArray($Num) Then ContinueLoop
		$Num = StringRegExp($Tra, '(?i)[^--]{2}'&StringTrimLeft($Num[0], 2), 3); return the correct token if NT-dummy was found
		If Not IsArray($Num) Then
			For $a=1 to $Array[0]
				If $Array[$a]='['&$Sec[$s]&']' Then
					For $t=$a to $Array[0]
						If StringLeft($Array[$t], 4) = 'Tra=' Then
							_Process_Log('Config\'&$g_Flags[14]&'\Mod.ini:' & $t & ': Fault: ' & $Sec[$s]&' => '&StringTrimLeft($Array[$t], 4))
							ExitLoop 2
						EndIf
					Next
				EndIf
			Next
		EndIf
	Next
EndFunc   ;==>Weidu_NoTXT
#EndRegion WeiDU

#Region Subfunctions
Func _CheckANSI($p_File)
	GUICtrlSetData($g_Label2, $p_File)
	$Array = StringSplit(StringStripCR(FileRead(@ScriptDir & '\' & $p_File)), @LF)
	For $a = 1 To $Array[0]
		GUICtrlSetData($g_Progress2, $a & '/' & $Array[0])
		$Line = StringSplit($Array[$a], '')
		For $l = 1 To $Line[0]
			If Asc($Line[$l]) > 126 Then _Process_Log($p_File & ': Line ' & $a & ' Char ' & $l & ': ' & $Line[$l] & ' = ' & Asc($Line[$l]))
		Next
	Next
EndFunc   ;==>_CheckANSI

Func _SearchFunc($p_Func, $p_File, $p_Show=1)
	$Found =0
	For $f=1 To $p_File[0]
		$Array = Eval('Array'&$f)
		For $a=1 to $Array[0]
			If StringInStr($Array[$a], $p_Func) Then
				If StringRegExp($Array[$a], '\A(?i);|Func|EndFunc|_PrintDebug') Then ContinueLoop
				$Found+=1
				If $p_Show=1 Then ConsoleWrite($p_File[$f] & ':' & $a & ':'& StringStripWS($Array[$a], 3) & @CRLF)
			EndIf
		Next
	Next
	Return $Found
EndFunc   ;==>_SearchFunc

; ---------------------------------------------------------------------------------------------
; sort the inifiles by chapters. Increases productivity and you can see if you missed files
; ---------------------------------------------------------------------------------------------
Func _SortIni($p_Ini)
	$Order = IniReadSectionNames($g_ModIni)
	_ArraySort($Order, 0, 1)
	For $o=1 to $Order[0]
		IniRenameSection($p_Ini, $Order[$o], 'X'&$Order[$o])
	Next
	For $o=1 to $Order[0]
		IniRenameSection($p_Ini, 'X'&$Order[$o], $Order[$o])
	Next
	$Array=StringSplit(StringStripCR(FileRead($p_Ini)), @LF)
	$Handle = FileOpen($p_Ini, 2)
	For $a=1 to $Array[0]
		If StringRegExp($Array[$a], '\A\x5b') And $Array[$a-1] <> '' Then FileWriteLine($Handle, '')
		If $Array[$a] = '' Then
			$n=$a
			While $n < $Array[0]
				$n+=1
				If $n = $Array[0] Then
					If $Array[0] = '' Then
						ExitLoop 2
					Else
						ExitLoop
					EndIf
				ElseIf $Array[$n] <> '' Then
					$a=$n-1
					ContinueLoop 2
				EndIf
			WEnd
		EndIf
		FileWriteLine($Handle, $Array[$a])
	Next
	FileClose($Handle)
EndFunc

Func _SortRead(ByRef $SortArray, ByRef $SearchArray, $p_String)
	For $s = 1 To $SearchArray[0]
		If StringRegExp($SearchArray[$s], '(?i)\A' & $p_String & '=') Then
			$SortArray &= '|||' & $SearchArray[$s]
			ExitLoop
		EndIf
	Next
EndFunc   ;==>_SortRead

Func _SortWeiduIni($p_File)
	Local $a, $Array, $Found
	$Handle = FileOpen($p_File & '.new', 2)
	$Order = IniReadSectionNames($g_ModIni)
	_ArraySort($Order, 0, 1)
	$Section = IniReadSectionNames($p_File)
	For $o=1 to $Order[0]
		$Found=0
		For $s=1 to $Section[0]
			If $Section[$s] = $Order[$o] Then
				$Found = $s
				ExitLoop
			EndIf
		Next
		If $Found = 0 Then ContinueLoop
		FileWrite($Handle, '[' & $Section[$s] & ']' & @CRLF)
		$Read = IniReadSection($p_File, $Section[$s])
		Local $Length = 2, $Count = 0, $Tra = '', $Current = ''
		For $l = 1 To $Read[0][0]
			$Temp = StringLen($Read[$l][0])
			If $Temp > $Length Then $Length = $Temp
		Next
		For $Len = 1 To $Length
			For $r = 1 To $Read[0][0]
				If StringRegExp($Read[$r][0], '\A\x40' & $Current & '\x3f') Then
					If $Read[$r][1] <> '' Then
						$Count += 1
						FileWrite($Handle, $Read[$r][0] & '=' & $Read[$r][1] & @CRLF)
						If $Count = $Read[0][0] Then ExitLoop 2
						$Read[$r][1] = ''
					EndIf
				ElseIf StringLen($Read[$r][0]) = $Len Then
					If StringInStr($Read[$r][0], '?') Then ContinueLoop
					$Count += 1
					If $Read[$r][1] = '' Then ContinueLoop
					If $Read[$r][0] = 'Tra' Then
						$Tra = $Read[$r][1]
						ContinueLoop
					EndIf
					FileWrite($Handle, $Read[$r][0] & '=' & $Read[$r][1] & @CRLF)
					If $Count = $Read[0][0] Then ExitLoop 2
					$Current = StringTrimLeft($Read[$r][0], 1)
				EndIf
			Next
		Next
		If $Tra = '' Then
			_Process_Log('Fault: Tra is empty for ' & $Section[$s] & ' in ' & $p_File)
			Return 0
		EndIf
		If $Count <> $Read[0][0] Then
			_Process_Log('Fault: Counter differs for ' & $Section[$s] & ' in ' & $p_File & ':' & @CRLF & $Count & @CRLF & $Read[0][0])
			Return 0
		EndIf
		FileWrite($Handle, 'Tra=' & $Tra & @CRLF & @CRLF)
	Next
	FileClose($Handle)
	FileMove($p_File, $g_GConfDir&'\bak\', 1)
	FileMove($p_File & '.new', $p_File)
	Return 1
EndFunc   ;==>_SortWeiduIni
#EndRegion Subfunctions

#Region Stuff from the std. or other udfs
; ---------------------------------------------------------------------------------------------
; Searches for files with a certain pattern
; ---------------------------------------------------------------------------------------------
Func _FileSearch($p_Dir, $p_String)
	Local $Return[1] = [0]
	$search = FileFindFirstFile($p_Dir & '\' & $p_String)
	If $search = -1 Then Return SetError(1, 0, $Return)
	Local $Return[4000]
	While 1
		$file = FileFindNextFile($search)
		If @error Then ExitLoop
		If $file = '.' Or $file = '..' Then ContinueLoop
		$Return[0] += 1
		$Return[$Return[0]] = $file
	WEnd
	FileClose($search)
	ReDim $Return[$Return[0] + 1]
	Return SetError(0, 0, $Return)
EndFunc   ;==>_FileSearch

; ---------------------------------------------------------------------------------------------
; Returns the WeiDU-file or a translation for a component of a mod
; ---------------------------------------------------------------------------------------------
Func _GetTra($p_String, $p_Tra)
	Local $Num
	$Num = StringRegExp($p_String, '(?i)'&$p_Tra&':\d{1,}', 3)
	If Not IsArray($Num) Then $Num = StringRegExp($p_String, '(?i)--:\d{1,}', 3)
	If StringLeft($Num[0], 2) = '--' Then $Num = StringRegExp($p_String, '(?i)[^--]{2}'&StringTrimLeft($Num[0], 2), 3); return the correct token if NT-dummy was found
	$Tra=StringTrimLeft($Num[0], 3); Langnumber
	Return $Tra
EndFunc   ;==>_GetTra


; ---------------------------------------------------------------------------------------------
; Get items from an IniReadSection-array
; ---------------------------------------------------------------------------------------------
Func _IniRead($p_Handle, $p_Type, $p_String); $a=array, $b=key, $c=default
	If Not IsArray($p_Handle) Then
		ConsoleWrite('! Handle not defined for ' & $p_Type & ' ' & $p_String & @CRLF)
		Return SetError(-1, 0, $p_String)
	EndIf
	For $h = 1 To $p_Handle[0][0]
		If $p_Handle[$h][0] = $p_Type Then
			Return SetError($h, 0, $p_Handle[$h][1])
		EndIf
	Next
	Return SetError(0, 0, $p_String)
EndFunc   ;==>_IniRead

; ---------------------------------------------------------------------------------------------
; Read a section that's too big for std-ini-function
; ---------------------------------------------------------------------------------------------
Func _IniReadSection($p_File, $p_Key)
	Local $Read
	$Array=StringSplit(StringStripCR(FileRead($p_File)), @LF)
	Local $Return[$Array[0]+1][2]
	For $a=1 to $Array[0]
		If StringLeft($Array[$a], 1) = '[' Then
			If StringInStr($Array[$a], '['&$p_Key&']') Then
				$Read=1
				ContinueLoop
			Else
				$Read=0
			EndIf
		EndIf
		If $Read = 0 Then ContinueLoop
		If $Array[$a] = '' Then ContinueLoop
		;ConsoleWrite($Array[$a]&@CRLF)
		$Num=StringInStr($Array[$a], '=')
		$Return[0][0]+=1
		$Return[$Return[0][0]][0]=StringLower(StringLeft($Array[$a], $Num-1))
		$Return[$Return[0][0]][1]=StringTrimLeft($Array[$a], $Num)
	Next
	ReDim $Return[$Return[0][0]+1][2]
	_ArraySort($Return, 0, 1)
	Return $Return
EndFunc   ;==>_IniReadSection

Func _Process_Log($p_Text, $p_Write = 1, $p_Length=0); $p_Length will auto-resize the text
	_GUICtrlEdit_AppendText($g_Edit, $p_Text & @CRLF)
	_GUICtrlEdit_Scroll($g_Edit, 1)
	If $p_Write = 1 Then
		ConsoleWrite($p_Text & @CRLF)
		FileWrite($g_LogFile, $p_Text & @CRLF)
	EndIf
EndFunc   ;==>_Process_SetScrollLog
#EndRegion Stuff from the std. or other udfs