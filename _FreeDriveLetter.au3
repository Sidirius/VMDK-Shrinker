Func _FreeDriveLetter($iMode = 0)
    If $iMode < 0 Or $iMode > 2 Or Not IsNumber($iMode) Then $iMode = 0
    Local $sFreeDriveLetter = ''
    For $i = 67 To 90
        If Not DriveGetType(Chr($i) & ':') Then $sFreeDriveLetter &= Chr($i) & ':|'
    Next
    If $iMode Then
        Return StringSplit(StringTrimRight($sFreeDriveLetter, 1), '|', $iMode)
    Else
        Return StringTrimRight($sFreeDriveLetter, 1)
    EndIf
EndFunc