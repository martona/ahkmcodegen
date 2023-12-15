#Requires AutoHotkey v2.0+

_OPTS_IGNOREWARNINGS := 0
_OPTS_KEEPJUNK := 0
_OPTS_NOPEMPTYCALLS := 1
_OPTS_MERGE_RDATA := 1
_OPTS_SHOW_COMMANDS := 1
_OPTS_WSL := 0
_OPTS_BASE64_LINELEN := 80
_OPTS_MCODE_META := 1

class tabOpts extends GuiBase {

    getName() {
        return "Opts"
    }

    preInit() {
        AppendConfig([ "_OPTS_IGNOREWARNINGS", "_OPTS_KEEPJUNK", "_OPTS_NOPEMPTYCALLS", 
            "_OPTS_MERGE_RDATA", "_OPTS_SHOW_COMMANDS", "_OPTS_WSL", "_OPTS_BASE64_LINELEN",
            "_OPTS_MCODE_META"])
    }

    start() {
        ; groupboxes seem to want this as an anchor
		this.guiAdd("Text", "section h0 w0")

        this.startGroupBox("General")
		this.addCheckbox(
			"Ignore compiler warnings",
			"_OPTS_IGNOREWARNINGS",
			"Ignore warnings produced by the compiler, and proceed to generate the mcode block anyway.",
		)
		this.addCheckbox(
			"Keep intermediate files",
			"_OPTS_KEEPJUNK",
			"Do not auto-delete the various intermediary files produced by the compiler and the "
            . "assembler.`r`n`r`n"
            . "Leaving them around might be useful to check the generated assembly code, but if you want to "
            . "do this, godbolt.org is probably a more useful tool."
		)
        this.addCheckbox(
			"Use WSL",
			"_OPTS_WSL",
			"If you have the Windows Subsystem for Linux installed, you can use the developer tools in "
            . "your Linux environment to compile code.`r`n`r`n"
            . "This isn't anything fancy, this program will just use 'wsl.exe <your compiler "
            . "specification>' when identifying or running gcc or clang.`r`n`r`n"
            . "Note that you do need to install a windows cross-compiler on Linux for this to work "
            . "reliably, such as gcc-mingw-w64-x86-64-win32, as well as the corresponding binutils "
            . "package for gas.`r`n`r`n"
            . "For the above example your 'compiler location' specification becomes just 'x86_64-w64-mingw32-gcc'"
            . ", and for the assembler you'd type 'x86_64-w64-mingw32-as'."
		)
        this.endGroupBox()

        this.startGroupBox("Code generation")
		this.addCheckbox(
			"Patch null CALLs",
			"_OPTS_NOPEMPTYCALLS",
			"Some GCC implementations (e.g. mingw-win32-x64 as of 2023/12/9) will insert CALLs to "
            . "library routines without asking, or there being a way of disabling this behavior.`r`n`r`n"
            . "mingw for example will call ___chkstk_ms if you use more than 4KB of stack.`r`n`r`n"
            . "Since we have no way of actually linking to the called routines, this program can patch "
            . "the intermediary .s file to remove these instructions.`r`n`r`n"
            . "Select this option to do so silently, without being prompted.",
		)
		this.addCheckbox(
			"Merge .rdata into .text",
			"_OPTS_MERGE_RDATA",
			"Optimization /O3 (on a suitable platform specified by -march) will heavily vectorize "
            . "the code.`r`n`r`n"
            . "This results in the automatic addition of an .rdata section that holds initializers "
            . "for some of the vectors. The code addressing these locations normally needs linker "
            . "support which we can't have.`r`n`r`n"
            . "This program can merge the .rdata section into .text, which solves the problem. " 
            . "Not doing so will almost certainly produce code that will crash on execution, or "
            . "at least produce incorrect results.`r`n`r`n"
            . "Select this option to merge the sections silently, without being prompted.",
		)
        this.endGroupBox()

        this.startGroupBox("Output")
        this.addCheckbox(
			"Show executed commands",
			"_OPTS_SHOW_COMMANDS",
			"Show the full command line for the compiler and the assembler as they're being called. ",
		)
        this.addCheckbox(
			"Meta info in comments",
			"_OPTS_MCODE_META",
			"Include meta-info in the generated output, such as the name of the source file, the "
            . "compiler version, compiler flags, etc.",
		)
        this.addEditBox(
            "base64 line length",
            "_OPTS_BASE64_LINELEN",
            "The number of characters per base64 output line, between the enclosing quoutes.",
        )
        this.endGroupBox()

		this.finalizeFinalColumn()
        return
    }
}
