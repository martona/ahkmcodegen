# ahkmcodegen 0.1
The first release of an "mcode" generator for **AutoHotkey**. 

"mcode'" is what the **AutoHotkey** forums call machine code embedded in script files. These functions are called to make certain calculations faster. While **AutoHotkey** - especially version 2 - is a capable language, it is interpreted, therefore everything but fast. More about mcode's inception here: https://www.autohotkey.com/boards/viewtopic.php?f=7&t=32

Your compiled C code runs in a shellcode-like environment: no heap, no runtime, no APIs (not in a straightforward manner anyway). It's great for certain things: math heavy stuff,  pixel-crunching, and so on. For everything else you can break out the SDK and create a DLL.

# This Doc
- [Why](#why)
- [How](#how)
- [GCC and clang](#gcc-and-clang)
- [The Bad](#the-bad)
- [License](#license)
- [Credits](#credits)

# Why
The old MCode4GCC seems to be taking a break from updates. I was working on some pixel-heavy code and needed some features, so this project was born. Notable new stuff:

- Use **gcc** or **clang**
	>Having more options is always good, and **clang** is an excellent alternative to **gcc**.
- Merge `.rdata` sections into `.text`
	>If your compiled  code contains large initializer data, the compiler will generate a read-only data (`.rdata`) section, but without a linker, your code won't be able to access it and crash, or worse, do random wrong stuff. The compilers - especially **gcc** - will heavily vectorize your code if `-march=` and `/On` allow; this will almost guarantee the placement of an `.rdata` section, even if you don't trigger it knowingly. This tool will merge `.rdata` into whatever section the code is in, so all will be well, and the assembler will make relative addressing work.
- Remove `call ___ms_chkstk`
	>Using more than 4KB of stack space in your code will trigger this stack check from **mingw**-based **gcc** with apparently no way to turn it  off. This seems to be a **mingw** specialty, and the usual switches such as `-fno-stack-check` or `-fno-stack-protector` won't affect it. These cannot be resolved without linking to the runtime, and will cause a crash otherwise, so they need to be removed. (I guess you *could* implement a dummy `inline ___ms_chkstk` in your own code that the optimizer will then remove, but why bother?)
- Support for more than one exported function from a single source in a single blob
	>Any function that's not explicitly `inline` or  `static` will be exported at a certain offset. These offsets will be shown during the build process, as well as - optionally - be part of the ready-to-paste base64-encoded text blob as **AutoHotkey** comments along with the name of the exported function. You can then add the shown value to the base address that you'd normally pass to `DllCall` to invoke them.
- Auto-generated metadata
	>Include the name of the C source file, the compiler version and compilation flags used, etc. with the blob to make your code easier to maintain.
- Multiple configurations
	>If you're working with more than one C source at a time, or using different compiler switches for the same one (`-march=x86-64-v4`, `-march=x86-64-v3`, etc.) flipping back and forth is easy.
- A few other minor things
	>Or maybe not so minor, but I'm currently forgetting about them? 

# How
There's some sample code included in the root of the repo:

sample.c
```
int sample(int a, int b) {
	return a+b;
}
```
sample.ahk
```
#Requires  AutoHotkey v2.0
MsgBox("39+3=" . call_mcode(39, 3))

call_mcode(a, b) {
	static  b64  :=  ""
	.  ""  ; sample.c
	.  ""  ; 16 bytes
	.  ""  ; x86_64-w64-mingw32-gcc (GCC) 10-win32 20220113
	.  ""  ; flags: -march=x86-64 -O3
	.  ""  ; GNU assembler (GNU Binutils) 2.38
	.  ""  ; flags: -O2
	.  ""  ; 0x000000: sample
	.  "jQQRw5CQkJCQkJCQkJCQkA=="

	static code := b64decode(b64)
	return DllCall(code, "int", a, "int", b, "int")
}

b64decode(s) {
	len  :=  strlen(s)*3//4
	code  :=  DllCall("GlobalAlloc", "uint", 0, "ptr", len, "ptr")
	if code {
		if DllCall("crypt32\CryptStringToBinary", "str", s, "uint", 0, "uint", 
                0x1, "ptr", code, "uint*", len, "ptr", 0, "ptr", 0, "int") {
			if DllCall("VirtualProtect", "ptr", code, "ptr", len, 
                    "uint", 0x40, "uint*", 0, "int") {
				return code
			}
		}
		DllCall("GlobalFree", "ptr", code, "ptr")
	}
	return 0
}
```
The `MsgBox` call invokes `call_mcode` which calls `b64decode` to turn the base64-blob into a memory address with executable code. `DllCall` then invokes it, and returns the answer to life, the universe, and everything. It's super straightforward. Since the local variables are declared `static`, they're only initialized on the first call.

# GCC and clang
You can get them from many places. My current favorite is the **MSYS2** development environment for Windows; it's tiny, neat, up to date, and seems well-supported. Install it from https://www.msys2.org/ then use their `pacman` package manager to get **gcc**, **clang**, or both.

There's a **mingw32** [download utility](https://github.com/Vuniverse0/mingwInstaller/) which will set you up with your choice of **gcc**. 

You can also run whatever Linux distro you want within WSL on Windows, install the latest **mingw** cross-compiler package in it (such as `gcc-mingw-w64-x86-64-win32`) then use `x86_64-w64-mingw32-gcc` as the compiler specification in ahkmcodegen. This requires WSL 2 and you need to enable it on the Options tab, but it works great.

# The Bad
- This project is new, and while I've been using it extensively, I have no idea what problems people may run into. I've been learning **AutoHotkey** 2 as I went, so the code is of varying quality.
- Untested/untried on 32-bit Windows, and while it might work, it probably won't. The code doesn't even consider the possiblity that anything other than a 64-bit world exists. The generated code blobs, if you're using a 32-bit cross-compiler, should be perfectly fine though.
- You might find the UI rough to look at. It's servicable and nothing requires more clicks than necessary, I think, but I'm not a UI/UX guy.

# License
MIT.

# Credits

**Bart Uliasz**' [tesstrain-windows-gui](https://github.com/buliasz/tesstrain-windows-gui) project inspired the UI layout code.

**just me**'s [CreateImageButton](https://www.autohotkey.com/boards/viewtopic.php?t=93339) is used for the buttons.
