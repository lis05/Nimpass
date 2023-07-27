import nigui
import strutils
import sequtils
import passutils
import safeutils
import dialogs
import osproc

const 
    windowWidth = 400
    windowHeight = 210
    labelFontSize = 26
    textBoxFontSize = 26
    buttonFontSize = 26
    separatorFontSize = 5

app.init()

# window setup
var window = newWindow("nimpass")
window.width = windowWidth
window.height = windowHeight


#! WIDGETS AND THEIR LAYOUTS
var layout = newLayoutContainer(Layout_Vertical)


# separator
proc newSeparator(): Label = 
    var separator = newLabel("")
    separator.fontSize = separatorFontSize

    return separator


# text box where user puts password's name
var passNameWidget = newTextBox("")
passNameWidget.fontSize = textBoxFontSize

block:
    var tempLayout = newLayoutContainer(Layout_Vertical)
    var frame = newFrame("Password name")
    frame.fontSize = labelFontSize

    tempLayout.frame = frame

    tempLayout.add(passNameWidget)

    layout.add(tempLayout)


# buttons
var saveButton = newButton("Save")
saveButton.widthMode = WidthMode_Expand
saveButton.fontSize = buttonFontSize

var updateButton = newButton("Update")
updateButton.widthMode = WidthMode_Expand
updateButton.fontSize = buttonFontSize

var deleteButton = newButton("Delete")
deleteButton.widthMode = WidthMode_Expand
deleteButton.fontSize = buttonFontSize

var listButton = newButton("List")
listButton.widthMode = WidthMode_Expand
listButton.fontSize = buttonFontSize

var showButton = newButton("Show")
showButton.widthMode = WidthMode_Expand
showButton.fontSize = buttonFontSize

var copyButton = newButton("Copy")
copyButton.widthMode = WidthMode_Expand
copyButton.fontSize = buttonFontSize

var typeButton = newButton("Type")
typeButton.widthMode = WidthMode_Expand
typeButton.fontSize = buttonFontSize

block:
    var tempLayout = newLayoutContainer(Layout_Horizontal)

    tempLayout.add(saveButton)
    tempLayout.add(updateButton)
    tempLayout.add(deleteButton)

    layout.add(newSeparator())
    layout.add(newSeparator())
    layout.add(tempLayout)

block:
    var tempLayout = newLayoutContainer(Layout_Horizontal)

    tempLayout.add(listButton)
    tempLayout.add(showButton)
    tempLayout.add(copyButton)
    tempLayout.add(typeButton)

    layout.add(tempLayout)

window.add(layout)


#! CALLBACKS FOR BUTTONS
saveButton.onClick = proc(event: ClickEvent) =
    var mkey = masterkeyPrompt()

    if mkey == "":
        showSuccess("Cancelled the operation.")
        return
    
    try:
        verifyMasterkey(mkey)
    except InvalidMasterkeyError:
        showError("Invalid masterkey.")
        return

    var
        name = passNameWidget.text
        password = passwordPrompt()
    
    if password == "":
        showSuccess("Cancelled the operation.")
        return

    try:
        insertEntry(mkey, Entry(name: name, password: password))
    except InvalidMasterkeyError:
        showError("Invalid masterkey.")
        return
    except NameIsTooShortError:
        showError("Name is too short (minimum length is $1)." % intToStr(nameMinLength))
        return
    except EntryAlreadyExistsError:
        showError("Entry with name $1 already exists (click Update if you want to update the entry)." % name)
        return
    except PasswordContainsBadCharacterError:
        showError("Password or its name contains illegal character. (allowed characters are $1)." % alphabet.join(""))
        return
    
    showSuccess("Saved new entry.")

updateButton.onClick = proc(event: ClickEvent) = 
    var mkey = masterkeyPrompt()
    
    if mkey == "":
        showSuccess("Cancelled the operation.")
        return
    
    try:
        verifyMasterkey(mkey)
    except InvalidMasterkeyError:
        showError("Invalid masterkey.")
        return
    
    var
        name = passNameWidget.text
        password = passwordPrompt()
    
    if password == "":
        showSuccess("Cancelled the operation.")
        return

    try:
        deleteEntry(mkey, name)
        insertEntry(mkey, Entry(name: name, password: password))
    except InvalidMasterkeyError:
        showError("Invalid masterkey.")
        return
    except NameIsTooShortError:
        showError("Name is too short (minimum length is $1)." % intToStr(nameMinLength))
        return
    except EntryNotFoundError:
        showError("Entry with name $1 was not found (click Save if you want to insert a new entry)." % name)
        return
    except PasswordContainsBadCharacterError:
        showError("Password or its name contains illegal character. (allowed characters are $1)." % alphabet.join(""))
        return
    
    showSuccess("Updated the old entry.")

deleteButton.onClick = proc(event: ClickEvent) = 
    var 
        mkey = masterkeyPrompt()
        name = passNameWidget.text
    
    if mkey == "":
        showSuccess("Cancelled the operation.")
        return
    
    try:
        verifyMasterkey(mkey)
    except InvalidMasterkeyError:
        showError("Invalid masterkey.")
        return

    try:
        deleteEntry(mkey, name)
    except InvalidMasterkeyError:
        showError("Invalid masterkey.")
        return
    except NameIsTooShortError:
        showError("Name is too short (minimum length is $1)." % intToStr(nameMinLength))
        return
    except EntryNotFoundError:
        showError("Entry with name $1 was not found (click Save if you want to insert a new entry)." % name)
        return
    
    showSuccess("Deleted the entry.")
    
listButton.onClick = proc(event: ClickEvent) = 
    var 
        mkey = masterkeyPrompt()
    
    if mkey == "":
        showSuccess("Cancelled the operation.")
        return
    
    try:
        verifyMasterkey(mkey)
    except InvalidMasterkeyError:
        showError("Invalid masterkey.")
        return

    try:
        var s = readStorage(mkey)
        var text = "Stored passwords(names are shown):\n"
        for e in s.entries:
            text.add(e.name & "\n")
        
        showSuccess(text)

    except InvalidMasterkeyError:
        showError("Invalid masterkey.")
        return

showButton.onClick = proc(event: ClickEvent) = 
    var 
        mkey = masterkeyPrompt()
        name = passNameWidget.text
    
    if mkey == "":
        showSuccess("Cancelled the operation.")
        return
    
    try:
        verifyMasterkey(mkey)
    except InvalidMasterkeyError:
        showError("Invalid masterkey.")
        return

    try:
        var e = getEntry(mkey, name)
        show(e.name, e.password)
    except InvalidMasterkeyError:
        showError("Invalid masterkey.")
        return
    except NameIsTooShortError:
        showError("Name is too short (minimum length is $1)." % intToStr(nameMinLength))
        return
    except EntryNotFoundError:
        showError("Entry with name $1 was not found (click Save if you want to insert a new entry)." % name)
        return

copyButton.onClick = proc(event: ClickEvent) = 
    var 
        mkey = masterkeyPrompt()
        name = passNameWidget.text
    
    if mkey == "":
        showSuccess("Cancelled the operation.")
        return
    
    try:
        verifyMasterkey(mkey)
    except InvalidMasterkeyError:
        showError("Invalid masterkey.")
        return

    try:
        var e = getEntry(mkey, name)
        var es = execCmd("echo -n '$1' | xclip -selection clipboard" % e.password)
        if es == 0:
            showSuccess("Copied the password into the clipboard.")
        else:
            showError("Could not copy the password. Check if xclip is installed.")
    except InvalidMasterkeyError:
        showError("Invalid masterkey.")
        return
    except NameIsTooShortError:
        showError("Name is too short (minimum length is $1)." % intToStr(nameMinLength))
        return
    except EntryNotFoundError:
        showError("Entry with name $1 was not found (click Save if you want to insert a new entry)." % name)
        return

var timer: Timer
var timerState = 0
var password = ""

proc tickTimer(event: TimerEvent) = 
    typeButton.text = intToStr(5 - timerState)
    timerState += 1

    if timerState == 6:
        var code = execCmd("xdotool type '$1'" % password)
        if code == 0:
            showSuccess("Typed the password.")
        else:
            showError("Could not type the password. Check if xdotool is installed")
            
        
        timer.stop()
        timerState = 0
        typeButton.text = "Type"

typeButton.onClick = proc(event: ClickEvent) = 
    if timerState != 0:
        return

    var 
        mkey = masterkeyPrompt()
        name = passNameWidget.text
    
    if mkey == "":
        showSuccess("Cancelled the operation.")
        return
    
    try:
        verifyMasterkey(mkey)
    except InvalidMasterkeyError:
        showError("Invalid masterkey.")
        return

    try:
        var e = getEntry(mkey, name)
        password = e.password
        var tm: TimerEvent
        tickTimer(tm)
        timer = startRepeatingTimer(1000, tickTimer)
    except InvalidMasterkeyError:
        showError("Invalid masterkey.")
        return
    except NameIsTooShortError:
        showError("Name is too short (minimum length is $1)." % intToStr(nameMinLength))
        return
    except EntryNotFoundError:
        showError("Entry with name $1 was not found (click Save if you want to insert a new entry)." % name)
        return

    



initStorage()
window.show()
app.run()