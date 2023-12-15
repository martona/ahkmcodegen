
CONFIGURATION_FILE := A_ScriptDir "\cfg.ini"
CONFIGURATION_USED := 0
_ACTIVE_CONFIGURATION := 0

CONFIGURATION_VARIABLES_LIST := [
	"_ACTIVE_CONFIGURATION", "CONFIGURATION_USED"
]

VALUE_VALIDATORS := Map(
	"_OPTS_BASE64_LINELEN",   (a)=>(IsInteger(a) && a > 0 && a < 16384),
)

AppendConfig(cfg) {
	i := 1
	while i <= cfg.Length
		CONFIGURATION_VARIABLES_LIST.Push(cfg[i++])
}

SaveSettings(metaOnly := false) {
	SetGlobal("CONFIGURATION_USED", 1)
	for var in CONFIGURATION_VARIABLES_LIST {
		if SubStr(var, 1, 1) = "_" {
			IniWrite(%var%, CONFIGURATION_FILE, "General", var)
		} else {
			if (!metaOnly)
				IniWrite(%var%, CONFIGURATION_FILE, Format("{:04d}", _ACTIVE_CONFIGURATION), var)
		}
	}
}

LoadSettings(ignoreMeta := false) {
	SetGlobal("CONFIGURATION_USED", 0)
	; load meta first
	if !ignoreMeta {
		for var in CONFIGURATION_VARIABLES_LIST {
			if !IsSet(%var%)
				SetGlobal(var, 0)
			if SubStr(var, 1, 1) = "_" {
				SetGlobal(var, IniRead(CONFIGURATION_FILE, "General", var, %var%))
			}
		}
	}
	; load the active config
	for var in CONFIGURATION_VARIABLES_LIST {
		if !IsSet(%var%)
			SetGlobal(var, 0)
		if SubStr(var, 1, 1) != "_"  {
			SetGlobal(var, IniRead(CONFIGURATION_FILE, Format("{:04d}", _ACTIVE_CONFIGURATION), var, %var%))
		}
	}
}

RemoveCfgSection(n) {
	while(IsConfigSlotUsed(n+1)) {
		s := IniRead(CONFIGURATION_FILE, Format("{:04d}", n+1))
		IniWrite(s, CONFIGURATION_FILE, Format("{:04d}", n++))
	}
	IniDelete(CONFIGURATION_FILE, Format("{:04d}", n))
}

CfgCopy(from, to) {
	if from != to {
		s := IniRead(CONFIGURATION_FILE, Format("{:04d}", from))
		IniWrite(s, CONFIGURATION_FILE, Format("{:04d}", to))
	}
}

GetLastConfigSlotUsed() {
	i := _ACTIVE_CONFIGURATION
	while(true) {
		if !IsConfigSlotUsed(i)
			return i-1
		i++
	}
}

IsConfigSlotUsed(n) {
	return IniRead(CONFIGURATION_FILE, Format("{:04d}", n), "CONFIGURATION_USED", 0)
}

SetGlobal(varName, varValue) {
    global
    %varName% := varValue
}
