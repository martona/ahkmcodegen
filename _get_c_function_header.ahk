#Requires AutoHotkey v2.0

get_c_function_header(fname, file, auxinfo) {
    if (auxinfo && FileExist(auxinfo)) {
       aux := FileRead(auxinfo)
       aux := RegExReplace(aux, "/\*.*?\*/", "")
       Loop Parse aux, "`n", "`r" {
        s := A_LoopField
            s := RegExReplace(s, "^\s*extern\s*", "")
            if idx := RegExMatch(s, "^\s*[\w\*\s]*\s*\b" . fname . "\b\s*\(") {
                return trim(s)
            }
       }
    }

    ; if we didn't find it in the aux file, try to find it in the source file
    includes := ""
    txt := FileRead(file)
    ; get the path portion of the filename
    path := RegExReplace(file, "^(.*)\\[^\\]+$", "$1\")
    ; load #include'd stuff but not recursively
    Loop Parse txt, "`n", "`r" {
        s := A_LoopField
        if idx := RegExMatch(s, '\s*#include\s+\"(.*)\"', &match) {
            include_file := match[1]
            includes := includes . FileRead(path . include_file)
        }
    }
    return _get_c_function_header(fname, includes . txt)
}

_get_c_function_header(fname, txt) {
    ; Get the function header of a C function
    ; fname: name of the function
    ; file: the file to search in
    ; returns: the function header as a string
    ; example: get_c_function_header("main", "C:\main.c")
    ;          returns: "int main(int argc, char *argv[])"
    ;          if the function is not found, returns an empty string

    ; note that this has very obvious limitations since it's just a few regexes,
    ; not an actual C parser. the function's type should be on the same line as
    ; the function name, for example.

    in_code_block := 0
    in_multicomment := 0
    step := 0 ; 0 = looking for function, 1 = looking for parameters, 2 = looking for end of parameters
    header := ""
    Loop Parse txt, "`n", "`r" {
        s := A_LoopField
        while (s) {
            ; remove single-line comments
            s := RegExReplace(s, "//.*$", "")
            s := RegExReplace(s, "/\*.*?\*/", "")

            ; attempt to skip multiline comments
            if (in_multicomment) {
                if idx := RegExMatch(s, "\*/", &match) {
                    in_multicomment--
                    s := substr(s, idx + 2)
                } else {
                    s := ""
                    continue   
                }
            }
            if idx := RegExMatch(s, "/\*") {
                in_multicomment++
                ; the next line will be a comment, but process whatever we have
                ; before the /* marker
                s := substr(s, 1, idx - 1)
            }

            ; skip lines in code blocks
            if (!in_code_block) {
                if step = 0 {
                    ; attempt to match the function name
                    if idx := RegExMatch(s, "\s*([\w\*]+\s+)+" . fname . "\s*", &match) {
                        header := substr(s, idx, strlen(match[0]) - idx + 1)
                        s := substr(s, idx + strlen(match[0]))
                        step := 1
                    }
                }
                if step = 1 {
                    ; attempt to match the function parameters
                    if idx := RegExMatch(s, "\s*\(", &match) {
                        header .= match[0]
                        s := substr(s, idx + strlen(match[0]))
                        step := 2
                    } else {
                        s := ""
                    }
                }
                if step = 2 {
                    ; attempt to match the end of the function parameters
                    if idx := RegExMatch(s, ".*\)", &match) {
                        header .= match[0]
                        header := RegExReplace(header, "\s\s+", " ")
                        header := RegExReplace(header, "\s*\(\s*", "(")
                        header := RegExReplace(header, "\s*\)\s*", ")")
                        header := RegExReplace(header, "\s*,\s*", ", ")
                        header := RegExReplace(header, "\s*\*\s*", " *")
                        return header
                    } else {
                        header .= s
                        s := ""
                    }
                }
            }
            ; attempt to figure out if we're in a code block when we find the
            ; function header. if we are, then it's a call to the function, not the
            ; function definition itself.
            if step = 0 {
                while idx := RegExMatch(s, "\{|\}", &match) {
                    s := substr(s, idx + 1)
                    if match[0] = "{" {
                        in_code_block++
                    } else {
                        in_code_block--
                    }
                }
                ; if we're on step 0, and finished code block processing, we can consume the rest
                ; if the line
                s := ""
            }
            s := trim(s)
        }
    }
}
