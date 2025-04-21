# ConvertTo-Base64String
```
ConvertTo-Base64String [-InputString] <String> [<CommonParameters>]
```
## Synopsis
Converts a string into base64.
## Description
Uses UTF8Encoding.GetBytes to convert the input string into a byte array, then passes it to System.Convert.ToBase64String to return the base64-encoded string.
## Parameters
### -InputString
The string to convert to base64.
```yaml
Type: String
Required: true
Position: 1
Default value: 
Accept pipeline input: true (ByValue)
```
## Examples
### Example 1
```powershell
PS> ConvertTo-Base64String "Example"

RXhhbXBsZQ==
```
### Example 2
```powershell
PS> @('example123', 'example456') | ConvertTo-Base64String

ZXhhbXBsZTEyMw==
ZXhhbXBsZTQ1Ng==
```
# Get-DocumentationIP
```
Get-DocumentationIP [[-IPVersion] <String>] [[-Count] <Int32>] [<CommonParameters>]
```
## Synopsis
Returns an IP address that is suitable for use in documentation.
## Description
Returns a random IP address from the reserved address blocks described in RFC 5737 (for IPv4) or RFC 3849 (for IPv6).
## Parameters
### -IPVersion
The IP version(s) allowed for the IP address. Valid values are "4", "6", or "Both". The default is "4".
```yaml
Type: String
Required: false
Position: 1
Default value: 4
Accept pipeline input: true (ByValue)
```
### -Count
Specifies the number of IP addresses to return. The default is 1.
```yaml
Type: Int32
Required: false
Position: 2
Default value: 1
Accept pipeline input: true (ByValue)
```
## Examples
### Example 1
```powershell
PS> Get-DocumentationIP
203.0.113.194

```
### Example 2
```powershell
PS> Get-DocumentationIP -IPVersion 6
2001:0DB8:164E:C268:CBD9:91FE:A7A3:392A

```
### Example 3
```powershell
PS> Get-DocumentationIP -IPVersion Both -Count 5
2001:0DB8:C4EB:B3F9:5605:977C:2CFC:DE8A
2001:0DB8:300C:F09B:B032:A1CC:2DE3:D5DE
198.51.100.54
203.0.113.68
2001:0DB8:B846:485:FD81:91AA:60BA:CA97

```
## Related Links
- https://datatracker.ietf.org/doc/html/rfc5737
- https://datatracker.ietf.org/doc/html/rfc3849
# Get-DocumentationPhoneNumber
```
Get-DocumentationPhoneNumber [[-Format] <String>] [[-Specificity] <String>] [[-Count] <Int32>] [<CommonParameters>]
```
## Synopsis
Returns a telephone number that is suitable for use in documentation.
## Description
Returns a random North American Numbering Plan (NANP, country code "+1") telephone number from the reserved range described in ATIS-0300115.
## Parameters
### -Format
The format for the telephone number. Valid values are "E.164", "Spaces", "Hyphens", or "US". The default is "E.164".
```yaml
Type: String
Required: false
Position: 1
Default value: E.164
Accept pipeline input: true (ByValue)
```
### -Specificity
Whether to include the area code or the country code in the telephone number. Valid values are "Country", "Area", or "Local". The default is "Country".
```yaml
Type: String
Required: false
Position: 2
Default value: Country
Accept pipeline input: true (ByValue)
```
### -Count
Specifies the number of telephone numbers to return. The default is 1.
```yaml
Type: Int32
Required: false
Position: 3
Default value: 1
Accept pipeline input: true (ByValue)
```
## Examples
### Example 1
```powershell
PS> Get-DocumentationPhoneNumber
+18725550194

```
### Example 2
```powershell
PS> Get-DocumentationPhoneNumber -Format US
+1 (313) 555-0193

```
### Example 3
```powershell
PS> Get-DocumentationPhoneNumber -Format US -Specificity Area -Count 5
(767) 555-0179
(985) 555-0168
(345) 555-0160
(803) 555-0190
(706) 555-0177

```
## Related Links
- https://www.nationalnanpa.com/pdf/NRUF/ATIS-0300115.pdf
- https://en.wikipedia.org/wiki/555_(telephone_number)
# Get-ExtendedFileProperty
```
Get-ExtendedFileProperty [-Path] <String> [<CommonParameters>]
```
## Synopsis
Gets a file's extended file properties.
## Description
Creates a new Shell Folder object from the file's parent folder path. Then creates a FolderItem object for the file. Finally, loops through all indices between 0 and 512 and returns all non-null properties for that file.
## Parameters
### -Path
The path to the file to get extended file properties for.
```yaml
Type: String
Required: true
Position: 1
Default value: 
Accept pipeline input: true (ByValue)
```
## Examples
### Example 1
```powershell
PS> Get-ExtendedFileProperty example.mp4

FileName    PropertyName      PropertyValue
--------    ------------      -------------
example.mp4 Name              example.mp4
example.mp4 Size              11.3 MB
example.mp4 Item type         MP4 Video File (VLC)
example.mp4 Date modified     12/25/2021 11:11 PM
example.mp4 Date created      12/26/2021 12:04 AM
example.mp4 Date accessed     12/26/2021 12:37 AM
example.mp4 Attributes        A
example.mp4 Perceived type    Video

(...)
```
### Example 2
```powershell
PS> Get-ExtendedFileProperty example.mp4 | Where-Object PropertyName -like 'Date*'

FileName    PropertyName  PropertyValue
--------    ------------  -------------
example.mp4 Date modified 12/25/2021 11:11 PM
example.mp4 Date created  12/26/2021 12:04 AM
example.mp4 Date accessed 12/26/2021 12:37 AM
```
### Example 3
```powershell
PS> @('example.mp4', 'example2.mp4') | Get-ExtendedFileProperty | Where-Object PropertyName -in 'Size', 'Length', 'Frame width', 'Frame height', 'Total bitrate'

FileName     PropertyName  PropertyValue
--------     ------------  -------------
example.mp4  Size          11.3 MB
example.mp4  Length        00:01:27
example.mp4  Frame height  352
example.mp4  Frame width   624
example.mp4  Total bitrate 1091kbps
example2.mp4 Size          4.80 MB
example2.mp4 Length        00:00:41
example2.mp4 Frame height  720
example2.mp4 Frame width   1280
example2.mp4 Total bitrate 952kbps
```
# Get-HelpAsMarkdown
```
Get-HelpAsMarkdown [-Cmdlet] <String> [<CommonParameters>]
```
## Synopsis
A minimal wrapper around Get-Help that outputs a markdown string.
## Description
Extracts the syntax, synopsis, description, parameters, and examples for a command from Get-Help and converts the output to markdown. This command is intended to generate the minimum viable markdown documentation for a command.
## Parameters
### -Cmdlet
The cmdlet to generate markdown documentation for.
```yaml
Type: String
Required: true
Position: 1
Default value: 
Accept pipeline input: true (ByValue)
```
## Examples
### Example 1
```powershell
PS> Get-HelpAsMarkdown Get-Date

# Get-Date

(...)

## Synopsis
Gets the current date and time.
## Description
The `Get-Date` cmdlet gets a DateTime object that represents the current date or a date that you specify. `Get-Date` can (...)

(...)
```
### Example 2
```powershell
PS> @('Get-Date', 'Format-Table') | Get-HelpAsMarkdown

# Get-Date

(...)

## Synopsis
Gets the current date and time.
## Description
The `Get-Date` cmdlet gets a DateTime object that represents the current date or a date that you specify. `Get-Date` can (...)

(...)

# Format-Table

(...)

## Synopsis
Formats the output as a table.
## Description
The `Format-Table` cmdlet formats the output of a command as a table with the selected properties of the object in each (...)

(...)
```
### Example 3
```powershell
PS> @('Get-Date', 'Format-Table') | Get-HelpAsMarkdown | Out-File -FilePath ./MyDocumentation.md

Generates a file called "MyDocumentation.md" which contains the markdown documentation for the "Get-Date" and "Format-Table" commands.
```
### Example 4
```powershell
PS> Get-Command -Module ArdisUtilities | Get-HelpAsMarkdown | Out-File -FilePath ./ArdisUtilities.md

Generates a file called "ArdisUtilities.md" which contains the markdown documentation for all the commands in the "ArdisUtilities" module.
```
# Get-SizeDurationRatio
```
Get-SizeDurationRatio [-Path] <String> [<CommonParameters>]
```
## Synopsis
Calculates a file's size (in KB) divided by its duration (in seconds).
## Description
Creates a new Shell Folder object from the file's parent folder path. Then creates a FolderItem object for the file. Finally, uses the FolderItem's extended properties to fetch the duration (if it exists) and calculate the ratio.
## Parameters
### -Path
The path to the file to calculate the size/duration ratio for.
```yaml
Type: String
Required: true
Position: 1
Default value: 
Accept pipeline input: true (ByValue)
```
## Examples
### Example 1
```powershell
PS> Get-SizeDurationRatio ./example-video.mp4

Name                          Size Duration            Ratio
----                          ---- --------            -----
example-video.mp4 195746.022460938      736 265.959269648013
```
### Example 2
```powershell
PS> @('./example-audio.mp3', './example-video.mp4') | Get-SizeDurationRatio

Name                          Size Duration            Ratio
----                          ---- --------            -----
example-audio.mp3     5165.4140625      132 39.1319247159091
example-video.mp4 195746.022460938      736 265.959269648013
```
### Example 3
```powershell
PS> Get-SizeDurationRatio

cmdlet Get-SizeDurationRatio at command pipeline position 1
Supply values for the following parameters:
Path: ./example-video.mp4

Name                          Size Duration            Ratio
----                          ---- --------            -----
example-video.mp4 195746.022460938      736 265.959269648013
```
### Example 4
```powershell
PS> Get-SizeDurationRatio ./example-document.txt

Get-SizeDurationRatio: example-document.txt does not have a duration.
```
### Example 5
```powershell
PS> @('./example-audio.mp3', './example-video.mp4', './example-document.txt') | Get-SizeDurationRatio

Name                          Size Duration            Ratio
----                          ---- --------            -----
example-audio.mp3     5165.4140625      132 39.1319247159091
example-video.mp4 195746.022460938      736 265.959269648013
Get-SizeDurationRatio: example-document.txt does not have a duration.
```
# Get-StringHash
```
Get-StringHash [-InputString] <String> [[-Algorithm] <String>] [[-Encoding] <String>] [<CommonParameters>]
```
## Synopsis
Hashes a string.
## Description
Converts a string into bytes, then hashes those bytes and outputs the hash as a string.
## Parameters
### -InputString
The string to hash.
```yaml
Type: String
Required: true
Position: 1
Default value: 
Accept pipeline input: true (ByValue)
```
### -Algorithm
The hashing algorithm to use. Supported algorithms are "SHA1", "SHA256", "SHA384", "SHA512", and "MD5".
```yaml
Type: String
Required: false
Position: 2
Default value: SHA1
Accept pipeline input: false
```
### -Encoding
The encoding format for the hash. Supported values are "hex" and "base64".
```yaml
Type: String
Required: false
Position: 3
Default value: hex
Accept pipeline input: false
```
## Examples
### Example 1
```powershell
PS> Get-StringHash Example

Algorithm Hash                                     InputString Encoding
--------- ----                                     ----------- --------
SHA1      0F01ED56A1E32A05E5EF96E4D779F34784AF9A96 Example     hex
```
### Example 2
```powershell
PS> Get-StringHash Example -Algorithm SHA256

Algorithm Hash                                                             InputString Encoding
--------- ----                                                             ----------- --------
SHA256    D029F87E3D80F8FD9B1BE67C7426B4CC1FF47B4A9D0A8461C826A59D8C5EB6CD Example     hex
```
### Example 3
```powershell
PS> Get-StringHash Example -Algorithm SHA256 -Encoding base64

Algorithm Hash                                         InputString Encoding
--------- ----                                         ----------- --------
SHA256    0Cn4fj2A+P2bG+Z8dCa0zB/0e0qdCoRhyCalnYxets0= Example     base64
```
### Example 4
```powershell
PS> @('Example1', 'Example2') | Get-StringHash

Algorithm Hash                                     InputString Encoding
--------- ----                                     ----------- --------
SHA1      556A3BABEA53F0F9A2DEDB8F6A5C472FC3521615 Example1    hex
SHA1      146525784A68F39E8BCC0EC7E11498C3B7B402B5 Example2    hex
```
# Get-SubresourceIntegrity
```
Get-SubresourceIntegrity [-Subresource] <String> [[-Algorithm] <String>] [<CommonParameters>]
```
## Aliases
```
sri
```
## Synopsis
Gets the hash of a file for use in a subresource integrity (SRI) check.
## Description
Accepts either a local file path OR a URL to a file as input. If the input is a URL, downloads the file.Calculates the hash of the given file. Then outputs the hash in base64 with an algorithm prefix,so the hash is ready to be used in a subresource integrity (SRI) check.
## Parameters
### -Subresource
A local file OR a URL to a file to calculate the integrity hash for.
```yaml
Type: String
Required: true
Position: 1
Default value: 
Accept pipeline input: true (ByValue)
```
### -Algorithm
The hashing algorithm to use. Must be 'SHA256', 'SHA384', or 'SHA512'.
```yaml
Type: String
Required: false
Position: 2
Default value: SHA512
Accept pipeline input: false
```
## Examples
### Example 1
```powershell
PS> Get-SubresourceIntegrity ./example.js

Subresource  Integrity
-----------  ---------
./example.js sha512-X/YkDZyjTf4wyc2Vy16YGCPHwAY8rZJY+POgokZjQB2mhIRFJCckEGc6YyX9eNsPfn0PzThEuNs+uaomE5CO6A==
```
### Example 2
```powershell
PS> Get-SubresourceIntegrity "https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/js/bootstrap.bundle.min.js" -Algorithm SHA384

Subresource                                                                  Integrity
-----------                                                                  ---------
https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/js/bootstrap.bundle.min.js sha384-C6RzsynM9kWDrMNeT87bh95OGNyZPhcTNXj1NW7RuBCsyN/o0jlpcV8Qyq46cDfL
```
### Example 3
```powershell
PS> @('./example1.js', './example2.js', './example3.js') | Get-SubresourceIntegrity

Subresource   Integrity
-----------   ---------
./example1.js sha512-X/YkDZyjTf4wyc2Vy16YGCPHwAY8rZJY+POgokZjQB2mhIRFJCckEGc6YyX9eNsPfn0PzThEuNs+uaomE5CO6A==
./example2.js sha512-UxkBbtNVXoNNNOwpKb3EdOtjmGNg3YbF6dq3ns6iPdrcy/WxOz+atgbe8USrqZk8vpKu4O2Rdw3U+ctPgcgwZg==
./example3.js sha512-f0Km8/mTw5HtTOWjPoYhh+SCxl7GCgdVE+SvPRzHqNUzzt+QpXTevZzqFC5KKHXSbMny5VR9/qadHYSGluNDEw==
```
## Related Links
- https://www.w3.org/TR/SRI/
- https://developer.mozilla.org/en-US/docs/Web/Security/Subresource_Integrity
# Invoke-RandomFile
```
Invoke-RandomFile [-FileCount <Int32>] [-FileCategory <String>] [-SearchFolder <String>] [<CommonParameters>]
```
## Synopsis
Selects and opens a random file in the current directory.
## Description
Recursively scan the current directory and subdirectories for all file paths, and record it into a text cache file in the same root directory. Then pick a random line or lines from the text cache file that meet the file extension requirements. Finally, call Invoke-Item on each of the random files selected.
## Parameters
### -FileCount
The number of files to select and invoke. Must be an integer greater than 0. Default value is 1.
```yaml
Type: Int32
Required: false
Position: named
Default value: 1
Accept pipeline input: false
```
### -FileCategory
The high-level category of file to select. Valid values are "all", "video", "audio", "image", and "document".Common file extensions for each file category are hardcoded in the function. The default value is "all".
```yaml
Type: String
Required: false
Position: named
Default value: all
Accept pipeline input: false
```
### -SearchFolder
The file path to a specific subfolder to open the random file from. Omitting this parameter will opena random file from the same directory this command was executed in.
```yaml
Type: String
Required: false
Position: named
Default value: 
Accept pipeline input: false
```
## Examples
### Example 1
```powershell
PS> Invoke-RandomFile

Creates a file called "all-cache.txt" in the current directory, and opens a random file from this directory.
```
### Example 2
```powershell
PS> Invoke-RandomFile -FileCategory video

Creates a file called "video-cache.txt" in the current directory, and opens a random video file from this directory.
```
### Example 3
```powershell
PS> Invoke-RandomFile -FileCount 2 -FileCategory video "./path/to/subfolder"

Creates a file called "video-cache.txt" in the current directory, and opens 2 random video files from the
"./path/to/subfolder" folder.
```
# Open-HistoryFile
```
Open-HistoryFile [<CommonParameters>]
```
## Synopsis
Opens the current session's persistent history file in a text editor.
## Description
Besides the in-memory session history which can be retrieved using Get-History, the PSReadLine module alsomaintains a persistent history of commands in a text file saved on disk. This command locates this textfile using (Get-PSReadlineOption).HistorySavePath then opens it using Invoke-Item.
## Examples
### Example 1
```powershell
PS> Open-HistoryFile

Opens the default text editor on the persistent history file.
```
# Open-ParentFolder
```
Open-ParentFolder [-Command] <String> [<CommonParameters>]
```
## Synopsis
Opens the native GUI file explorer (e.g., File Explorer on Windows) in the folder that contains a command.
## Description
Uses Get-Command to determine the path to an executable, then passes the path to Split-Path to get theparent folder. Finally, opens the parent folder by passing the path as an argument to Invoke-Item.
## Parameters
### -Command
The name of the executable to open the file explorer to.
```yaml
Type: String
Required: true
Position: 1
Default value: 
Accept pipeline input: true (ByValue)
```
## Examples
### Example 1
```powershell
PS> Open-ParentFolder curl

Opens file explorer to the folder containing the curl binary.
```
# Open-TemporaryBrowser
```
Open-TemporaryBrowser [[-Browser] <String>] [-CORS] [<CommonParameters>]
```
## Synopsis
Opens a new web browser instance with a temporary profile. Optionally passes flags to the temporary instance.
## Description
Finds the full path to the web browser, then passes a temporary profile to open a new isolated instance of the application.
## Parameters
### -Browser
The web browser to open. Must be 'Brave', 'Chrome', or 'Edge'. Defaults to 'Chrome'.
```yaml
Type: String
Required: false
Position: 1
Default value: Chrome
Accept pipeline input: false
```
### -CORS
Pass the --disable-web-security flag to disable the same-origin policy, which disables CORS restrictions.
```yaml
Type: SwitchParameter
Required: false
Position: named
Default value: False
Accept pipeline input: false
```
## Examples
### Example 1
```powershell
PS> Open-TemporaryBrowser -CORS

Opens a new isolated instance of Chrome with the same-origin policy disabled.
```
# Test-TcpPort
```
Test-TcpPort [-RemoteHost] <String> [[-Port] <Int32>] [[-Timeout] <Int32>] [<CommonParameters>]
```
## Synopsis
Tests if a TCP port is open or not.
## Description
Uses System.Net.Sockets.TcpClient to connect to a given TCP port and return whether the remote host responded or not. Similar to Test-NetConnection but the timeout duration is adjustable and much smaller by default.
## Parameters
### -RemoteHost
The name of the remote host to test TCP ports against.
```yaml
Type: String
Required: true
Position: 1
Default value: 
Accept pipeline input: false
```
### -Port
The port number to test. Valid values are integers between 1 and 65535. The default value is 80.
```yaml
Type: Int32
Required: false
Position: 2
Default value: 80
Accept pipeline input: true (ByValue)
```
### -Timeout
The duration (in milliseconds) to wait for a response from the remote host. The default value is 200.
```yaml
Type: Int32
Required: false
Position: 3
Default value: 200
Accept pipeline input: false
```
## Examples
### Example 1
```powershell
PS> Test-TcpPort example.com

RemoteHost  Protocol Port PortOpen
----------  -------- ---- --------
example.com TCP      80       True
```
### Example 2
```powershell
PS> @(25, 80, 443) | Test-TcpPort example.com

RemoteHost  Protocol Port PortOpen
----------  -------- ---- --------
example.com TCP      25      False
example.com TCP      80       True
example.com TCP      443      True
```
## Related Links
- Test-Connection
- Test-NetConnection
