# Nimpass - GUI password manager written in Nim
![](https://i.ibb.co/5kYQXq7/image.png)

Nimpass is a GUI password manager developed to run on Linux systems. It stores passwords in an encrypted form in a single file `$HOME/.nimpass-passwords.txt`. AES algorithm is used for encryption.

When you first run the app - it asks you to create a masterkey. It will be used to encrypt and decrypt passwords. Without the masterkey, the passwords can't be accessed.

## Dependencies:
- NiGui - https://github.com/simonkrauter/NiGui/tree/master
- NimAES - https://github.com/jangko/nimAES
- xclip
- xdotool
- zenity 