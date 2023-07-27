import nigui
import osproc
import strutils
import sequtils
import passutils
import std/random
import system

randomize()

proc showError*(text: string) = 
    discard execCmd("zenity --error --text=\'$1\'" % text)

proc showSuccess*(text: string) = 
    discard execCmd("zenity --info --text=\'Success! $1\'" % text)

proc show*(name, password: string) = 
    discard execCmd("zenity --info --text=\'Name: $1\nPassword: $2\'" % [name, password])


proc initStoragePrompt*(): string = 
    var cmd =   "zenity --entry --hide-text --text=\'This is the first time you use nimpass. Therefore, storage must be initialized.\n" &
                "You have to input new masterkey. It will be used to work with passwords.\nInput masterkey:\'"
    var (pass1, es1) = execCmdEx(cmd)
    if es1 != 0: return ""


    cmd =   "zenity --entry --hide-text --text=\'Please enter the masterkey again:\'"
    var (pass2, es2) = execCmdEx(cmd)
    if es2 != 0: return ""


    pass1 = pass1.strip(chars = {'\n'})
    pass2 = pass2.strip(chars = {'\n'})

    if pass1 != pass2:
        showError("Masterkeys do not match.")
        return ""

    if pass1.len == 0:
        showError("Masterkey can not be empty.")
        return ""

    return pass1

proc masterkeyPrompt*(): string = 
    var cmd = "zenity --entry --hide-text --text=\'Please input masterkey to continue:\'"
    var (pass, es) = execCmdEx(cmd)
    if es != 0: return ""

    pass = pass.strip(chars = {'\n'})

    return pass



const randomPasswordLen = 32
let alphabet* = toSeq("1234567890qwertyuiopasdfghjklzxcvbnm!@#$^*+_=-QWERTYUIOPASDFGHJKLZXCVBNM".items)

proc passwordPrompt*(): string = 
    var cmd =   "zenity --question --text=\"Do you want to use a randomly generated password? " &
                "Press Yes if yes, and No if you want to input the password yourself.\"; echo $?"

    var (opt, es) = execCmdEx(cmd)
    if es != 0: return ""
    opt = opt.strip(chars = {'\n'})

    var password: string = ""
    if opt == "0":
        for i in 0..<randomPasswordLen:
            password.add(sample(alphabet))
        return password

    (password, es) = execCmdEx("zenity --entry --hide-text --text=\"Enter the password:\"")
    if es != 0: return "" 

    password = password.strip(chars = {'\n'})

    return password
    