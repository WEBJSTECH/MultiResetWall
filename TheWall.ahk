; A Multi-Instance macro for Minecraft ResetInstance
; A publicly avalable version of "The Wall" made by jojoe77777
; Settings Change by Dowsky, main body by Specnr
; By PodX12
;
#NoEnv
#SingleInstance Force

SetKeyDelay, 0
SetWinDelay, 1
SetTitleMatchMode, 2

; Variables to configure
global rows := 3 ; Number of row on the wall scene
global cols := 3 ; Number of columns on the wall scene
global wideResets := True
global fullscreen := False
global disableTTS := False
global countAttempts := True
global beforeFreezeDelay := 600 ; increase if doesnt join world
global fullScreenDelay := 270 ; increse if fullscreening issues
global obsDelay := 100 ; increase if not changing scenes in obs
global restartDelay := 200 ; increase if saying missing instanceNumber in .minecraft (and you ran setup)
global maxLoops := 50 ; increase if macro regularly locks up
global scriptBootDelay := 6000 ; increase if instance freezes before world gen
global hotSwapDelay := 20
global projectorTitle := "Fullscreen Projector"
global suspendEnabled := False
global sceneSwitchCtrlEnabled := False ; Enabled this will change OBS scene switch to be CTRL + Numpad{X}


;This section is from dowsky macro that will adjust settings when you leave and enter a world
global settingsToggle := True ; True = enabled, False = disabled
global settingsDelay := 10
global vanillaSettingsDelay := 10 ; Increase this if not changing any settings or doing weird stuff.
global renderDistanceDefaults := [0, 0, 3, 8, 12, 17, 22, 27, 31, 36, 41, 45, 50, 55, 60, 64, 69, 74, 79, 83, 88, 93, 98, 102, 107, 112, 116, 121, 126, 131, 134, 139, 143]

global enableRDChange := True
global renderDistance := renderDistanceDefaults[16]
global renderDistanceBG := renderDistanceDefaults[5]

global FPSLimit := 160 ; Unlimited 160 --- To configure this go to settings press SHIFT + P to switch to vanilla settings screen, tab to the FPS menu and the hold Left until 0 and count the inputs right to your desired FPS

; Don't configure these
global instWidth := Floor(A_ScreenWidth / cols)
global instHeight := Floor(A_ScreenHeight / rows)
global McDirectories := []
global instances := 0
global rawPIDs := []
global PIDs := []
global resetScriptTime := []
global resetIdx := []
global timeSinceMoved := A_TickCount
global currentInstance := 0
global version := "1.0.0"
global newHeight := Floor(A_ScreenHeight / 2.5)
global verticalPositionHeight := Floor(( A_ScreenHeight - (A_ScreenHeight/2.5) ) / 2 - 50)


if(!suspendEnabled)
    beforeFreezeDelay := 0

UnsuspendAll()
sleep, %restartDelay%
GetAllPIDs()
SetTitles()

for i, mcdir in McDirectories {
    idle := mcdir . "idle.tmp"
    if (!FileExist(idle))
        FileAppend,,%idle%
    if (wideResets) {
        pid := PIDs[i]
        WinRestore, ahk_pid %pid%
        WinMove, ahk_pid %pid%, , 0, 0, %A_ScreenWidth%, %A_ScreenHeight%
        WinMove, ahk_pid %pid%, , 0, %verticalPositionHeight%, %A_ScreenWidth%, %newHeight%
    }
    WinSet, AlwaysOnTop, Off, ahk_pid %pid%
}

if (!disableTTS)
    ComObjCreate("SAPI.SpVoice").Speak("Ready")

#Persistent
SetTimer, CheckScripts, 20
Menu, Tray, NoStandard 
Menu, Tray, Add, Wall Macro %version%, ShowVersion
Menu, Tray, Add, Unsuspend All, UnsuspendAll

while(A_Index <= instances){
    Menu, Instances, Add, Kill Instance %A_Index%, KillInstance
}

Menu, Tray, Add, Kill Instances, :Instances 

Menu, Tray, Add
Menu, Tray, Add, Reload, Reload
Menu, Tray, Add, Exit, Exit

Menu, Tray, Default, Wall Macro %version% 
return

KillInstance(){
    pid := PIDs[A_ThisMenuItemPos]

    if(pid > 0){
        Process, Close, %pid%
    }
}

ShowVersion() {
    resp := HttpGet("https://pastebin.com/raw/VtH2hC0p")

    if(resp != version)
    {
        MsgBox, A NEWER VERSION IS AVAILABLE (%resp%), YOU ARE USING %version%
    }else{
        MsgBox, You are using version %version% and are up to date.
    }
}

Exit() {
    UnsuspendAll()
    ExitApp
}

Reload(){
    UnsuspendAll()
    Reload
}

HttpGet(URL) {
    static req := ComObjCreate("Msxml2.XMLHTTP")
    req.open("GET", URL, false)
    req.send()
    return req.responseText
}

CheckScripts:
    Critical
    toRemove := []
    for i, rIdx in resetIdx {
        idleCheck := McDirectories[rIdx] . "idle.tmp"
        if (A_TickCount - resetScriptTime[i] > scriptBootDelay && FileExist(idleCheck)) {
            Sleep, 50
            SuspendInstance(PIDs[rIdx])
            toRemove.Push(resetScriptTime[i])
        }
    }
    for i, x in toRemove {
        idx := resetScriptTime.Length()
        while (idx) {
            resetTime := resetScriptTime[idx]
            if (x == resetTime) {
                resetScriptTime.RemoveAt(idx)
                resetIdx.RemoveAt(idx)
            }
            idx--
        }
    }
return

MousePosToInstNumber() {
    MouseGetPos, mX, mY
    return (Floor(mY / instHeight) * cols) + Floor(mX / instWidth) + 1
}

RunHide(Command)
{
    dhw := A_DetectHiddenWindows
    DetectHiddenWindows, On
    Run, %ComSpec%,, Hide, cPid
    WinWait, ahk_pid %cPid%
    DetectHiddenWindows, %dhw%
    DllCall("AttachConsole", "uint", cPid)

    Shell := ComObjCreate("WScript.Shell")
    Exec := Shell.Exec(Command)
    Result := Exec.StdOut.ReadAll()

    DllCall("FreeConsole")
    Process, Close, %cPid%
Return Result
}

GetMcDir(pid)
{
    command := Format("powershell.exe $x = Get-WmiObject Win32_Process -Filter \""ProcessId = {1}\""; $x.CommandLine", pid)
    rawOut := RunHide(command)
    if (InStr(rawOut, "--gameDir")) {
        strStart := RegExMatch(rawOut, "P)--gameDir (?:""(.+?)""|([^\s]+))", strLen, 1)
        return SubStr(rawOut, strStart+10, strLen-10) . "\"
    } else {
        strStart := RegExMatch(rawOut, "P)(?:-Djava\.library\.path=(.+?) )|(?:\""-Djava\.library.path=(.+?)\"")", strLen, 1)
        if (SubStr(rawOut, strStart+20, 1) == "=") {
            strLen -= 1
            strStart += 1
        }
        return StrReplace(SubStr(rawOut, strStart+20, strLen-28) . ".minecraft\", "/", "\")
    }
}

GetInstanceTotal() {
    idx := 1
    global rawPIDs
    WinGet, all, list
    Loop, %all%
    {
        WinGet, pid, PID, % "ahk_id " all%A_Index%
        WinGetTitle, title, ahk_pid %pid%
        if (InStr(title, "Minecraft*")) {
            rawPIDs[idx] := pid
            idx += 1
        }
    }
return rawPIDs.MaxIndex()
}

GetInstanceNumberFromMcDir(mcdir) {
    numFile := mcdir . "instanceNumber.txt"
    num := -1
    if (mcdir == "" || mcdir == ".minecraft") ; Misread something
        Reload
    if (!FileExist(numFile))
        MsgBox, Missing instanceNumber.txt in %mcdir%
    else
        FileRead, num, %numFile%
return num
}

GetAllPIDs()
{
    global McDirectories
    global PIDs
    global instances := GetInstanceTotal()
    ; Generate mcdir and order PIDs
    Loop, %instances% {
        mcdir := GetMcDir(rawPIDs[A_Index])
        if (num := GetInstanceNumberFromMcDir(mcdir)) == -1
            ExitApp
        PIDS[num] := rawPIDs[A_Index]
        McDirectories[num] := mcdir
    }
}

FreeMemory(pid)
{
    h:=DllCall("OpenProcess", "UInt", 0x001F0FFF, "Int", 0, "Int", pid)
    DllCall("SetProcessWorkingSetSize", "UInt", h, "Int", -1, "Int", -1)
    DllCall("CloseHandle", "Int", h)
}

UnsuspendAll() {
    WinGet, all, list
    Loop, %all%
    {
        WinGet, pid, PID, % "ahk_id " all%A_Index%
        WinGetTitle, title, ahk_pid %pid%
        if (InStr(title, "Minecraft*"))
            ResumeInstance(pid)
    }
}

SuspendInstance(pid) {
    if(suspendEnabled){
        hProcess := DllCall("OpenProcess", "UInt", 0x1F0FFF, "Int", 0, "Int", pid)
        If (hProcess) {
            DllCall("ntdll.dll\NtSuspendProcess", "Int", hProcess)
            DllCall("CloseHandle", "Int", hProcess)
        }
        FreeMemory(pid)
    }
}

ResumeInstance(pid) {
    if(suspendEnabled){
        hProcess := DllCall("OpenProcess", "UInt", 0x1F0FFF, "Int", 0, "Int", pid)
        if (hProcess) {
            DllCall("ntdll.dll\NtResumeProcess", "Int", hProcess)
            DllCall("CloseHandle", "Int", hProcess)
        }
    }
}

SwitchInstance(idx)
{
    currentInstance := idx

    if (idx <= instances) {
        pid := PIDs[idx]
        ResumeInstance(pid)
        WinMinimize, %projectorTitle% 
        WinSet, AlwaysOnTop, On, ahk_pid %pid%
        WinSet, AlwaysOnTop, Off, ahk_pid %pid%
        if(sceneSwitchCtrlEnabled)
            Send {Ctrl down}
        Send {Numpad%idx% down}
        Sleep, %obsDelay%
        Send {Numpad%idx% up}
        if(sceneSwitchCtrlEnabled)
            Send {Ctrl up}
        if (wideResets)
            WinMaximize, ahk_pid %pid%
        if (fullscreen) {
            ControlSend, ahk_parent, {Blind}{F11}, ahk_pid %pid%
            sleep, %fullScreenDelay%
        }
        send {LButton} ; Make sure the window is activated

        if(settingsToggle)
            RaiseSettings()

        ;Process, priority, %pid%, AboveNormal
    }
}

GetActiveInstanceNum() {
    WinGet, pid, PID, A
    WinGetTitle, title, ahk_pid %pid%
    if (InStr(title, " - ")) {
        for i, tmppid in PIDs {
            if (tmppid == pid)
                return i
        }
    }
return -1
}

ExitWorld()
{
    currentInstance := 0
    if(settingsToggle)
        LowerSettings()

    if (fullscreen) {
        send {F11}
        sleep, %fullScreenDelay%
    }
    if (idx := GetActiveInstanceNum()) > 0
    {
        pid := PIDs[idx]
        if (wideResets) {
            WinRestore, ahk_pid %pid%
            WinMove, ahk_pid %pid%, ,0, %verticalPositionHeight%, %A_ScreenWidth%, %newHeight%
        }
        WinSet, AlwaysOnTop, Off, ahk_pid %pid%
        ControlSend, ahk_parent, {Blind}{Esc}, ahk_pid %pid%
        ;Process, priority, %pid%, Normal 
        ToWall()
        ResetInstance(idx)
    }
}

ResetInstance(idx) {
    if(currentInstance == idx){
        return
    }
    idleFile := McDirectories[idx] . "idle.tmp"
    if (idx <= instances && FileExist(idleFile)) {
        pid := PIDs[idx]
        ResumeInstance(pid)
        ControlSend, ahk_parent, {Blind}{Esc 2}, ahk_pid %pid%
        ; Reset
        logFile := McDirectories[idx] . "logs\latest.log"
        If (FileExist(idleFile))
            FileDelete, %idleFile%
        Run, reset.ahk %pid% %logFile% %maxLoops% %beforeFreezeDelay% %idleFile%
        Critical, On
        resetScriptTime.Push(A_TickCount)
        resetIdx.Push(idx)
        Critical, Off
        ; Count Attempts
        if (countAttempts)
        {
            FileRead, WorldNumber, ATTEMPTS.txt
            if (ErrorLevel)
                WorldNumber = 0
            else
                FileDelete, ATTEMPTS.txt

            WorldNumber += 1
            FileAppend, %WorldNumber%, ATTEMPTS.txt
        }
    }
}

SetTitles() {
    for i, pid in PIDs {
        WinSetTitle, ahk_pid %pid%, , Minecraft* - Instance %i%
    }
}

ToWall() {
    WinActivate, %projectorTitle%
    send {F15 down}
    sleep, %obsDelay%
    send {F15 up}
}

; Focus hovered instance and background reset all other instances
FocusReset(focusInstance) {
    SwitchInstance(focusInstance)
    loop, %instances% {
        if (A_Index != focusInstance) {
            ResetInstance(A_Index)
        }
    }
}

; Reset all instances
ResetAll() {
    loop, %instances% {
        ResetInstance(A_Index)
    }
}

LowerSettings(){ 
    SetKeyDelay, 0
    Send, {Esc}{Tab 6}{Enter}
    Send, {Tab 6}{Enter}
    Sleep, %vanillaSettingsDelay%
    Send, +P
    Sleep, %vanillaSettingsDelay%
    Send, {Tab 4}{left 160}{Right %renderDistanceBG%}{Tab 2}{left 160}
    Sleep %settingsDelay%
    Send {Esc 2} 
}

RaiseSettings(){ 
    SetKeyDelay, 0
    Send, {Esc 2}{Tab 6}
    Send, {Enter}{Tab 6}{Enter}
    Sleep, %vanillaSettingsDelay%
    Send, +P
    Sleep, %vanillaSettingsDelay%
    Send, {Tab 4}
    if(enableRDChange)
        Send, {left 160}{Right %renderDistance%}
    Send, {Tab 2}{left 160}{Right %FPSlimit%}
    Sleep %settingsDelay%
    Send {Esc}{Esc} 
    Sleep, 5
    Send {F3 Down}{Esc}{F3 Up}
}

PauseInstance(idk){ 
    pid := PIDs[idx]
    ControlSend, ahk_parent, {Blind}{Esc}, ahk_pid %pid%
}

; *F16::
;     ResetInstance(1)
; return
; *F17::
;     ResetInstance(2)
; return
; *F18::
;     ResetInstance(3)
; return
; *F19::
;     ResetInstance(4)
; return
; *F20::
;     ResetInstance(5)
; return
; *F21::
;     ResetInstance(6)
; return
; *F22::
;     ResetInstance(7)
; return
; *F23::
;     ResetInstance(8)
; return
; *F24::
;     ResetInstance(9)
; return

; ; Switch to instance keys (Shift + 1-9)
; *^F16::
;     ExitWorld()
;     Sleep, %hotSwapDelay%
;     SwitchInstance(1)
; return
; *^F17::
;     ExitWorld()
;     Sleep, %hotSwapDelay%
;     SwitchInstance(2)
; return
; *^F18::
;     ExitWorld()
;     Sleep, %hotSwapDelay%
;     SwitchInstance(3)
; return
; *^F19::
;     ExitWorld()
;     Sleep, %hotSwapDelay%
;     SwitchInstance(4)
; return
; *^F20::
;     ExitWorld()
;     Sleep, %hotSwapDelay%
;     SwitchInstance(5)
; return
; *^F21::
;     ExitWorld()
;     Sleep, %hotSwapDelay%
;     SwitchInstance(6)
; return
; *^F22::
;     ExitWorld()
;     Sleep, %hotSwapDelay%
;     SwitchInstance(7)
; return
; *^F23::
;     ExitWorld()
;     Sleep, %hotSwapDelay%
;     SwitchInstance(8)
; return
; *^F24::
;     ExitWorld()
;     Sleep, %hotSwapDelay%
;     SwitchInstance(9)
; return

#IfWinActive, Minecraft
    {
        *RAlt:: 
            ExitWorld() ; Reset
        return
    }

    #If WinActive(projectorTitle)
    {
        *R:: 
            ResetInstance(MousePosToInstNumber())

        return

        *F::
            SwitchInstance(MousePosToInstNumber())

        return

        *G::
            FocusReset(MousePosToInstNumber())
        return

        *T::
            ResetAll()
        return
    }

