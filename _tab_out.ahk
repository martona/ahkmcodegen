#Requires AutoHotkey v2.0+
#include "_get_c_function_header.ahk"

class tabOut extends GuiBase {

    ctl_log := 0
    ctl_out := 0
    ctl_cpy := 0

    getName() {
        return "Output"
    }

    preInit() {
    }

    start() {
		this.guiAdd("Text", "section h0 w0")
        this.startGroupBox("Command output")
        this.ctl_log := this.guiAdd("Edit", "-E0x200 section xs r6 w" . (this.columnWidthAll - 24) . " +multi +readonly")
        this.endGroupBox()
        this.startGroupBox("mcode")
        this.ctl_out := this.guiAdd("Edit", "-E0x200 section xs r8 w" . (this.columnWidthAll - 24) . " +multi +readonly")
        this.pushRightMark()
        this.guiAdd("Button", "section xs", "&Decoder...").OnEvent("Click", eventDecoder)
        this.ctl_cpy := this.guiAdd("Button", "ys +disabled", "C&opy to clipboard")
        this.ctl_cpy.OnEvent("Click", eventCopy)
        this.pushRightFinish(true)
        this.endGroupBox()
		this.finalizeFinalColumn()
        return

        eventDecoder(*) {
            if "Yes" = MsgBox("Copy a sample decoder to the clipboard?",
                "Decoder", "YesNo Icon?") {
                sample := FileRead(A_ScriptDir . "\sample.ahk")
                A_Clipboard := sample
                MsgBox("Done.", "Decoder")
            }

        }
        eventCopy(*) {
            A_Clipboard := this.ctl_out.Value
        }
    }

    out(txt) {
        this.ctl_out.Value := txt
        this.ctl_cpy.Opt(txt ? "-disabled" : "+disabled")
    }

    compile() {
        GuiBase.status("Working...")
        if (!PROGRAM_SOURCE_FILE) || (!FileExist(PROGRAM_SOURCE_FILE)) {
            MsgBox("Please specify a valid source file to compile.")
            GuiBase.status()
            return
        }
        if !CL_LOC || !CL_IDENT
        {
            MsgBox("Cannot find the compiler. Please make sure the file exists.")
            GuiBase.status()
            return
        }
        if !AS_LOC || ! AS_IDENT
        {
            MsgBox("Cannot find the assembler. Please make sure the file exists.")
            GuiBase.status()
            return
        }

        ; clear output
        this.ctl_log.Value := ""
        this.out("")

        ; set working dir to the source's directory so any #includes
        ; it does will work
        workingdir := ""
        source_name := PROGRAM_SOURCE_FILE
        filesepidx := InStr(PROGRAM_SOURCE_FILE, "\",, -1)
        if filesepidx {
            workingdir := SubStr(PROGRAM_SOURCE_FILE, 1, filesepidx - 1) 
            source_name := SubStr(PROGRAM_SOURCE_FILE, filesepidx+1)
        }

        ; cobble up cl flags
        clopts := CL_FLG . " " . CL_OPT
        clopts := clopts . ((CL_USED & CL_CLANG) ? " -fno-integrated-as" : "")
        ; source
        srcfile := source_name
        ; linker output
        objfile := source_name . ".o"
        ; c function names
        auxfile := source_name . ".aux.txt"
        ; the listing that we're after
        lstfile := source_name . ".lst.txt"
        ; stderr gets redirected here
        errfile := source_name . ".err.txt"
        ; the intermediate assembly file
        asmfile := source_name . ".s"
        ; remove any previously genrated  files if they're still around
        removeWorkFiles()
        ; final command line
        fmts := CL_USED & CL_WSL ?  (
                                        (CL_USED & CL_GCC) ? 
                                            '{} /c "wsl.exe "{}" "{}" {} "{}" -aux-info "{}" 2> "{}""'
                                            :
                                            '{} /c "wsl.exe "{}" "{}" {} "{}" 2> "{}""'
                                    ) : (
                                        (CL_USED & CL_GCC) ?
                                            '{} /c ""{}" "{}" {} "{}" -aux-info "{}" 2> "{}""'
                                            :
                                            '{} /c ""{}" "{}" {} "{}" 2> "{}""'
                                    )
        cl := CL_USED & CL_GCC ?
            Format(fmts, A_ComSpec, CL_LOC, srcfile, clopts . " -S -c -o", asmfile, auxfile, errfile) :
            Format(fmts, A_ComSpec, CL_LOC, srcfile, clopts . " -S -c -o", asmfile, errfile)
        ; log all this stuff
        if _OPTS_SHOW_COMMANDS {
            log("Working Directory: ")
            log(workingdir)
            log()
            log("Executing: ")
            log(cl)
            log()
        }
        ; fix up path in case gcc needs additional stuff
        ec := run_cl(CL_LOC, cl)
        log("Compiler exit code: " . ec)

        ; read and display stderr
        err := ""
        if FileExist(workingdir . "\" . errfile)
            err := FileRead(workingdir . "\" . errfile)
        if (err)
            log(err)
        ; ask about warnings
        if ec = 0 && StrLen(err) {
            answer := askAboutWarnings()
            if answer = "No" {
                GuiBase.status()
                return
            }
        }
        ; bail if error
        if ec {
            GuiBase.status("Compiler reported failure. Exit code " . ec . ".")
            return
        }

        if _OPTS_MERGE_RDATA | _OPTS_NOPEMPTYCALLS {
            ; patch the .s file for .rdata or call __chkstk_ms
            lst := ""
            if FileExist(workingdir . "\" . asmfile) {
                lst := FileRead(workingdir . "\" . asmfile)
            } else {
                log("ERROR: listing file not found while no error reported by assembler. Exiting.")
                GuiBase.status()
                return
            }
            out := "", line := 1, removed := 0, ignored := 0
            Loop Parse lst, "`n", "`r" {
                remove := false, ignore := false
                if RegExMatch(A_LoopField, "Ami)\s+call(l|q){0,1}\s+(___chkstk_ms|__stack_chk_fail)\b") {
                    remove :=  _OPTS_NOPEMPTYCALLS
                    ignore := !_OPTS_NOPEMPTYCALLS
                } else if RegExMatch(A_LoopField, "Ami)\s+\.section\s+\.(rdata|rodata|note)\b") ||
                          RegExMatch(A_LoopField, "Ami)\s+\.data\b") {
                    remove :=  _OPTS_MERGE_RDATA
                    ignore := !_OPTS_MERGE_RDATA
                }
                if (remove) {
                    log("INFO(" . PROGRAM_TITLE . "): " . asmfile
                        . "`r`n    line " . line . ", removed: " . Trim(A_LoopField))
                    removed++
                } else if (ignore) {
                    log("WARNING(" . PROGRAM_TITLE . "): " . asmfile
                        . "`r`n    line " . line . ", not handled: " . Trim(A_LoopField))
                    ignored++
                } else {
                    out := out . A_LoopField . "`n"
                }
                line++
            }
            encoding := FileEncoding("UTF-8-RAW")
            file := FileOpen(workingdir . "\" . asmfile, "w")
            file.Write(out)
            file.Close()
            FileEncoding(encoding)
            if removed | ignored {
                log("INFO(" . PROGRAM_TITLE . "): " . asmfile
                    . "`r`n    ignored " . ignored . " and removed " . removed . " line(s)")
            }
        }

        ; assembler command line
        asopts := AS_FLG
        fmts := (AS_USED & AS_WSL) ? 
            '{} /c "wsl.exe "{}" -aln="{}" {} -o "{}" "{}" 2> "{}""' :
            '{} /c ""{}" -aln="{}" {} -o "{}" "{}" 2> "{}""'
        ; the 16 width makes the listing not very human-readable but it allows for space for a full .align 64
        gas := Format(fmts, A_ComSpec, AS_LOC, lstfile, asopts . " --listing-lhs-width=16", objfile, asmfile, errfile)
        if _OPTS_SHOW_COMMANDS {
            log("Executing: ")
            log(gas)
            log()
        }
        ec := run_cl(AS_LOC, gas)
        log("Assembler exit code: " . ec)

        ; read and display stderr
        err := ""
        if FileExist(workingdir . "\" . errfile)
            err := FileRead(workingdir . "\" . errfile)
        if (err)
            log(err)
        ; ask about warnings
        if ec = 0 && StrLen(err) {
            answer := askAboutWarnings()
            if answer = "No" {
                GuiBase.status()
                return
            }
        }

        ; bail if error
        if ec {
            GuiBase.status("Assembler reported failure. Exit code " . ec . ".")
            return
        }

        ; load the output
        lst := ""
        if FileExist(workingdir . "\" . lstfile) {
            lst := FileRead(workingdir . "\" . lstfile)
        } else {
            log("ERROR: listing file not found while no error reported by assembler. Exiting.")
            GuiBase.status()
            return
        }

        if !_OPTS_KEEPJUNK 
            removeWorkFiles()

        blob  := Buffer(StrLen(lst)), blobptr := blob.ptr
        current_offset := 0, exported_labels := []
        Loop Parse lst, "`n", "`r" {
            found := RegExMatch(A_LoopField, "Ami)"
                    . "\s*(?<lineno>\d+)\s+"                        ; " 132 " (line number)
                    . "((?<offset>[\da-f]+)(?=\s)){0,1}\s*(?=\s)"   ; " 002f " (offset, 0 or 1 time)
                    . "(?<hex>((\s)\K[\da-f]+(?=\s))+)*\s*"         ; any hex string plus whitespace, 0 or more times
                    . "(\.section\s+(?<section>[^\s]+)){0,1}\s*"    ; ".section" followed by anything 0 or 1 time
                    . '(?<label>[a-z_][a-z_\d]*:\s*(#|$)){0,1}'     ; " _label2123:" followed by optional whitespace then a comment or the end of the line
                    . "(?<rest>.*)", &match)                        ; whatever's left from the line
            if found {
                if strlen(match["hex"]) {
                    mstr := StrReplace(StrReplace(match["hex"], " ", ""), "`t", "")
                    offset := ("0x" . match["offset"]) + 0
                    if offset != current_offset {
                        log("INTERNAL ERROR(" . PROGRAM_TITLE . "): " . lstfile
                                . "`r`n    line " . match["lineno"] . ": offset mismatch")
                        GuiBase.status("Error.")
                        return
                    }
                    if (mstr = "E800000000") {
                        log("WARNING(" . PROGRAM_TITLE . "): " . lstfile
                            . "`r`n    line " . match["lineno"] . " offs " . match["offset"] . ": " . mstr . " " . match["rest"])
                    }
                    blobptr := appendBufferHex(blobptr, mstr)
                    current_offset := current_offset + strlen(mstr) / 2
                }
                if match["section"] {
                    current_offset := 0
                    log("WARNING(" . PROGRAM_TITLE . "): " . lstfile 
                        . "`r`n    line " . match["lineno"] . ": .section " .  match["section"])
                }
                if match["label"] {
                    ; remove the ":" from the end of the label (it's guaranteed to be there)
                    label := SubStr(match["label"], 1, InStr(match["label"], ":") - 1)
                    xoffset := format("0x{:06x}", current_offset)
                    exported_labels.push({offset: xoffset, label: label})
                    log("INFO(" . PROGRAM_TITLE . "): " . lstfile 
                        . "`r`n    exported label at " . xoffset . ": " . label)
                    
                }
            }
        }

        bloblen := blobptr - blob.ptr
        b64b := b64encode(blob.ptr, bloblen)
        formatted := ""
        padding := "                                      "
        if (_OPTS_MCODE_META) {
            formatted := formatted . ". `"`" `; " . source_name . '`n'
            formatted := formatted . ". `"`" `; " . bloblen . ' bytes`n'
            formatted := formatted . ". `"`" `; " . CL_IDENT . '`n'
            formatted := formatted . ". `"`" `; flags: " . clopts . '`n'
            formatted := formatted . ". `"`" `; " . AS_IDENT . '`n'
            formatted := formatted . ". `"`" `; flags: " . asopts . '`n'
        }
        while StrLen(b64b) > 0 {
            formatted := formatted . '. "' . SubStr(b64b, 1, _OPTS_BASE64_LINELEN) . '"`n'
            b64b := SubStr(b64b, _OPTS_BASE64_LINELEN + 1)
        }
        if (_OPTS_MCODE_META) {
            longest_label := 0
            for label in exported_labels
                longest_label := max(longest_label, strlen(label.label))
            for label in exported_labels {
                line := ". `"`" `; " . label.offset . ": " . label.label
                if (_OPTS_FN_HDRS) {
                    line := line . substr(padding, 1, longest_label - strlen(label.label))
                    line := line . ": " . get_c_function_header(label.label, workingdir . "\" . srcfile, workingdir . "\" . auxfile)
                }
                formatted := formatted . line . '`n'
            }
        }
        this.out(formatted)

        GuiBase.status("Done. Code bytes: " 
            . bloblen . " (0x" . format("{:x}", bloblen)
            . "), text: " . strlen(formatted) . " characters")
        theGui.setCurrentTab(theGui.tabs, 1)
        return

        appendBufferHex(ptr, txt) {
            txt := StrReplace(txt, " ", "")
            while (strlen(txt)) {
                byte := ("0x" . SubStr(txt, 1, 2)) + 0
                txt := SubStr(txt, 3)
                NumPut("uchar", byte, ptr)
                ptr++
            }
            return ptr
        }

        b64encode(ptr, len) {
            str := ""
            ;just double the binary size, which is more
            ;than enough to hold the b64-encoded output
            ;which has a 33% overhead (4 bytes to store 3)
            ;(also adding 3 in case we're encoding a single
            ;byte which needs to be padded to 4)
            str_len := len * 2 + 3
            VarSetStrCapacity(&str, str_len)
            DllCall("Crypt32.dll\CryptBinaryToString",
                    "ptr", ptr, "uint", len, "uint", 0x40000001,
                    "str", str, "uintp", str_len, "cdecl uint")
            VarSetStrCapacity(&str, -1)
            return str
        }

        run_cl(path_cl, cl) {
            path_os := EnvGet("PATH")
            path_cl := SubStr(path_cl, 1, InStr(path_cl, "\",, -1))
            EnvSet("PATH", path_os . ";" . path_cl)
            ; run and grab output
            ec := RunWait(cl, workingdir, "Hide")
            EnvSet("PATH", path_os)
            return ec
        }

        askAboutWarnings() {
            return _OPTS_IGNOREWARNINGS ? "Yes" : MsgBox("There have been compiler warnings. "
                . "Please check the output. Continue generating code?"
                . "`r`n`r`n"
                . "(This message can be turned off on the Options tab.)",
                "Rats.", "Owner" . GuiBase.mainGui.Hwnd . " YesNo Icon!")
        }

        removeWorkFiles() {
            if  FileExist( workingdir . "\" . objfile)
                FileDelete(workingdir . "\" . objfile)
            if  FileExist( workingdir . "\" . lstfile)
                FileDelete(workingdir . "\" . lstfile)
            if  FileExist( workingdir . "\" . errfile)
                FileDelete(workingdir . "\" . errfile)
            if  FileExist( workingdir . "\" . asmfile)
                FileDelete(workingdir . "\" . asmfile)
            if  FileExist( workingdir . "\" . auxfile)
                FileDelete(workingdir . "\" . auxfile)
        }

        log(txt := "") {
            return this.log(txt)
        }
    }

    log(txt := "") {
		txt := txt . "`r`n"
		EM_SETSEL 		:= 0x0001
		EM_REPLACESEL 	:= 0x00C2
		try {
			SendMessage(EM_SETSEL, 0, -1, this.ctl_log)
		} catch as e {
		}
		try {
			SendMessage(EM_SETSEL, -1, -1, this.ctl_log)
		} catch as e {
		}
		try {
			SendMessage(EM_REPLACESEL, -1, StrPtr(txt), this.ctl_log)
		} catch as e {
		}
	}
}
