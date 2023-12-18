#Requires AutoHotkey v2.0
#include "..\_get_c_function_header.ahk"

testcases := [
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    "int main(int argc, char *argv[]) {",
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    "
    (
    /*
    some multiline comment
    and some more text
    */

    some function-like text (something here) {
        for loop or whatever {
        }
        if {
            a = main(lol);
        }
        else {
            {}
        }
    }
    foo not_main() {return 0;}
    int main //best function()
    (
        /* not this 
            or this*/ int argc, //this either
        char *argv[] /*<3<3<3PARAMETERS<3<3<3*/
    /*will this work?*/ )
    {
        return 0;
    }
    )",
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    "
    (
        int /*the return type*/ main /*
                                       we love comments
        */ ( /*the parameters*/ int argc, char *argv[] /*<3<3<3PARAMETERS<3<3<3*/ ) {
            return 0;
        }
    )",
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
]

test()

test() {
    for testcase in testcases {
        result := _get_c_function_header("main", testcase, "")
        if result != "int main(int argc, char *argv[])" {
            Throw("failed case: " . testcase)
        }
    }
    MsgBox("all tests passed")
}
