Func _ReCreateMyself()
    If @Compiled Then
        Run(@ScriptFullPath)
    Else
        $AutoIt3Path = RegRead("HKEY_LOCAL_MACHINE\SOFTWARE\AutoIt v3\AutoIt", "InstallDir");installDir for production
        $ToRun1 = '"' & $AutoIt3Path & '\AutoIt3.exe "' & ' "' & @ScriptFullPath & '"'
        Run($ToRun1)
    EndIf
    Exit
EndFunc