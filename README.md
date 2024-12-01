# PowerShell.Module.ExpressVPN

A Module to Control ExpressVPN Networking




### Implementing A Custom Protocol

I found that when I implement a tool that it using a browser, with a web interface, it is very useful to implement my own custom protocol to start application from custom links like ```testprotocol://``` . For example, ```foobar://dothis``` can be mapped to a certain application. Widely used applications such as Zoom, Slack, and custom VPN clients register their custom protocols using this same mechanism. For instance:
- **Zoom** uses `zoommtg://`.
- **Slack** uses `slack://`.

This setup allows a web browser, application, or script to invoke ExpressVPN directly via URLs like `vpn://connect`, passing commands or parameters to control the VPN client.

FIrst, we need to add The `"URL Protocol"=""` entry in the Windows Registry. When Windows processes URLs, it looks for the following:
1. The protocol part of the URL (e.g., `vpn` in `vpn://`).
2. A matching key in `HKEY_CLASSES_ROOT` (e.g., `HKEY_CLASSES_ROOT\expressvpn`).
3. The presence of the `"URL Protocol"` entry confirms that the key corresponds to a URL scheme rather than a file type or other association.

For the **VPN** , I have created a custom protocol named ```vpn``` . Here's how to do it:
1. Open `regedit`.
2. Create a new key under `HKEY_CLASSES_ROOT` (e.g., `HKEY_CLASSES_ROOT\vpn`).
3. Add a default value: `@="URL:vpn Protocol"`.
4. Add the `"URL Protocol"=""` value.
5. Add a `shell\open\command` key, and set its default value to a test executable (e.g., `notepad.exe`).

```plaintext
[HKEY_CLASSES_ROOT\vpn]
@="URL:vpn Protocol"
"URL Protocol"=""

[HKEY_CLASSES_ROOT\vpn\shell\open\command]
@="notepad.exe"
```
- Save the changes and test by typing `vpn://` in a browser or `Run` dialog.
- Without `"URL Protocol"=""`, Windows will not recognize `vpn://`.


### Encoding a command for Registry Use
If you are encoding this for a registry value in `hex(2):` format, you would separate each Unicode code point with a comma, as shown above.



#### Function to Convert a String to Unicode Hexadecimal
```powershell
function Convert-ToUnicodeHex {
    param (
        [Parameter(Mandatory)]
        [string]$InputString
    )

    $unicodeHex = ""
    foreach ($char in $InputString.ToCharArray()) {
        # Convert each character to its Unicode code point in hexadecimal format
        $unicodeHex += "{0:X4}," -f [int][char]$char
    }

    # Trim the trailing comma and return the result
    return $unicodeHex.TrimEnd(',')
}

# Example usage
$string = "ExpressVPN"
$encodedString = Convert-ToUnicodeHex -InputString $string
Write-Output $encodedString
```



## vpn_protocol.reg registry file

**Purpose of the Registry File**

1. Define a Custom Protocol: This registry entry lets ExpressVPN handle URLs with the `vpn://` scheme.
2. Associate an Icon: Provides a visual representation for the protocol in file dialogs or other UI elements.
3. Enable Command Execution: Specifies the exact application and parameters to invoke when the protocol is triggered.

## vpnshim application

I have made the vpn shim application to act as a shim when invoking ```vpn://<action>``` the goal is to parse the url, extract the command and call ExpressVPN Client as an administrator.

Exmaples:

- [VPN Disconnect](vpn://disconnect)
- [ConnectVPN to Frankfurt](vpn://connect+7)
- [ConnectVPN to Frankfurt](vpn://connect+8) 

