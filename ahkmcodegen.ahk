#Requires AutoHotkey 2.0+

#SingleInstance Force
SendMode "Event"
SetWinDelay -1
CoordMode "Mouse", "Screen"
CoordMode "Pixel", "Screen"
FileEncoding "UTF-8-RAW"

VERSION_NUMBER := "0.1"
PROGRAM_TITLE := "ahkmcodegen"
DEBUG_MODE := true

#include "_cfg.ahk"
#include "_guibase.ahk"
#include "_tab_main.ahk"
#include "_tab_opts.ahk"
#include "_tab_out.ahk"

theGui := ahkmcodegen()
theGui.start()

_UI_SELECTED_TAB := 0

class ahkmcodegen extends GuiBase {

	tabmai := tabMain()
	tabout := tabOut()
	tabopt := tabOpts()
	tabs := 0

	preInit() {
        AppendConfig([ "_UI_SELECTED_TAB"])
	}

	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	start() {

		this.preInit()
		this.tabmai.preInit()
		this.tabout.preInit()
		this.tabopt.preInit()
		LoadSettings()

		super.start()

		this.tabs := this.guiAdd("Tab3", "", 
			[this.tabmai.getName(), this.tabout.getName(), this.tabopt.getName()])
		this.tabs.OnEvent("Change", eventTabChange)

		this.tabs.UseTab(this.tabmai.getName())
		this.tabmai.Start()
		this.tabs.UseTab(this.tabout.getName())
		this.tabout.Start()
		this.tabs.UseTab(this.tabopt.getName())
		this.tabopt.Start()
		
		this.tabs.UseTab()

		anchor := this.guiAdd("Button", "section", "")
		anchor.Move(,,0,0)
		this.pushRightMark()
		GuiBase.statusControl := this.guiAdd("Text", "xp ys hp 0x200")
		; we only needed that button at its original size to get this text
		; control to pick up on the height for the 0x200 (VCENTER) option
		if (DEBUG_MODE) {
			this.guiAdd("Button", "ys x+10", "&Reload").OnEvent("Click", this.reloadApp)
		}
		this.guiAdd("Button", "ys x+10", "&Compile").OnEvent("Click", eventCompile)
		this.guiAdd("Button", "ys x+10", "E&xit").OnEvent("Click", this.exitGui)
		this.pushRightFinish(false, true)

		this.tabmai.refreshStatus()
		this.setCurrentTab(this.tabs, _UI_SELECTED_TAB)
		GuiBase.mainGui.Show()
		return

		eventTabChange(*) {
			SetGlobal("_UI_SELECTED_TAB", this.getCurrentTab(theGui.tabs))
			SaveSettings()
		}

		eventCompile(*) {
			theGui.tabout.compile()
		}
	}
}

