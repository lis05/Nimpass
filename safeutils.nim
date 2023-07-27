import nimAES
import strutils
import std/sha1

var aes = initAES()
const fillCharacter* = 0.char

proc growKey(key: var string) =
    for i in 0..<32:
        if key.len mod 32 == 0:
            break
        key.add(key[i])

proc growData(data: var string) =
    while data.len mod 16 != 0:
        data.add(fillCharacter)

proc encryptText*(key, data: string): string =
    var 
        key = key
        data = data
    
    if find(data, fillCharacter) != -1:
        raise newException(Exception, "data to encrypt can't include fillCharacter '$1' " % $fillCharacter)

    growKey(key)
    growData(data)

    if aes.setEncodeKey(key):
        for i in countup(0, data.len - 1, 16): 
            result.add(aes.encryptECB(data[i..i+15]))
    else:
        raise newException(Exception, "aes.SetEncodeKey failed")
    
    assert result.len mod 16 == 0

    return result

proc decryptText*(key, data: string): string =
    var 
        key = key
        data = data
    
    assert data.len mod 16 == 0

    growKey(key)
    
    if aes.setDecodeKey(key):
        for i in countup(0, data.len - 1, 16):
            result.add(aes.decryptECB(data[i..i+15]))
    else:
        raise newException(Exception, "aes.setDecodeKey failed")
    
    return result.strip(chars = {fillCharacter})

proc hashsum*(data: string): string =
    return $secureHash($secureHash(data))