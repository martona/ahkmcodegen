#Requires AutoHotkey v2.0+

CL_GCC   := 1
CL_CLANG := 2
CL_WSL   := 4
CL_IDENT := ""
AS_GAS   := 1
AS_WSL   := 4
AS_IDENT := ""

PROGRAM_SOURCE_FILE := ""
AHK_SOURCE_FILE := ""
CL_USED := 0
CL_LOC  := ""
CL_FLG  := "-march=native"
CL_OPT  := "-O2"
AS_USED := 0
AS_LOC  := ""
AS_FLG  := "-O2"

class tabMain extends GuiBase {

	log := 0
    ctrl_cl_idnt    := 0
    ctrl_as_idnt    := 0

    getName() {
        return "Main"
    }

    preInit() {
        GuiBase.register(this)
        AppendConfig([ "PROGRAM_SOURCE_FILE", "AHK_SOURCE_FILE",
            "CL_USED", "AS_USED",
            "CL_LOC", "CL_FLG", "CL_OPT",
            "AS_LOC", "AS_FLG", ])
    }

    start() {

		this.guiAdd("Text", "section h0 w0")

        this.startGroupBox("Configuration Used")
        cfg_copythis    := -1
        (ctrl_cfg_dn := this.guiAdd("Button", "section xs", "<")).OnEvent("Click", cfg_dn)
        ctrl_cfg_txt := this.guiAdd("Text", "ys hp center 0x200", "000000", )
        (ctrl_cfg_up := this.guiAdd("Button", "ys +disabled", ">")).OnEvent("Click", cfg_up)
        this.guiAdd("Button", "ys", "Add new").OnEvent("Click", cfg_add)
        (ctrl_cfg_dl := this.guiAdd("Button", "ys +disabled", "Delete current")).OnEvent("Click", cfg_dl)
        (ctrl_cfg_cp := this.guiAdd("Button", "ys", "Copy current")).OnEvent("Click", cfg_cp)
        (ctrl_cfg_ps := this.guiAdd("Button", "ys +disabled", "Paste 999")).OnEvent("Click", cfg_ps)
        update_cfg_ctls()
        update_cfg_ctls() {
            ctrl_cfg_txt.Value := _ACTIVE_CONFIGURATION
            ctrl_cfg_dn.Opt(_ACTIVE_CONFIGURATION ? "-disabled" : "+disabled")
            ctrl_cfg_up.Opt(IsConfigSlotUsed(_ACTIVE_CONFIGURATION+1) ? "-disabled" : "+disabled")
            ctrl_cfg_dl.Opt((_ACTIVE_CONFIGURATION && IsConfigSlotUsed(_ACTIVE_CONFIGURATION)) ? "-disabled" : "+disabled")
            ctrl_cfg_ps.Opt((cfg_copythis = -1 || _ACTIVE_CONFIGURATION = cfg_copythis) ? "+disabled" : "-disabled")
            this.updateImageButtonText(ctrl_cfg_ps, (cfg_copythis = -1) ? "Paste" : ("Paste " . cfg_copythis))
            ctrl_cfg_cp.Opt((!IsConfigSlotUsed(_ACTIVE_CONFIGURATION)) ? "+disabled" : "-disabled")
        }
        cfg_dn(*) {
            SaveSettings()
            SetGlobal("_ACTIVE_CONFIGURATION", _ACTIVE_CONFIGURATION-1)
            cfg_chg()
        }
        cfg_up(*) {
            SaveSettings()
            SetGlobal("_ACTIVE_CONFIGURATION", _ACTIVE_CONFIGURATION+1)
            cfg_chg()
        }
        cfg_dl(*) {
            RemoveCfgSection(_ACTIVE_CONFIGURATION)
            SetGlobal("_ACTIVE_CONFIGURATION", _ACTIVE_CONFIGURATION-1)
            cfg_copythis := -1
            cfg_chg()
        }
        cfg_add(*) {
            SaveSettings()
            SetGlobal("_ACTIVE_CONFIGURATION", GetLastConfigSlotUsed()+1)
            cfg_chg()
        }
        cfg_chg() {
            SaveSettings(true)
            LoadSettings(true)
            theGui.refreshUIFromGlobals()
            update_cfg_ctls()
            SetGlobal("CL_USED", 0)
            SetGlobal("CL_IDENT", 0)
        }
        cfg_cp(*) {
            cfg_copythis := _ACTIVE_CONFIGURATION
            cfg_chg()
        }
        cfg_ps(*) {
            CfgCopy(cfg_copythis, _ACTIVE_CONFIGURATION)
            LoadSettings(true)
            cfg_chg()
        }
        this.endGroupBox()

        this.columnWidth00 -= 100
        this.columnWIdth01 += 100
        this.startGroupBox("Source code")
        this.addFileSelection(
			"",
			"PROGRAM_SOURCE_FILE",
			"This is the C program you're compiling. ",
            this.refreshStatus,
		)
        this.endGroupBox()

        this.startGroupBox("Existing AHK script for auto-insertion (optional)")
        this.addFileSelection(
			"",
			"AHK_SOURCE_FILE",
			"The AutoHotkey script specified here will receive an automatically-inserted mcode block.`r`n`r`n"
            . "Note that this will only UPDATE an existing block that you've manually pasted in before, "
            . "and metadata must be present as comments (see Options tab).`r`n`r`n"
            . "Leave this blank to not use this feature.",
            this.refreshStatus,
		)
        this.endGroupBox()

        this.startGroupBox("Compiler")
		this.addFileSelection(
			"Location",
			"CL_LOC",
			"Please select the compiler executable you intend to use..",
            this.cl_changed.Bind(this),
		)
        this.guiAdd("Text", "section xs w" . this.columnWidth00, "Detected as")
        this.ctrl_cl_idnt := this.guiAdd("Text", "ys w" . this.columnWidth01, "Unknown")

        this.addDropDown(
            "Options",
            ["-O0", "-O1", "-O2", "-O3", "-Os", "-Ofast", "-Oz"],
            "","CL_OPT",
            "", 0, 0, [this.columnWidth00, 70]
        )
        this.addEditBox(
            "",
            "CL_FLG",
            "Select the level of optimization (-O2 or O3 recommended), and specify "
            . "any additional command line options to pass to the compiler.`r`n`r`n"
            . "This field is optional, even though you should probably select a "
            . "-march option. The default provided can be safely changed or removed.",
            "", "", [0, this.columnWidth01 - 70 - GuiBase.mainGui.MarginX * 1]
        )
        this.endGroupBox()

        this.startGroupBox("GNU Assembler")
		this.addFileSelection(
			"Location",
			"AS_LOC",
			"Please select the as executable you intend to use.`r`n`r`n"
            . "This is typically found as as.exe in the same location as gcc.exe. "
            . "If you intend to use clang as your compiler, you might still need "
            . "to install gcc just to get ahold of as.",
            this.as_changed.Bind(this),
		)
        this.guiAdd("Text", "section xs w" . this.columnWidth00, "Detected as")
        this.ctrl_as_idnt := this.guiAdd("Text", "ys w" . this.columnWidth01, "Unknown")
        this.addEditBox(
            "Options",
            "AS_FLG",
            "Specify additional options to pass to as.",
        )
        this.endGroupBox()
        this.columnWidth00 += 100
        this.columnWIdth01 -= 100

		this.finalizeFinalColumn()

        clobj := {
            changes:        0, 
            ctl:            this.ctrl_cl_idnt, 
            glbToolLoc:     "CL_LOC",
            glbToolUse:     "CL_USED",
            glbToolIdnt:    "CL_IDENT",
            useIdents:      [   {regex: "i)\bGCC\b",      ident: "CL_GCC"}, 
                                {regex: "i)\bclang\b",    ident: "CL_CLANG"}
                            ],
            wsl: "CL_WSL",
        }
        asobj := {
            changes:        0, 
            ctl:            this.ctrl_as_idnt, 
            glbToolLoc:     "AS_LOC",
            glbToolUse:     "AS_USED",
            glbToolIdnt:    "AS_IDENT",
            useIdents:      [{regex: ".*GNU assembler.*", ident: "AS_GAS"}],
            wsl:            "AS_WSL" 
        }
        this.detectToolChangeTracker := Map("cl", clobj, "as", asobj)

        this.refreshUI()
        this.refreshStatus()
    }

    cl_changed(*) {
        SetTimer(this.timerFn, 1000)
        this.detectToolChangeTracker["cl"].changes++
        SetGlobal("CL_USED", 0)
        SetGlobal("CL_IDENT", 0)
        this.refreshStatus()
        this.ctrl_cl_idnt.Value := "One second..."
    }
    as_changed(*) {
        SetTimer(this.timerFn, 1000)
        this.detectToolChangeTracker["as"].changes++
        SetGlobal("AS_USED", 0)
        SetGlobal("AS_IDENT", 0)
        this.refreshStatus()
        this.ctrl_as_idnt.Value := "One second..."
    }
    
    detectToolLastCfg := 0
    detectToolChangeTracker := 0
    timerFn := ObjBindMethod(this, "refreshToolVersion")
    refreshToolVersion() {
        for id, obj in this.detectToolChangeTracker {
            highmark := obj.changes
            if highmark || this.detectToolLastCfg != _ACTIVE_CONFIGURATION {
                obj.ctl.Text := "Working..."
                this.detectToolVersion(obj)
                this.refreshStatus()
                obj.changes -= highmark
            }
        }
        this.detectToolLastCfg := _ACTIVE_CONFIGURATION
    }

    refreshUI() {
        this.cl_changed()
        this.as_changed()
    }

    refreshStatus() {
        if (!PROGRAM_SOURCE_FILE || !FileExist(PROGRAM_SOURCE_FILE))
            GuiBase.status("Need source file specified")
        else if !CL_IDENT
            GuiBase.status("Need compiler")
        else if !AS_IDENT
            GuiBase.status("Need assembler")
        else
            GuiBase.status("Ready.")
    }

    detectToolVersion(obj) {
        cfg := _ACTIVE_CONFIGURATION
        local_tool_loc := %obj.glbToolLoc%
        ver := this.detectCommandVersion(local_tool_loc)
        ; if the user flipped to a different configuration while the above
        ; command was running, this function is being called again
        ; so we don't need to go further
        if cfg = _ACTIVE_CONFIGURATION && local_tool_loc = %obj.glbToolLoc% {
            if ver && ver[1] {
                for i in obj.useIdents
                    SetGlobal(obj.glbToolUse, %obj.glbToolUse% | ((RegExMatch(ver[1], i.regex)) ? %i.ident% : 0))
                SetGlobal(obj.glbToolUse, %obj.glbToolUse% | (ver[2] ? %obj.wsl% : 0))
                ver := ver[1]
            } else {
                ver := ""
            }
            obj.ctl.Value := ((%obj.glbToolUse% & %obj.wsl%) ? "*WSL* " : "") . (ver ? ver : "Unknown")
            SetGlobal(obj.glbToolIdnt, ver)
        }
    }

    detectCommandVersion(cmd) {
        if RegExMatch(cmd, "\b(gcc|as|clang)\b") {
            v := GetCommandOutput('"' . cmd . '" --version')
            if (v) {
                v := StrSplit(v, "`n", "`r")[1]
                return [v, false]
            }
            if _OPTS_WSL && !InStr(cmd, "\") {
                v := GetCommandOutput('wsl.exe "' . cmd . '" --version')
                if (v) {
                    v := StrSplit(v, "`n", "`r")[1]
                    return [v, true]
                }
            }
        }
        return false
    }
}
