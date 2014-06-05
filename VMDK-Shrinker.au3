#RequireAdmin
#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_Icon=C:\Program Files (x86)\VMware\VMware Workstation\ico\vd.ico
#AutoIt3Wrapper_Outfile=bin\VMDK-Shrinker.exe
#AutoIt3Wrapper_Compression=4
#AutoIt3Wrapper_Res_Comment=VMDK-Shrinker
#AutoIt3Wrapper_Res_Description=Program to Shrink or Mount VMware *.vmdk file
#AutoIt3Wrapper_Res_Fileversion=0.0.0.3
#AutoIt3Wrapper_Res_Fileversion_AutoIncrement=y
#AutoIt3Wrapper_Res_LegalCopyright=Sven Hartmann
#AutoIt3Wrapper_Res_Language=1031
#AutoIt3Wrapper_Res_requestedExecutionLevel=requireAdministrator
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****
#include <ButtonConstants.au3>
#include <EditConstants.au3>
#include <GUIConstantsEx.au3>
#include <WindowsConstants.au3>
#include <_RunWithReducedPrivileges.au3>
#include <_FreeDriveLetter.au3>
#include <_ReCreateMyself.au3>
If $CmdLine[0] > 0 Then
	$DEBUG = $CmdLine[1]
ElseIf Not @Compiled Then
	$DEBUG = "-debug"
Else
	$DEBUG = "0"
EndIf
Dim $vmdkFile
Dim $LWB
$sFreeDriveLetter = _FreeDriveLetter(0) ; Parameter = 0
$sFirstDrive = StringLeft($sFreeDriveLetter, 2)
$sLastDrive = StringRight($sFreeDriveLetter, 2)

#Region ### START Koda GUI section ###
$MAIN = GUICreate("VMDK-Shrinker", 600, 80, -1, -1)
$tbDatei = GUICtrlCreateInput("", 10, 12, 500, 21)
$btnOpen = GUICtrlCreateButton("Öffnen", 515, 10, 75, 25)
$btnStart = GUICtrlCreateButton("Start", 515, 45, 75, 25)
$btnMount = GUICtrlCreateButton("Mount", 515, 45, 75, 25)
$btnUnMount = GUICtrlCreateButton("Unmount", 515, 45, 75, 25)
$comDriveLetter = GUICtrlCreateCombo("Drive Letter", 10, 45, 75, 25)
$btnDebug = GUICtrlCreateButton("Debug", 400, 45, 110, 25)
$cboxMountOnly = GUICtrlCreateCheckbox("Mount only", 95, 45)
GUICtrlSetData($comDriveLetter, $sFreeDriveLetter, $sLastDrive)
GUICtrlSetState($btnMount, $GUI_HIDE)
GUICtrlSetState($btnUnMount, $GUI_HIDE)
If $DEBUG == "-debug" Then
	GUICtrlSetState($btnDebug, $GUI_SHOW)
Else
	GUICtrlSetState($btnDebug, $GUI_HIDE)
EndIf
GUISetState(@SW_SHOW)
#EndRegion ### END Koda GUI section ###

While 1
	$nMsg = GUIGetMsg()
	Switch $nMsg
		Case $GUI_EVENT_CLOSE
			Exit
		Case $btnOpen
			ButtonOpen()
		Case $btnStart
			ButtonStart()
		Case $btnMount
			ButtonMount()
		Case $btnUnMount
			ButtonUnMount()
		Case $btnDebug
			ButtonDebug()
		Case $cboxMountOnly
			CheckboxMountOnly()
	EndSwitch
WEnd

Func ButtonOpen()
	$vmdkFile = '"' & FileOpenDialog("VMDK Datei öffnen", "", "VMDK Dateien (*.vmdk)") & '"'
	GUICtrlSetData($tbDatei, $vmdkFile)
EndFunc   ;==>ButtonOpen

Func ButtonStart()
	Initialize()
	Start()
EndFunc   ;==>ButtonStart

Func ButtonMount()
	Initialize()
	RepairVMDK()
	MountVMDKExplorer()
EndFunc   ;==>ButtonMount

Func ButtonUnMount()
	Initialize()
	UnMountVMDKExplorer()
EndFunc   ;==>ButtonUnMount

Func CheckboxMountOnly()
	If GUICtrlRead($cboxMountOnly) = 1 Then
		GUICtrlSetState($btnStart, $GUI_HIDE)
		GUICtrlSetState($btnUnMount, $GUI_HIDE)
		GUICtrlSetState($btnMount, $GUI_SHOW)
	Else
		GUICtrlSetState($btnStart, $GUI_SHOW)
		GUICtrlSetState($btnUnMount, $GUI_HIDE)
		GUICtrlSetState($btnMount, $GUI_HIDE)
	EndIf
EndFunc   ;==>CheckboxMountOnly

Func ButtonDebug()
	RunWait(@ComSpec & " /c " & "%appdata%\HTK\vmToolkit\bin\vmware-mount.exe Z: /d /f")
	RunWait(@ComSpec & " /c " & "%appdata%\HTK\vmToolkit\bin\vmware-mount.exe Y: /d /f")
	RunWait(@ComSpec & " /c " & "%appdata%\HTK\vmToolkit\bin\vmware-mount.exe X: /d /f")
	RunWait(@ComSpec & " /c " & "%appdata%\HTK\vmToolkit\bin\vmware-mount.exe W: /d /f")
	RunWait(@ComSpec & " /c " & "%appdata%\HTK\vmToolkit\bin\vmware-mount.exe V: /d /f")
	RunWait(@ComSpec & " /c " & "%appdata%\HTK\vmToolkit\bin\vmware-mount.exe U: /d /f")
	RunWait(@ComSpec & " /c " & "%appdata%\HTK\vmToolkit\bin\vmware-mount.exe T: /d /f")
	RunWait(@ComSpec & " /c " & "%appdata%\HTK\vmToolkit\bin\vmware-mount.exe S: /d /f")
	RunWait(@ComSpec & " /c " & "%appdata%\HTK\vmToolkit\bin\vmware-mount.exe R: /d /f")
	RunWait(@ComSpec & " /c " & "%appdata%\HTK\vmToolkit\bin\vmware-mount.exe Q: /d /f")
	$var1 = $GUI_HIDE
	MsgBox(0, "", @AppDataDir)
EndFunc   ;==>ButtonDebug

Func Start()
	RepairVMDK()
	MountVMDK()
	SdeleteOnVMDK()
	UnMountVMDK()
	DefragVMDK()
	ShrinkVMDK()
EndFunc   ;==>Start

Func Initialize()
	$vmdkFile = GUICtrlRead($tbDatei)
	$LWB = GUICtrlRead($comDriveLetter)
	Validate()
EndFunc   ;==>Initialize

Func Validate()
	If Not StringRegExp($vmdkFile, '(?i).vmdk') Then
		MsgBox(0 + 16, "Fehler", "Keine oder ungültige VMDK gewählt.")
		_ReCreateMyself()
	EndIf
EndFunc   ;==>Validate

Func RepairVMDK()
	RunWait(@ComSpec & " /c " & "%appdata%\HTK\vmToolkit\bin\vmware-vdiskmanager.exe -R " & $vmdkFile)
EndFunc   ;==>RepairVMDK

Func MountVMDK()
	RunWait(@ComSpec & " /c " & "%appdata%\HTK\vmToolkit\bin\vmware-mount.exe " & $LWB & " " & $vmdkFile & " /m:w")
EndFunc   ;==>MountVMDK

Func MountVMDKExplorer()
	Initialize()
	_RunWithReducedPrivileges(@ComSpec, " /c %appdata%\HTK\vmToolkit\bin\vmware-mount.exe " & $LWB & " " & $vmdkFile & " /m:w")
	GUICtrlSetState($btnStart, $GUI_HIDE)
	GUICtrlSetState($btnUnMount, $GUI_SHOW)
	GUICtrlSetState($btnMount, $GUI_HIDE)
	GUICtrlSetState($comDriveLetter, $GUI_HIDE)
	GUICtrlSetState($cboxMountOnly, $GUI_HIDE)
EndFunc   ;==>MountVMDKExplorer

Func SdeleteOnVMDK()
	RunWait(@ComSpec & " /c " & "%appdata%\HTK\vmToolkit\sdelete\sdelete.exe -z " & $LWB)
EndFunc   ;==>SdeleteOnVMDK

Func UnMountVMDK()
	RunWait(@ComSpec & " /c " & "%appdata%\HTK\vmToolkit\bin\vmware-mount.exe " & $LWB & " /d /f")
EndFunc   ;==>UnMountVMDK

Func UnMountVMDKExplorer()
	RunWait(@ComSpec & " /c " & "%appdata%\HTK\vmToolkit\bin\vmware-mount.exe " & $LWB & " /d /f")
	GUICtrlSetState($btnStart, $GUI_HIDE)
	GUICtrlSetState($btnUnMount, $GUI_HIDE)
	GUICtrlSetState($btnMount, $GUI_SHOW)
	GUICtrlSetState($comDriveLetter, $GUI_SHOW)
	GUICtrlSetState($cboxMountOnly, $GUI_SHOW)
EndFunc   ;==>UnMountVMDKExplorer

Func DefragVMDK()
	RunWait(@ComSpec & " /c " & "%appdata%\HTK\vmToolkit\bin\vmware-vdiskmanager.exe -d " & $vmdkFile)
EndFunc   ;==>DefragVMDK

Func ShrinkVMDK()
	RunWait(@ComSpec & " /c " & "%appdata%\HTK\vmToolkit\bin\vmware-vdiskmanager.exe -k " & $vmdkFile)
EndFunc   ;==>ShrinkVMDK

Func EOF()
	Exit
EndFunc   ;==>EOF
