#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
; #Warn  ; Enable warnings to assist with detecting common errors.
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.

#SingleInstance, Force
CoordMode, Mouse, Screen


class Configuration {
    static Width := "30"
    static Height := "20"
    static FontColor := "ffffff"
    static FontSize := "12"
    static DefaultBackground := "555555"
    static DefaultText := "##"
    static Transparency := 255
    static LayoutMap := { 1033: { Name: "EN", Color: "00CC00" }}
    static LayoutScanPeriodMs := 200
    static EnableAlwaysOn := true
    static AlwaysOnCursorType := "IBeam"

    static NameSpecificConfigFileName := SubStr( A_ScriptName, 1, -3 ) . "ini"

    FindLayoutParams(code) {
        local layoutParams := this.LayoutMap[code]
        local defaultParams := { Name: this.DefaultText, Color: this.DefaultBackground }
        return ((layoutParams) ? (layoutParams) : (defaultParams))
    }

    HandleParseError(line, context="") {
        OutputDebug, Bad parameter line read from config file: %line% (context: %context%)
    }

    /**
        Example config:

        [Indicator]
        width = 29
        height = 20
        fontColor = ffffff
        fontSize = 12
        transparency = 180
        layoutScanPeriodMs = 200

        [Languages]
        EN = 1033;00bb00
        HE = 1037;5555ff
    */
    ReadConfigFile() {
        local ConfigFileContents, FirstChar, SeparatorPosition, SectionName, ParamKey, ParamValue, ParamValueValid

        if (FileExist(this.NameSpecificConfigFileName)) {
            FileRead, ConfigFileContents, % this.NameSpecificConfigFileName
        } else {
            MsgBox, Conguration INI file was not found, will use default configuration
            return
        }

        if (ErrorLevel != 0 or !ConfigFileContents ) {
            MsgBox, Failed to read INI file: %A_LastError%, will use default configuration
            return
        }

        Loop, Parse, ConfigFileContents, `n`r, %A_Space%%A_Tab%
        {
            if (!Trim(A_LoopField)) {
                continue
            }

            FirstChar := SubStr(A_LoopField, 1, 1)
            if (FirstChar = "[") {
                SectionName := SubStr(A_LoopField, 2, -1)
                continue
            }
            if (FirstChar = ";") {
                continue
            }

            SeparatorPosition := InStr(A_LoopField, "=")
            if (!SeparatorPosition) {
                OutputDebug, Bad parameter line read from config file: %A_LoopField%
                continue
            }

            ParamKey := Trim(SubStr(A_LoopField, 1, SeparatorPosition - 1))
            ParamValue := Trim(SubStr(A_LoopField, SeparatorPosition + 1))

            switch SectionName {
                case "Indicator":
                    ParamValueValid := false
                    switch ParamKey {
                        case "Width":
                            ParamValueValid := RegExMatch(ParamValue, "\d+")
                            if (ParamValueValid) {
                                this.Width := ParamValue
                            }
                        case "Height":
                            ParamValueValid := RegExMatch(ParamValue, "\d+")
                            if (ParamValueValid) {
                                this.Height := ParamValue
                            }
                        case "FontColor":
                            ParamValueValid := RegExMatch(ParamValue, "i)[\da-f]{6}")
                            if (ParamValueValid) {
                                this.FontColor := ParamValue
                            }
                        case "FontSize":
                            ParamValueValid := RegExMatch(ParamValue, "\d+")
                            if (ParamValueValid) {
                                this.FontSize := ParamValue
                            }
                        case "Transparency":
                            ParamValueValid := RegExMatch(ParamValue, "\d+")
                            if (ParamValueValid and 0 < ParamValue and ParamValue <= 255) {
                                this.Transparency := ParamValue
                            }
                        case "LayoutScanPeriodMs":
                            ParamValueValid := RegExMatch(ParamValue, "\d+")
                            if (ParamValueValid) {
                                this.LayoutScanPeriodMs := ParamValue
                            }
                    }
                    if (!ParamValueValid) {
                        this.HandleParseError(A_LoopField, SectionName)
                    }
                case "Languages":
                    if (RegExMatch(ParamKey, "i)[a-z]{2,5}") and RegExMatch(ParamValue, "i)(\d{4,5})\s*;\s*([\da-f]{6})", ParamValueGroup)) {
                        this.LayoutMap[ParamValueGroup1] := { Name: ParamKey, Color: ParamValueGroup2 }
                    }
                    else {
                        this.HandleParseError(A_LoopField, SectionName)
                    }
                default:
                    this.HandleParseError(A_LoopField)
            }

        }
        ConfigFileContents := ""
    }
}

GuiLangName := ""

class IndicatorGui {
    static Width := 30
    static Height := 20
    static GuiHwnd := ""
    static TransparencyLevel := 255

    Init(width, height, fontSize, fontColor, backgroundColor, transparencyLevel, initialText="EN") {
        this.Width := width
        this.Height := height
        this.TransparencyLevel := transparencyLevel

        Gui, +AlwaysOnTop +Disabled -SysMenu -Caption +Owner +HwndIndicatorGuiHwnd
        this.GuiHwnd := IndicatorGuiHwnd
        Gui, Margin, 2, 1
        Gui, Font, s%fontSize% c%fontColor% Bold
        Gui, Add, Text, vGuiLangName, % initialText
        Gui, Color, backgroundColor
    }

    Show(xPos, yPos, color, text, doHide=true) {
        GuiControl,, GuiLangName, %text%
        Gui, Color, c%color%
        Gui, Show, % "w" . this.Width . " h" . this.Height . " x" . xPos . " y" . yPos . " NoActivate"
        WinSet, Transparent, % this.TransparencyLevel, % "ahk_id " . this.GuiHwnd

        if (doHide) {
            HideMethodRef := ObjBindMethod(this, "Hide")
            SetTimer, % HideMethodRef, -1000
        }
    }

    Hide() {
        Gui, Cancel
    }
}

class Util {
    GetActiveLayout() {
        active_hwnd := WinExist("A")
        threadID := dllCall("GetWindowThreadProcessId", "uint", active_hwnd, "uint", 0)
        code := dllCall("GetKeyboardLayout", "uint", threadID, "uint") & 0xFFFF
        return code
    }

    GetCurrentCursor() {
        return A_cursor
    }

    GetCoordsAtMousePosition() {
        MouseGetPos, xPos, yPos
        xPos := xPos + 15
        yPos := yPos + 15
        return { x: xPos, y: yPos }
    }

    GetCoordsAtCaretPosition() {
        xPos := A_CaretX + 5
        yPos := A_CaretY + 12
        return { x: xPos, y: yPos }
    }
}


Configuration.ReadConfigFile()

ActiveLayout := Util.GetActiveLayout()
PreviousLayout := ActiveLayout
LayoutParams := Configuration.FindLayoutParams(ActiveLayout)

IndicatorGui.Init(Configuration.Width
    , Configuration.Height
    , Configuration.FontSize
    , Configuration.FontColor
    , Configuration.DefaultBackground
    , Configuration.Transparency
    , LayoutParams.Name)
IndicatorCoords := Util.GetCoordsAtMousePosition()
IndicatorGui.Show(IndicatorCoords.x, IndicatorCoords.y, LayoutParams.Color, LayoutParams.Name)

Cursor := Util.GetCurrentCursor()
PrevCursor := Cursor

loop {
    sleep, Configuration.LayoutScanPeriodMs

    AutoHide := false
    ActiveLayout := Util.GetActiveLayout()

    IndicatorCoords := ""
    ControlGetFocus, FocusedControl, A

    if (!ErrorLevel) {
        IndicatorCoords := Util.GetCoordsAtCaretPosition()
    }

    if (!IndicatorCoords.x) {
        IndicatorCoords := Util.GetCoordsAtMousePosition()
        Cursor := Util.GetCurrentCursor()

        if (Cursor != Configuration.AlwaysOnCursorType) {
            if (PrevCursor = Configuration.AlwaysOnCursorType) {
                IndicatorGui.Hide()
            }
            if (ActiveLayout = PreviousLayout) {
                continue
            }
            AutoHide := true
        }
    }

    LayoutParams := Configuration.FindLayoutParams(ActiveLayout)
    IndicatorGui.Show(IndicatorCoords.x, IndicatorCoords.y, LayoutParams.Color, LayoutParams.Name, AutoHide)

    PreviousLayout := ActiveLayout
    PrevCursor := Cursor
}

+esc::exitapp ;press Shift-Escape to close script
