#Requires AutoHotkey 2.0+

#include "lib\ahk\CreateImageButton.ahk"
BSTYLE_ROUND_LARGE := [
                        [0xff101080,,0xFF00FF00, 8, 0xff101070,  4], 
                        [0xff2020d0,,0xFF00FF00, 8, 0xff101070,  4], 
                        [0xff101040,,0xFF00FF00, 8, 0xff101070,  4], 
                        [0xff303030,,0xFF888888, 8, 0xff101070,  4], 
                        [0xff181890,,0xFF10FF10, 8, 0xff101070, 16],
                        [0xff101080,,0xFF00FF00, 8, 0xff101070,  4]
                      ]

class GuiBase {
    
	columnWidth00 := 225
    columnWidth01 := 370
    columnWidth02 := 120
    columnWidthAll := this.columnWidth00 + this.columnWidth01 + this.columnWidth02
    rowHeight := 19

    static mainGui := Gui("+OwnDialogs", PROGRAM_TITLE " v. " VERSION_NUMBER)
    static statusControl := 0
    static children := []

    finalColumnCtls := []
    groupBoxes := []
    ctls_pushRight := []
    ctls_thisGroupbox := []
    colorHook := HookCtlColor()

	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    static register(obj) {
        GuiBase.children.Push(obj)
    }

	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    getName() {
        return "GuiBase"
    }

	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    start() {
        GDIPlus()
		GuiBase.mainGui.SetFont( "c00FF00 s10", "Courier New")
		GuiBase.mainGui.BackColor := "000000"
        GuiBase.mainGui.Color := "900000"
        CreateImageButton("SetDefGuiColor", 0x000000)
    }

	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	exitGui(*) {
		ExitApp
	}

	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	reloadApp(*) {
		Reload
	}

   	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    static status(text := "") {
        if (GuiBase.statusControl) {
            GuiBase.statusControl.Text := text
        }
    }

	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    guiAdd(v1, v2 := "", v3 := "") {
        ctl := GuiBase.mainGui.Add(v1, v2, v3)
        try {
            if (v1 = "Button")
                CreateImageButton(ctl, 0, BSTYLE_ROUND_LARGE*)
        } catch {
        }
        if (v1 = "Edit" || v1 = "DropDownList") {
            this.colorHook.hook(ctl.hwnd, 0x00ff22, 0x300000)
            ctl.Opt("-E0x200")
        }
        if (this.groupBoxes.Length)
            this.groupBoxes[this.groupBoxes.Length].ctls.Push(ctl)
        this.ctls_thisGroupbox.Push(ctl)
        this.ctls_pushRight.Push(ctl)
        return ctl
    }

	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    updateImageButtonText(ctl, txt) {
        if ctl.Text != txt {
            ctl.Text := txt
            CreateImageButton(ctl, 0, BSTYLE_ROUND_LARGE*)
        }
    }

	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    RemoveExStyle(hwnd, style) {
        GWL_EXSTYLE := -20
        cstyle := DllCall("User32.dll\GetWindowLongPtr", "ptr", hwnd, "int", GWL_EXSTYLE, "ptr")
        cstyle &= !style
        ret := DllCall("User32.dll\SetWindowLongPtr", "ptr", hwnd, "int", GWL_EXSTYLE, "ptr", cstyle, "ptr")
        return ret
    }

	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    finalizeFinalColumn() {
		maxX := 0
		for c in this.finalColumnCtls {
			x := 0, y := 0, w := 0, h := 0
			c.GetPos(&x, &y, &w, &h)
			if (x + w> maxX) {
				maxX := x + w
			}
		}
		for c in this.finalColumnCtls {
			x := 0, y := 0, w := 0, h := 0
			c.GetPos(&x, &y, &w, &h)
			c.Move(maxX - w, y, w, h)
		}
        this.finalColumnCtls := []
    }

    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    addExplainer(description, title) {
        descriptionBtn := this.guiAdd("Button", 
            "x+10 ys h" this.rowHeight, "?")
        descriptionBtn.OnEvent("Click", DescriptionBox)
        DescriptionBox(*) {
            GuiBase.mainGui.Opt("+OwnDialogs")
            MsgBox(description, title)
        }
        this.finalColumnCtls.Push(descriptionBtn)
    }

    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	addDropDown(title, optionListDisplay, optionListValue, targetVariableName, description, OnChange:="", showValues:=0, widths:="") {
        if !optionListValue
            optionListValue := optionListDisplay
        av := []
        i := 1
        while (i <= optionListValue.Length) {
            if showValues
                av.Push(optionListDisplay[i] . " (" . optionListValue[i] . ")")
            else
                av.Push(optionListDisplay[i])
            i++
        }
        if !widths
            widths := [this.columnWidth00, this.columnWidth01]
		this.guiAdd("Text", "section xs w" widths[1] " h" this.rowHeight, title)
		guiCtrl := this.guiAdd("DropDownList", "-0x00800000 -E0x200 ys hp w" widths[2] " r10 v" targetVariableName, av)
        guiCtrl.optionListValue := optionListValue
        i := 1
        while (i <= optionListValue.Length) {
            if %targetVariableName% = optionListValue[i] {
                guiCtrl.Choose(i)
            }
            i++
        }
        if (description)
		    this.addExplainer(description, title)
		guiCtrl.OnEvent("Change", onSelectionChange)
		if (OnChange) {
			guiCtrl.OnEvent("Change", OnChange)
		}
        return guiCtrl
        onSelectionChange(obj, *) {
            SetGlobal(obj.Name, obj.optionListValue[obj.Value])
            SaveSettings()
        }
	}

    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	addFileSelection(title, targetVariableName, description, OnChange:="", isShowChangeButton:=true) {
        guiCtrl := 0
        if (title) {
            this.guiAdd("Text", "section xs w" this.columnWidth00 " h" this.rowHeight, title)
            guiCtrl := this.guiAdd("Edit", "-E0x200 ys hp w" 
                . this.columnWidth01 
                . " v" . targetVariableName, %targetVariableName%)
        } else {
            guiCtrl := this.guiAdd("Edit", "-E0x200 section xs hp w"
                . this.columnWidth00 + this.columnWidth01 + GuiBase.mainGui.MarginX  
                . " v" . targetVariableName, %targetVariableName%)
        }
        guiCtrl._enable := enable
        binSelectBtn := 0
		if (isShowChangeButton) {
			binSelectBtn := this.guiAdd("Button", "ys hp", "...")
			binSelectBtn.OnEvent("Click", eventFileSelectCb)
		}
        guiCtrl.OnEvent("Change", eventFileChange)
		this.addExplainer(description, title)
        return guiCtrl
		eventFileSelectCb(*) {
			selectedFile := FileSelect("*" %targetVariableName%, guiCtrl.Text, "Please choose: " title)
			if (selectedFile) {
				guiCtrl.Text := selectedFile
				SetGlobal(targetVariableName, selectedFile)
                SaveSettings()
				if (OnChange) {
					OnChange(selectedFile)
				}
			}
		}
        eventFileChange(*) {
            selectedFile := guiCtrl.Value
            SetGlobal(targetVariableName, selectedFile)
            SaveSettings()
            if (OnChange) {
                OnChange(selectedFile)
            }
        }
        enable(ctrlObj, b) {
            ControlSetEnabled(b, guiCtrl)
            if (binSelectBtn) {
                ControlSetEnabled(b, binSelectBtn)
            }
        }
	}

    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    startGroupBox(title) {
        w := this.columnWidthAll
        x := 0
        if this.groupBoxes.Length {
            parent := this.groupBoxes[this.groupBoxes.Length]
            parent.ctrl.GetPos(&x, &y, &w, &h)
            w -= 30
            x := 15
        }
        ctrl := this.guiAdd("GroupBox", "section xs+" . x . " w" . w . " h" this.rowHeight, title)
        this.groupBoxes.Push({ctrl: ctrl, ctls: []})
        this.ctls_thisGroupbox := []
        return ctrl
    }

    endGroupBox() {
        this.guiAdd("text", "section xs w0")
        box := this.groupBoxes[this.groupBoxes.Length]
        bottom := 0
        for c in box.ctls  {
            c.GetPos(&x, &y, &w, &h)
            c.Move(x+10, , , )
            bottom := y + h
        }
        box.ctrl.GetPos(&x, &y, &w, &h)
        box.ctrl.Move(, , , bottom - y)
        this.groupBoxes.Pop()
    }

    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	addEditBox(title, targetVariableName, description, defaultValue:="", OnChangeCallback:="", widths:="") {
        if !widths
            widths := [this.columnWidth00, this.columnWidth01]
        if (title)
		    this.guiAdd("Text", "section xs w" widths[1] " h" this.rowHeight, title)
		guiCtrl := this.guiAdd("Edit", "-E0x200 ys hp w" widths[2] " v" targetVariableName, %targetVariableName%)
		guiCtrl.OnEvent("Change", SetCtrlNameGlobalToCtrlValue)
		if (OnChangeCallback)
			guiCtrl.OnEvent("Change", OnChangeCallback)
        if (description)
		    this.addExplainer(description, title)
        return guiCtrl
	}

    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    addCheckbox(title, targetVariableName, description, OnChangeCallback:="") {
		guiCtrl := this.guiAdd("Checkbox", 
            "section xs 0x20 w" this.columnWidth00 + 23 " h" this.rowHeight " Checked" %targetVariableName% " v" targetVariableName, 
            title)
        guiCtrl.OnEvent("Click", SetCtrlNameGlobalToCtrlValue)
		if (OnChangeCallback)
            guiCtrl.OnEvent("Click", OnChangeCallback)
		this.addExplainer(description, title)
        return guiCtrl
	}

    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    refreshUIFromGlobals() {
        for ctrl in GuiBase.mainGui {
            if (ctrl.Name) {
                if IsSet(%ctrl.Name%) {
                    if ctrl.Type = "CheckBox"
                        ControlSetChecked(%ctrl.Name% ? 1 : 0, ctrl)
                    if ctrl.Type = "DDL" && ctrl.HasOwnProp("optionListValue") {
                        idx := 1
                        for v in ctrl.optionListValue {
                            if %ctrl.Name% = v {
                                ctrl.Choose(idx)
                                break
                            }
                            idx++
                        }
                    } else {
                        ctrl.Value := %ctrl.Name%
                    }
                } 
            }
        }
        for c in GuiBase.children {
            c.refreshUI()
        }
    }

    ;;;;;;; align controls created between calling these two functions to the right
    pushRightMark() {
        this.ctls_pushRight := []
    }
    pushRightFinish(withinCurrentGroupbox := true, stretchFirstControlBack := false) {
        container := withinCurrentGroupbox ? this.ctls_thisGroupbox : GuiBase.mainGui
        ; get the rightmost edge of all previous controls
        max_x2 := 0
        for ctl in container {
            ctl.GetPos(&x, &y, &w, &h)
            right := x + w
            max_x2 := max_x2 > right ? max_x2 : right
        }
        ; get our last control's position and figure out the delta along the x axis
        this.ctls_pushRight[this.ctls_pushRight.length].GetPos(&x, &y, &w, &h)
        deltax := max_x2 - w - x
        ; stretch first control left if needed
        if (stretchFirstControlBack) {
            this.ctls_pushRight[1].GetPos(&x, &y, &w, &h)
            this.ctls_pushRight[1].Move(x-deltax,, deltax + w)
        }
        ; move everything right
        for ctl in this.ctls_pushRight {
            ctl.GetPos(&x, &y, &w, &h)
            ctl.Move(x+deltax)
        }
    }

    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    getCurrentTab(tabctl) {
        static TCM_GETCURSEL := 0x130B
        return SendMessage(TCM_GETCURSEL, 0, 0, tabctl)
    }

    setCurrentTab(tabctl, idx) {
        static TCM_SETCURFOCUS  := 0x1330
        static TCM_SETCURSEL    := 0x130C
        SendMessage(TCM_SETCURFOCUS, idx, 0, tabctl)
        Sleep(0)
        SendMessage(TCM_SETCURSEL, idx, 0, tabctl)
        Sleep(0)
        return 
    }

}

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
SetCtrlNameGlobalToCtrlValue(ctrlObj, *) {
    globalName := ctrlObj.Name
    newValue := ctrlObj.Value
    if (VALUE_VALIDATORS.Has(globalName) && !VALUE_VALIDATORS[globalName](newValue))
        return
    SetGlobal(globalName, newValue)
    saveSettings()
}

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
GetCommandOutput(cmd) {
    path_os := EnvGet("PATH")
    path_cmd := substr(cmd, 1, instr(cmd, "\",, -1))
    while strlen(path_cmd) && substr(path_cmd, 1, 1) = '"'
        path_cmd := substr(path_cmd, 2)
    EnvSet("PATH", path_os . ";" . path_cmd)
    DllCall("QueryPerformanceCounter", "int64*", &ctr := 0)
    t := A_Temp . "\" . PROGRAM_TITLE . "-" . ctr . ".tmp"
    o := RunWaitFast(A_ComSpec . ' /c "' . cmd . ' > "' . t . '""',,t)
    EnvSet("PATH", path_os)
    if FileExist(t) {
        FileDelete(t)
    }
    return o
}

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; runwait can be iexplicably slow sometimes, waiting around for longer
; than needed, so i'm trying this as an alternative
RunWaitFast(cmd, wd := "", chkfile := "") {
    try {
        ; fire up the process
        Run(cmd, wd, "Hide", &pid)
        if (pid) {
            ; loop while the process exists
            while ProcessExist(pid) {
                ; if it's expected to create an output file
                if (chkfile) {
                    ; and that file exists
                    if FileExist(chkfile) {
                        ; and we can open it for writing
                        try {
                            if f := FileOpen(chkfile, "rw") {
                                ; then assume we're done
                                o := f.Read()
                                f.Close()
                                return o
                            }
                        } catch {
                            ; nothing to do here
                        }
                    }
                }
                Sleep(20)
            }
            ; if no pid but file, maybe it just all happened very fast
            if chkfile {
                try {
                    if f := FileOpen(chkfile, "r") {
                        o := f.Read()
                        f.Close()
                        return o
                    }
                } catch {
                }
            }
        }
    } catch {
    }
    return false
}

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
#DllLoad "Gdiplus.dll"
GDIPlus() {
   static GdipObject := 0
   If !IsObject(GdipObject) {
      GdipToken  := 0
      GdipStartupInfo := Buffer(24, 0)
      NumPut("UInt", 1, GdipStartupInfo)
      DllCall("Gdiplus.dll\GdiplusStartup", "ptr*", &GdipToken, "ptr", GdipStartupInfo, "ptr", 0, "UInt")
      GdipObject := {__Delete: UseGdipShutDown}
   }
   UseGdipShutDown(*) {
      DllCall("Gdiplus.dll\GdiplusShutdown", "ptr", GdipToken)
   }
}

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
class HookCtlColor {
    ctls := Map()
    msghandler := this.OnMessage.Bind(this)
    WM_CTLCOLOR := Map("Edit", 0x0133, "ListBox", 0x134, "Static", 0x0138)
    BS_CHECKBOX := 0x2, BS_RADIOBUTTON := 0x8

    __New() {
        for i, j in this.WM_CTLCOLOR {
            OnMessage(j, this.msghandler)
        }
    }
    __Delete() {
    }
 
    hook(hwnd, clrtx, clrbk) {
        If !this.ctls.Has(hwnd) {
            brush := DllCall("Gdi32.dll\CreateSolidBrush", "uint", clrbk, "ptr")
            this.ctls[hwnd] := {brush: brush, clrtx: clrtx, clrbk: clrbk}
            DllCall("User32.dll\InvalidateRect", "ptr", hwnd, "ptr", 0, "int", 1)
            if (WinGetClass("ahk_id " . hwnd) = "ComboBox") {
                cbbi := Buffer(40+A_PtrSize*3)
                NumPut("uint", cbbi.size, cbbi)
                if DllCall("User32.dll\GetComboBoxInfo", "ptr", hwnd, "ptr", cbbi, "int") {
                    this.hook(NumGet(cbbi, 40 + A_PtrSize, "ptr"), clrtx, clrbk)
                    this.hook(NumGet(cbbi, 40 + A_PtrSize * 2, "ptr"), clrtx, clrbk)
                }
            }
        }
    }

    OnMessage(wparam, lparam, msg, hwnd) {
        Critical
        If this.ctls.Has(lparam) {
            ctl := this.ctls[lparam]
            DllCall("Gdi32.dll\SetTextColor", "ptr", wparam, "int", ctl.clrtx)
            DllCall("Gdi32.dll\SetBkColor", "ptr", wparam, "int", ctl.clrbk)
            return ctl.brush
        }
    }
}