/*

.: Original script
. 
. $Date: 2018/02/25 16:58:24 $
. Version 1.0.3
. 
. Author:
. Jesper Rosenlund Nielsen, Jarl Petter Kvalsvik
. http://zwifthacks.com
. 
. Script:
. zwift-media-button
. 
. Functionality:
. Maps keys on media-button to Zwift-input, effectively making it a Zwift game-controller.
. 
. Usage:
. Script must be run as Administrator to work. If not it will try to launch itself in Administrator mode.
. 
. (An alternative solution would be to add the option 'Run with UI access' to context menus (via the AutoHotkey Setup) and use that option to launch the script)
. 
. 
. License:
. CC NY-NC
. https://creativecommons.org/licenses/by-nc/4.0/
 
*/

#Warn  ; Enable warnings to assist with detecting common errors.
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.

; Directives
; ==========
#SingleInstance Force
#NoEnv

; Configuration
; ==============

KeyDelayFactor := 3 ; increase if some keypresses do not transmit properly
ZwiftWindow := "ahk_class GLFW30" ; The ZwiftApp window
ButtonMode := 0  ; will be 1 when volume bar is visible and 2 when actions menu is visible
; The percentage by which to raise or lower the volume each time:
VolumeStep = 3
; How long to display the volume level bar graphs:
VolumeDisplayTime = 2500
VolumeProgressbarOptions = B ZH50 ZX0 ZY0 W250 X100 Y100 CBRed CWBlack
GlobalDebug := 0
CurrentView := 1

; MAIN ROUTINE
; =============== 

; Script must be run as Administrator to work
ElevateScript()

; Initialisation
SetKeyDelay, % KeyDelayFactor*10, % KeyDelayFactor*10

Media_Play_Pause::
  ; Use power-up
  ; to avoid accidentally activate powerup, this key handles *only* power up
  ZwiftSendKey("{Space}")
Return

; Media_next is unbound to keep the "skip sound track" functionality
; Media_Next::
; -- Do something...
; Return

Media_Prev::
  ;  Toogle view between 1 (normal/default) and 6 (looking back)
  ToogleView()
Return

Volume_Up::
  ChangeBike(1)
Return

Volume_Down::
  ChangeBike(-1)
Return

; Disabled the shift + Vol up/down 
; +Volume_Up::
;   VolumeUp()
; Return
;
; +Volume_Down::
;   VolumeDown()
; Return

+^Q::
  ExitApp
Return

; ---------------
; FUNCTIONS

SetButtonModeActionMenu() {
  global ButtonMode
  ButtonMode := 2
  SetTimer, ActionsMenuOff, 4000
}

ActionsMenuOff() {
  global ButtonMode
  SetTimer, ActionsMenuOff, Off
  ButtonMode := 0
}  

SwitchMiniMap() {
  global ZwiftWindow
  GetRelativePosition(1691/1920 , 140/1017, XX, YY)
  WinActivate, %ZwiftWindow%
  CoordMode, Mouse, Client
  MouseClick,, %xx%, %yy%
}

SendFanRideOn() {
  global ZwiftWindow
  
  WinActivate, ahk_class GLFW30

  GetRelativePosition(1655/1920 , 348/1147, XX1, YY1)
  GetRelativePosition(1655/1920 , 1111/1147, XX2, YY2)
  ; search for bluecolor "me"
  CoordMode, Pixel, Client
  PixelSearch, x, y, %XX1%, %YY1%, %XX2%, %YY2%, 0x1192CC,  , Fast RGB 

  if ( ERRORLEVEL = 0) {
    y := y - 5
    WinActivate, %ZwiftWindow%
    CoordMode, Mouse, Client
    MouseClick,, %x%, %y%
    Sleep, 1750
    ClickRideOn()
    ZwiftSendKey("{F3}")
    Sleep, 250
    GetRelativePosition(215/1920 , 970/1017, backx, backy)
    MouseClick,, %backx%, %backy%
    MouseClick,, %backx%, %yy%
  }
}

; Send Zwift keystroke(s)
ZwiftSendKey(message) {
  global ZwiftWindow
  ; Only send the key if Zwift is open
  if WinExist(ZwiftWindow) {
    ControlSend, ahk_parent, % message, % ZwiftWindow
  }
}

; Restart this script in Administrator mode if not started as Administrator
ElevateScript() {
  full_command_line := DllCall("GetCommandLine", "str")

  if not (A_IsAdmin or RegExMatch(full_command_line, " /restart(?!\S)"))
  {
    try
    {
      if A_IsCompiled
        Run *RunAs "%A_ScriptFullPath%" /restart
      else
        Run *RunAs "%A_AhkPath%" /restart "%A_ScriptFullPath%"
    }
    ExitApp
  }
}

ClickRideOn()
{
  global GlobalDebug

  WinActivate, ahk_class GLFW30

  GetRelativePosition(1555/1920 , 348/1147, XX1, YY1)
  GetRelativePosition(1555/1920 , 1111/1147, XX2, YY2)

  XX1 := Round(XX1)
  XX2 := Round(XX2)
  YY1 := Round(YY1)
  YY2 := Round(YY2)

  if ( globaldebug <> 0 ) {
    WinActivate, ahk_class GLFW30
    CoordMode, Mouse, Client
    MouseMove, %XX1%, %YY1%
    MouseMove, %XX2%, %YY2%
    MouseMove, %XX1%, %YY1%
    Sleep 2000
  }

  WinActivate, ahk_class GLFW30
  CoordMode, Pixel, Client
  ; search for various shades of orange just left of nameplates
  PixelSearch, x, y, %XX1%, %YY1%, %XX2%, %YY2%, 0xF36C3D,  , Fast RGB 


  if ( ERRORLEVEL = 0 ) {
    WinActivate, ahk_class GLFW30
    CoordMode, Mouse, Client
    y := y + 3

    if ( globaldebug <> 0 ) {
      CoordMode, Mouse, Client
      MouseMove, %x%, %y%
    } else {
      MouseClick,, %x%, %y%
    }
  }
}

GetRelativePosition(a, b, ByRef xx, ByRef yy)
{
  ; This special version of GetRelativePosition handles GUI elements
  ; which do not scale with the screen width but stays in place
  ; anchored to the right side of the window in an ultra wide window (e.g. rider list)
  ; Notice that riders list scales with the window when NOT in a wide window
  
  WinGet, hwnd, ID, ahk_class GLFW30
  ; Retrieve the width (w) and height (h) of the client area.
  GetClientSize(hwnd, W, H)

  if ( a > (W/2) and (W/H) > (1920/1147)) {
    ; wide screen
    XX := W - ((H*1920/1147) - round(a*(H*1920/1147)))
    YY := round(b*H)
  } else {
    ;; MsgBox Width = %w% Height = %h%
    XX := round(a*W)
    YY := round(b*H)
  }

}

GetClientSize(hwnd, ByRef w, ByRef h) {
  VarSetCapacity(rc, 16)
  DllCall("GetClientRect", "uint", hwnd, "uint", &rc)
  w := NumGet(rc, 8, "int")
  h := NumGet(rc, 12, "int")
}

ToogleView()
{
  ; Changing view between 1 (normal/default) and 6 (look back)
  global CurrentView
  if (CurrentView = 1) {
    ZwiftSendKey("6")
    CurrentView = 6
  } else {
    ZwiftSendKey("1")
    CurrentView = 1
  }
}

ChangeBike(n)
{
  SleepDelay := 10 ; Wait after each keystroke (in ms)

  ZwiftSendKey("{Esc}") ; Exit pairing screen
  Sleep, SleepDelay
  ZwiftSendKey("t") ; Go to the garage
  Sleep, SleepDelay
  ZwiftSendKey("{Enter}") ; Enter bike choice

  ; Wait additional time for bikes to load
  Sleep, 500
  
  ; Scroll to bike
  MoveKey := "{Up}"
  if (n < 0)
  {
    MoveKey := "{Down}"
    n := n * -1
  }
  Loop, % n
  {
    ZwiftSendKey(MoveKey)
    Sleep, SleepDelay
  }

  ZwiftSendKey("{Enter}") ; Equip bike
  Sleep, SleepDelay

  ZwiftSendKey("{Esc}") ; Exit bike choice
  Sleep, SleepDelay

  ; Wait additional time
  Sleep, 500

  ZwiftSendKey("{Esc}") ; Exit user customization
  Sleep, SleepDelay

  ; Wait additional time
  Sleep, 500

  ZwiftSendKey("{Esc}") ; Exit garage
  Sleep, SleepDelay
}

;------------------
; Handling volume

VolumeUp() {
  global VolumeStep
  SoundSet, +%VolumeStep%
  ShowVolumeBar()
}

VolumeDown() {
    global VolumeStep
    SoundSet, -%VolumeStep%
  ShowVolumeBar()
}

ShowVolumeBar() {
  global VolumeProgressbarOptions
  global VolumeDisplayTime
  IfWinNotExist, vol_Master
  {
    Progress, %VolumeProgressbarOptions%, , , vol_Master
  }
  SoundGet, vol_Master, Master
  Progress, %vol_Master%
  SetTimer, VolumeBarOff, %VolumeDisplayTime%
}

VolumeBarOff() {
  global ButtonMode
  SetTimer, VolumeBarOff, Off
  Progress, Off
  ButtonMode := 0
}