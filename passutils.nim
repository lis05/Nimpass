import os
#import system/io          # for some reason this just stopped working. idk why, but let it be
import strutils
import dialogs
import safeutils

const nameMinLength* = 2
let filename = getEnv("HOME") / ".nimpass-passwords.txt"

type 
    Entry* = object
        name*: string
        password*: string

    Storage = object 
        masterkeySum: string
        len: int
        entries*: seq[Entry]
    
    InvalidMasterkeyError* =                object of ValueError
    EntryNotFoundError* =                   object of ValueError
    EntryAlreadyExistsError* =              object of ValueError
    NameIsTooShortError* =                  object of ValueError
    PasswordContainsBadCharacterError* =    object of ValueError


proc toBytes(s: string): seq[byte] =
    for i in 0..<s.len:
        result.add(byte(s[i]))
    return result

proc fromBytes(s: seq[byte]): string = 
    for i in 0..<s.len:
        result.add(char(s[i]))
    return result


proc writeLen(f: File, n: int) =
    assert n <= 0xFFFF

    var byte1 = n shr 8
    var byte2 = n and 0xFF

    assert f.writeBytes([byte(byte1), byte(byte2)], 0, 2) == 2

proc readLen(f: File): int = 
    var bytes: array[2, byte]
    assert f.readBytes(bytes, 0, 2) == 2

    return (int(bytes[0]) shl 8) + int(bytes[1])

proc writeString(f: File, s: string) =
    writeLen(f, s.len)
    assert f.writeBytes(toBytes(s), 0, s.len) == s.len

proc readString(f: File): string = 
    var len = readLen(f)
    if len == 0:
        return ""

    var bytes = newSeq[byte](len)
    assert f.readBytes(bytes, 0, len) == len

    return fromBytes(bytes)


proc writeMasterkey(f: File, s: string) = 
    writeString(f, s)

proc readMasterkey(f: File): string =
    return readString(f)

proc writeEntry(f: File, e: Entry) =
    writeString(f, e.name)
    writeString(f, e.password)

proc readEntry(f: File): Entry = 
    result.name = readString(f)
    result.password = readString(f)

    return result


proc decryptStorage(mkey: string, s: var Storage) = 
    for (_, e) in mpairs(s.entries):
        e.name = decryptText(mkey, e.name)
        e.password = decryptText(mkey, e.password)

proc encryptStorage(mkey: string, s: var Storage) = 
    for (_, e) in mpairs(s.entries):
        e.name = encryptText(mkey, e.name)
        e.password = encryptText(mkey, e.password)


proc writeStorage(mkey: string, s: Storage) =
    var s = s
    encryptStorage(mkey, s)

    var f = open(filename, fmWrite)

    writeMasterkey(f, s.masterkeySum)
    writeLen(f, s.len)

    for e in s.entries:
       writeEntry(f, e)
    f.close()

proc readStorage*(mkey: string): Storage =
    var f = open(filename)

    result.masterkeySum = readMasterkey(f)
    result.len = readLen(f)
    for i in 0..<result.len:
        result.entries.add(readEntry(f))

    f.close()
    decryptStorage(mkey, result)

    return result


proc verifyMasterkey*(mkey: string) = 
    var f = open(filename)
    var key = readString(f)
    f.close()
    if hashsum(mkey) != key:
        raise newException(InvalidMasterkeyError, "Invalid masterkey.")

proc initStorage*() =
    if fileExists(filename):
        return

    var masterkey = initStoragePrompt().strip(chars = {'\n'})
    if masterkey == "":
        echo "Failed to initialize storage."
        quit(1)

    var s: Storage
    s.masterkeySum = hashsum(masterkey)
    s.len = 0

    writeStorage(masterkey, s)

    echo "Successfully initialized storage: $1" % filename

proc checkNameLength(name: string) = 
    if name.len < nameMinLength:
        raise newException(NameIsTooShortError, "Name $1 is too short" % name)

proc checkPassword(pass: string) = 
    for c in pass:
        if c notin alphabet:
            raise newException(PasswordContainsBadCharacterError, "Password contains illegal character.")

proc getEntry*(mkey: string, name: string): Entry = 
    verifyMasterkey(mkey)
    checkNameLength(name)

    var s = readStorage(mkey)
    for e in s.entries:
        if e.name == name:
            return e
    
    raise newException(EntryNotFoundError, "Entry with name $1 was not found" % name)

proc checkEntry*(mkey: string, name: string): bool = 
    try:
        discard getEntry(mkey, name)
    except EntryNotFoundError:
        return false

    return true

proc insertEntry*(mkey: string, e: Entry) = 
    verifyMasterkey(mkey)
    checkNameLength(e.name)
    checkPassword(e.password)
    checkPassword(e.name)

    
    var exists = checkEntry(mkey, e.name)
    if exists:
        raise newException(EntryAlreadyExistsError, "Entry with name $1 already exists." % e.name)
    
    var s = readStorage(mkey)
    s.len += 1
    s.entries.add(e)


    writeStorage(mkey, s)

proc deleteEntry*(mkey: string, name: string) = 
    verifyMasterkey(mkey)
    checkNameLength(name)

    
    var exists = checkEntry(mkey, name)
    if not exists:
        raise newException(EntryNotFoundError, "Entry with name $1 was not found." % name)
    
    var s = readStorage(mkey)
    s.len -= 1

    var pos = -1
    for (i, e) in pairs(s.entries):
        if e.name == name:
            pos = i
            break
    assert pos != -1

    s.entries.delete(pos)

    writeStorage(mkey, s)
