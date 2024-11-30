# PowerShell.Module.ExpressVPN

A Module to Control ExpressVPN Networking



## vpnshim 


Function to Convert a String to Unicode Hexadecimal

To convert a string into an encoded Unicode string in hexadecimal format in PowerShell, you can use the following function:

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



This registry file defines a custom protocol handler for ExpressVPN. Here's a breakdown of what each section does:

### 1. **Protocol Definition**:
```plaintext
[HKEY_CLASSES_ROOT\vpn]
@="URL:ExpressVPN Protocol"
"URL Protocol"=""
```
- This creates a new registry entry for a protocol named `vpn`.
- The `@="URL:ExpressVPN Protocol"` sets the display name for the protocol.
- The `"URL Protocol"=""` entry designates it as a protocol handler, allowing the OS to interpret `vpn://` URLs and invoke the associated application.

### 2. **Default Icon**:
```plaintext
[HKEY_CLASSES_ROOT\vpn\DefaultIcon]
@="\"C:\\Program Files (x86)\\ExpressVPN\\expressvpn-ui\\ExpressVPN.exe,1\""
```
- This sets the icon for the `vpn` protocol.
- The icon is located in the file `ExpressVPN.exe` at `C:\Program Files (x86)\ExpressVPN\expressvpn-ui`. The `,1` refers to the second icon resource embedded in the executable (icon resources are zero-indexed).

### 3. **Shell Commands**:
```plaintext
[HKEY_CLASSES_ROOT\vpn\shell]

[HKEY_CLASSES_ROOT\vpn\shell\open]

[HKEY_CLASSES_ROOT\vpn\shell\open\command]
@=hex(2):...
```
- These entries define the action that occurs when the protocol is invoked.

### 4. **Command Execution**:
```plaintext
[HKEY_CLASSES_ROOT\vpn\shell\open\command]
@=hex(2):22,00,43,00,3a,00,...
```
- This specifies the command to execute when a URL with the `expressvpn://` scheme is opened.
- The `hex(2):` value represents a Unicode string in hexadecimal format. When decoded, it translates to the command:

```plaintext
"C:\Program Files (x86)\ExpressVPN\expressvpn-ui\ExpressVPN.exe" "%1"
```

- This command:
  - Launches `ExpressVPN.exe` located in the specified path.
  - Passes the URL (or other parameters) to the application as `%1`.
  
### **Purpose of the Registry File**:
1. **Define a Custom Protocol**: This registry entry lets ExpressVPN handle URLs with the `expressvpn://` scheme.
2. **Associate an Icon**: Provides a visual representation for the protocol in file dialogs or other UI elements.
3. **Enable Command Execution**: Specifies the exact application and parameters to invoke when the protocol is triggered.

### **Use Case**:
- This setup allows a web browser, application, or script to invoke ExpressVPN directly via URLs like `expressvpn://connect`, passing commands or parameters to control the VPN client.


To convert a string into an encoded Unicode string in hexadecimal format in PowerShell, you can use the following function:

### Function to Convert a String to Unicode Hexadecimal
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

### Example Output
If you input the string `ExpressVPN`, the output would be:
```
0045,0078,0070,0072,0065,0073,0073,0056,0050,004E
```

### Explanation
1. **`ToCharArray()`**: Breaks the string into individual characters.
2. **`[int][char]$char`**: Converts each character to its Unicode code point (decimal).
3. **`"{0:X4}"`**: Formats the number as a 4-digit hexadecimal value.
4. **Joining**: Adds commas between the hexadecimal values for registry compatibility.

### Encoding for Registry Use
If you are encoding this for a registry value in `hex(2):` format, you would separate each Unicode code point with a comma, as shown above.