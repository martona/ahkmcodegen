#Requires AutoHotkey v2.0

MsgBox("39+3=" . call_mcode(39, 3))

call_mcode(a, b) {
    static b64 := ""
    . "" ; sample.c
    . "" ; 16 bytes
    . "" ; x86_64-w64-mingw32-gcc (GCC) 10-win32 20220113
    . "" ; flags: -march=x86-64 -O3
    . "" ; GNU assembler (GNU Binutils) 2.38
    . "" ; flags: -O2
    . "" ; 0x000000: sample
    . "jQQRw5CQkJCQkJCQkJCQkA=="
    static code := b64decode(b64)
    return DllCall(code, "int", a, "int", b, "int")
}

b64decode(s) {
    len := strlen(s)*3//4
    code := DllCall("GlobalAlloc", "uint", 0, "ptr", len, "ptr")
    if code {
        if DllCall("crypt32\CryptStringToBinary", "str", s, "uint", 0, "uint", 0x1, "ptr", code, "uint*", len, "ptr", 0, "ptr", 0, "int") {
            if DllCall("VirtualProtect", "ptr", code, "ptr", len, "uint", 0x40, "uint*", 0, "int") {
                return code
            }
        }
        DllCall("GlobalFree", "ptr", code, "ptr")
    }
    return 0
}
