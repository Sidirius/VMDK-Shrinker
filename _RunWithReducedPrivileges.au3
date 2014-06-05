#include-once
; ===============================================================================================================================
; <_RunWithReducedPrivileges.au3>
;
; Function to run a program with reduced privileges.
;	Useful when running in a higher privilege mode, but need to start a program with reduced privileges.
;	- A common problem this fixes is drag-and-drop not working, and misc functions (sendmessage, etc) not working.
;
; Functions:
;	_RunWithReducedPrivileges()		; runs a process with reduced privileges if currently running in a higher privilege mode
;
; INTERNAL Functions:
;	_RWRPCleanup()		; Helper function for the above
;
; Reference:
;	See 'Creating a process with Medium Integration Level from the process with High Integration Level in Vista'
;		@ http://www.codeproject.com/KB/vista-security/createprocessexplorerleve.aspx
;	  See Elmue's comment 'Here the cleaned and bugfixed code'
;	Also see: 'High elevation can be bad for your application: How to start a non-elevated process at the end of the installation'
;		@ http://www.codeproject.com/KB/vista-security/RunNonElevated.aspx
;	  (Elmue has the same code here too in his response to FaxedHead's comment ('Another alternative to this method'))
;	Another alternative using COM methods:
;	  'Getting the shell to run an application for you - Part 2:How | BrandonLive'
;		@ http://brandonlive.com/2008/04/27/getting-the-shell-to-run-an-application-for-you-part-2-how/
;
; Author: Ascend4nt, based on code by Elmue's fixed version of Alexey Gavrilov's code
; ===============================================================================================================================


; ===================================================================================================================
; Func _RWRPCleanup($hProcess,$hToken,$hDupToken,$iErr=0,$iExt=0)
;
; INTERNAL: Helper function for _RunWithReducedPrivileges()
;
; Author: Ascend4nt
; ===================================================================================================================

Func _RWRPCleanup($hProcess,$hToken,$hDupToken,$iErr=0,$iExt=0)
	Local $aHandles[3]=[$hToken,$hDupToken,$hProcess]	; order is important
	For $i=0 To 2
		If $aHandles[$i]<>0 Then DllCall("kernel32.dll","bool","CloseHandle","handle",$aHandles[$i])
	Next
	Return SetExtended($iExt,$iErr)
EndFunc


; ===================================================================================================================
; Func _RunWithReducedPrivileges($sPath,$sCmd='',$sFolder='',$iShowFlag=@SW_SHOWNORMAL,$bWait=False)
;
; Function to run a program with reduced privileges.
;	Useful when running in a higher privilege mode, but need to start a program with reduced privileges.
;	- A common problem this fixes is drag-and-drop not working, and misc functions (sendmessage, etc) not working.
;
; $sPath = Path to executable
; $sCmd = Command-line (optional)
; $sFolder = Folder to start in (optional)
; $iShowFlag = how the program should appear on startup. Default is @SW_SHOWNORMAL.
;	All the regular @SW_SHOW* macros should work here
; $bWait = If True, waits for the process to finish before returning with an exit code
;	If False, it returns without waiting for the process to finish, with the process ID #
;
; Returns:
;	Success: If $bWait=True, the exit code of the Process. If $bWait=False, then the Process ID # of the process
;	Failure: 0, with @error set:
;		@error = 2 = DLLCall error. @extended contains the DLLCall error code (see AutoIt Help)
;		@error = 3 = API returned failure. Call 'GetLastError' API function to get more info.
;
; Author: Ascend4nt, based on code by Elmue's fixed version of Alexey Gavrilov's code
; ===================================================================================================================

Func _RunWithReducedPrivileges($sPath,$sCmd='',$sFolder='',$iShowFlag=@SW_SHOWNORMAL,$bWait=False)
	Local $aRet,$iErr,$iRet=1,$hProcess,$hToken,$hDupToken,$stStartupInfo,$stProcInfo
	Local $sCmdType="wstr",$sFolderType="wstr"

;~ 	Run normally if not in an elevated state, or if pre-Vista O/S
	If Not IsAdmin() Or StringRegExp(@OSVersion,"_(XP|200(0|3))") Then	; XP, XPe, 2000, or 2003?
		If $bWait Then Return RunWait($sPath&' '&$sCmd,$sFolder)
		Return Run($sPath&' '&$sCmd,$sFolder)
	EndIf

;~ 	Check Parameters and adjust DLLCall types accordingly
	If Not IsString($sCmd) Or $sCmd='' Then
		$sCmdType="ptr"
		$sCmd=0
	EndIf
	If Not IsString($sFolder) Or $sFolder='' Then
		$sFolderType="ptr"
		$sFolder=0
	EndIf
#cs
	; STARTUPINFOW struct: cb,lpReserved,lpDesktop,lpTitle,dwX,dwY,dwXSize,dwYSize,dwXCountChars,dwYCountChars,dwFillAttribute,
	;	dwFlags,wShowWindow,cbReserved2,lpReserved2,hStdInput,hStdOutput,hStdError
	;	NOTE: This is for process creation info. Also, not sure if the Std I/O can be redirected..?
#ce
	$stStartupInfo=DllStructCreate("dword;ptr[3];dword[7];dword;word;word;ptr;handle[3]")
	DllStructSetData($stStartupInfo,1,DllStructGetSize($stStartupInfo))
	DllStructSetData($stStartupInfo,4,1)	; STARTF_USESHOWWINDOW
	DllStructSetData($stStartupInfo,5,$iShowFlag)

	; PROCESS_INFORMATION struct: hProcess, hThread, dwProcessId, dwThreadId
	;	This is for *receiving* info
	$stProcInfo=DllStructCreate("handle;handle;dword;dword")

;~ 	Open a handle to the Process
	; Explorer runs under a lower privilege, so it is the basis for our security info.
	;	Open the process with PROCESS_QUERY_INFORMATION (0x0400) access
	$aRet=DllCall("kernel32.dll","handle","OpenProcess","dword",0x0400,"bool",False,"dword",ProcessExists("explorer.exe"))
	If @error Then Return SetError(2,@error,0)
	If Not $aRet[0] Then Return SetError(3,0,0)
	$hProcess=$aRet[0]

;~ 	Open a handle to the Process's token (for duplication)
	; TOKEN_DUPLICATE = 0x0002
	$aRet=DllCall("advapi32.dll","bool","OpenProcessToken","handle",$hProcess,"dword",2,"handle*",0)
	If @error Then Return SetError(_RWRPCleanup($hProcess,0,0,2,@error),@extended,0)
	If $aRet[0]=0 Then Return SetError(_RWRPCleanup($hProcess,0,0,3),@extended,0)
	$hToken=$aRet[3]

;~ 	Duplicate the token handle
	; TOKEN_ALL_ACCESS = 0xF01FF, SecurityImpersonation = 2, TokenPrimary = 1,
	$aRet=DllCall("advapi32.dll","bool","DuplicateTokenEx","handle",$hToken,"dword",0xF01FF,"ptr",0,"int",2,"int",1,"handle*",0)
	If @error Then Return SetError(_RWRPCleanup($hProcess,$hToken,0,2,@error),@extended,0)
	If Not $aRet[0] Then Return SetError(_RWRPCleanup($hProcess,$hToken,0,3),@extended,0)
	$hDupToken=$aRet[6]

;~ 	Create the process using 'CreateProcessWithTokenW' (Vista+ O/S function)
	$aRet=DllCall("advapi32.dll","bool","CreateProcessWithTokenW","handle",$hDupToken,"dword",0,"wstr",$sPath,$sCmdType,$sCmd, _
		"dword",0,"ptr",0,$sFolderType,$sFolder,"ptr",DllStructGetPtr($stStartupInfo),"ptr",DllStructGetPtr($stProcInfo))
	$iErr=@error
	_RWRPCleanup($hProcess,$hToken,$hDupToken,2,@error)
	If $iErr Then Return SetError(2,$iErr,0)
	If Not $aRet[0] Then Return SetError(3,0,0)

;~ 	MsgBox(0,"Info","Process info data: Process handle:"&DllStructGetData($stProcInfo,1)&", Thread handle:"&DllStructGetData($stProcInfo,2)& _
;~ 		", Process ID:"&DllStructGetData($stProcInfo,3)&", Thread ID:"&DllStructGetData($stProcInfo,4)&@CRLF)

	$iRet=DllStructGetData($stProcInfo,3)	; Process ID

;~ 	If called in 'RunWait' style, wait for the process to close
	If $bWait Then
		ProcessWaitClose($iRet)
		$iRet=@extended					; Exit code
	EndIf

;~ 	Close Thread and then Process handles (order here is important):
	_RWRPCleanup(0,DllStructGetData($stProcInfo,2),DllStructGetData($stProcInfo,1),0)

	Return $iRet
EndFunc
