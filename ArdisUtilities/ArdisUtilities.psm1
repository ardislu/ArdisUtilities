#Requires -Version 7
Set-StrictMode -Version 3.0

function Invoke-RandomFile {
  <#
  .SYNOPSIS
    Selects and opens a random file in the current directory.

  .DESCRIPTION
    Recursively scan the current directory and subdirectories for all file paths, and record it into a text 
    cache file in the same root directory. Then pick a random line or lines from the text cache file that 
    meet the file extension requirements. Finally, call Invoke-Item on each of the random files selected.

  .PARAMETER FileCount
    The number of files to select and invoke. Must be an integer greater than 0. Default value is 1.

  .PARAMETER FileCategory
    The high-level category of file to select. Valid values are "all", "video", "audio", "image", and "document".
    Common file extensions for each file category are hardcoded in the function. The default value is "all".

  .PARAMETER SearchFolder
    The file path to a specific subfolder to open the random file from. Omitting this parameter will open
    a random file from the same directory this command was executed in.

  .EXAMPLE
    PS> Invoke-RandomFile

    Creates a file called "all-cache.txt" in the current directory, and opens a random file from this directory.

  .EXAMPLE
    PS> Invoke-RandomFile -FileCategory video

    Creates a file called "video-cache.txt" in the current directory, and opens a random video file from this directory.
    
  .EXAMPLE
    PS> Invoke-RandomFile -FileCount 2 -FileCategory video "./path/to/subfolder"

    Creates a file called "video-cache.txt" in the current directory, and opens 2 random video files from the
    "./path/to/subfolder" folder.
  #>

  [OutputType([System.Void])]
  [CmdletBinding(PositionalBinding = $false)] # Allows $SearchFolder to be passed from any position
  param(
    [ValidateRange(1, [Int]::MaxValue)]
    [Int]$FileCount = 1,

    [ValidateSet('all', 'video', 'audio', 'image', 'document')]
    [String]$FileCategory = 'all',

    [Parameter(ValueFromRemainingArguments)] # Allows dragging a subfolder to the shortcut to pass it as a parameter
    [ValidateScript({ Test-Path -LiteralPath $_ }, ErrorMessage = "'{0}' is not a valid path.")]
    [String]$SearchFolder
  )

  begin {
    # Define common extensions for each file category
    $videoExtensions = @('*.mp4', '*.flv', '*.m4v', '*.mkv', '*.avi', '*.webm', '*.wmv', '*.mov')
    $audioExtensions = @('*.mp3', '*.wav', '*.wma', '*.ogg', '*.m4a', '*.flac')
    $imageExtensions = @('*.jpeg', '*.jpg', '*.png', '*.gif', '*.svg', '*.tif', '*.tiff')
    $documentExtensions = @('*.txt', '*.doc', '*.docx', '*.pdf')

    # Define the folder in which this command was executed
    $rootFolder = (Get-Location).Path
  }

  process {
    switch ($FileCategory) {
      'video' { $allowedExtensions = $videoExtensions; Break }
      'audio' { $allowedExtensions = $audioExtensions; Break }
      'image' { $allowedExtensions = $imageExtensions; Break }
      'document' { $allowedExtensions = $documentExtensions; Break }
      default { $allowedExtensions = '*.*' }
    }

    if (-not($PSBoundParameters.ContainsKey('SearchFolder'))) {
      $SearchFolder = $rootFolder
    }
  
    # Caches a list of all file paths to disk for better performance on future runs. To refresh the cache, delete the .txt file
    if (-not(Test-Path -LiteralPath "$rootFolder/$FileCategory.txt")) {
      Get-ChildItem "$rootFolder/*" -Include $allowedExtensions -Recurse | Set-Content "$rootFolder/$FileCategory-cache.txt"
    }

    # Check if the cache file was successfully created. If not, that means no valid content was found.
    if (-not(Test-Path -LiteralPath "$rootFolder/$FileCategory-cache.txt")) {
      throw "No files found in the file category '$FileCategory'."
    }
  
    # Get $FileCount random files from the folder passed to the shortcut (or the command root, if no folder was passed)
    $tempFile = New-TemporaryFile # Set-Content -PassThru does not work, needs to write to file
    Get-Content "$rootFolder/$FileCategory-cache.txt" | Select-String $SearchFolder -SimpleMatch | Get-Random -Count $FileCount | Set-Content $tempFile # Set-Content is to convert the stream object into a string
    $randomFiles = Get-Content $tempFile
    Remove-Item $tempFile
  
    Invoke-Item -LiteralPath $randomFiles # Must use -LiteralPath to take special characters in file paths, like []. Can't pipe to -LiteralPath
  }
}

function ConvertTo-Base64String {
  <#
  .SYNOPSIS
    Converts a string into base64.

  .DESCRIPTION
    Uses UTF8Encoding.GetBytes to convert the input string into a byte array, then passes it to 
    System.Convert.ToBase64String to return the base64-encoded string.

  .PARAMETER InputString
    The string to convert to base64.

  .EXAMPLE
    PS> ConvertTo-Base64String "Example"

    RXhhbXBsZQ==

  .EXAMPLE
    PS> @('example123', 'example456') | ConvertTo-Base64String

    ZXhhbXBsZTEyMw==
    ZXhhbXBsZTQ1Ng==
  #>

  [OutputType([String])]
  [CmdletBinding()]
  param(
    [Parameter(Mandatory, ValueFromPipeline)]
    [String]$InputString
  )

  process {
    [System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($InputString))
  }
}

class StringHashInfo {
  [String]$Algorithm
  [String]$Hash
  [String]$InputString
}

function Get-StringHash {
  <#
  .SYNOPSIS
    Hashes a string.

  .DESCRIPTION
    Converts a string into an input stream, then passes that stream to Get-FileHash to hash the string.

  .PARAMETER InputString
    The string to hash.
  
  .PARAMETER Algorithm
    The hashing algorithm to use. Must be an algorithm accepted by Get-FileHash.

  .EXAMPLE
    PS> Get-StringHash Example

    Algorithm Hash                                     InputString
    --------- ----                                     -----------
    SHA1      0F01ED56A1E32A05E5EF96E4D779F34784AF9A96 Example

  .EXAMPLE
    PS> Get-StringHash Example -Algorithm SHA256

    Algorithm Hash                                                             InputString
    --------- ----                                                             -----------
    SHA256    D029F87E3D80F8FD9B1BE67C7426B4CC1FF47B4A9D0A8461C826A59D8C5EB6CD Example

  .EXAMPLE
    PS> @('Example1', 'Example2') | Get-StringHash

    Algorithm Hash                                     InputString
    --------- ----                                     -----------
    SHA1      556A3BABEA53F0F9A2DEDB8F6A5C472FC3521615 Example1
    SHA1      146525784A68F39E8BCC0EC7E11498C3B7B402B5 Example2
  #>

  [OutputType([StringHashInfo])]
  [CmdletBinding()]
  param(
    [Parameter(Mandatory, ValueFromPipeline)]
    [String]$InputString,

    [ValidateSet('SHA1', 'SHA256', 'SHA384', 'SHA512', 'MD5')]
    [String]$Algorithm = 'SHA1'
  )

  process {
    $stream = [System.IO.MemoryStream]::new([byte[]][char[]]$InputString)
    $fileHashObject = Get-FileHash -InputStream $stream -Algorithm $Algorithm

    [StringHashInfo] @{
      'Algorithm'   = $fileHashObject.Algorithm
      'Hash'        = $fileHashObject.Hash
      'InputString' = $InputString
    }
  }
}

class SizeDurationRatio {
  [String]$Path
  [String]$Name
  [Double]$Size
  [Double]$Duration
  [Double]$Ratio
}

$SizeDurationRatioDefaultDisplay = @{
  TypeName                  = 'SizeDurationRatio'
  DefaultDisplayPropertySet = 'Name', 'Size', 'Duration', 'Ratio'
}
Update-TypeData @SizeDurationRatioDefaultDisplay -Force

function Get-SizeDurationRatio {
  <#
  .SYNOPSIS
    Calculates a file's size (in KB) divided by its duration (in seconds).

  .DESCRIPTION
    Creates a new Shell Folder object from the file's parent folder path. Then creates a FolderItem 
    object for the file. Finally, uses the FolderItem's extended properties to fetch the duration 
    (if it exists) and calculate the ratio.

  .PARAMETER Path
    The path to the file to calculate the size/duration ratio for.

  .EXAMPLE
    PS> Get-SizeDurationRatio ./example-video.mp4 

    Name                          Size Duration            Ratio
    ----                          ---- --------            -----
    example-video.mp4 195746.022460938      736 265.959269648013

  .EXAMPLE
    PS> @('./example-audio.mp3', './example-video.mp4') | Get-SizeDurationRatio

    Name                          Size Duration            Ratio
    ----                          ---- --------            -----
    example-audio.mp3     5165.4140625      132 39.1319247159091
    example-video.mp4 195746.022460938      736 265.959269648013

  .EXAMPLE
    PS> Get-SizeDurationRatio

    cmdlet Get-SizeDurationRatio at command pipeline position 1
    Supply values for the following parameters:
    Path: ./example-video.mp4

    Name                          Size Duration            Ratio
    ----                          ---- --------            -----
    example-video.mp4 195746.022460938      736 265.959269648013

  .EXAMPLE
    PS> Get-SizeDurationRatio ./example-document.txt

    Get-SizeDurationRatio: example-document.txt does not have a duration.

  .EXAMPLE
    PS> @('./example-audio.mp3', './example-video.mp4', './example-document.txt') | Get-SizeDurationRatio

    Name                          Size Duration            Ratio
    ----                          ---- --------            -----
    example-audio.mp3     5165.4140625      132 39.1319247159091
    example-video.mp4 195746.022460938      736 265.959269648013
    Get-SizeDurationRatio: example-document.txt does not have a duration.
  #>

  [OutputType([SizeDurationRatio])]
  [CmdletBinding()]
  param(
    [Parameter(Mandatory, ValueFromPipeline)]
    [ValidateScript({ Test-Path -LiteralPath $_ }, ErrorMessage = "'{0}' is not a valid path.")]
    [String]$Path
  )

  begin {
    $shell = New-Object -ComObject Shell.Application
  }

  process {
    $resolvedPath = Resolve-Path -LiteralPath $Path
    $folderPath = Split-Path $resolvedPath
    $fileName = Split-Path $resolvedPath -Leaf

    $folderObject = $shell.NameSpace($folderPath)
    $fileObject = $folderObject.ParseName($fileName)

    $durationString = $folderObject.GetDetailsOf($fileObject, 27)

    # If the file does not have a duration, GetDetailsOf returns an empty string
    if ('' -eq $durationString) {
      $PSCmdlet.WriteError((New-Object System.Management.Automation.ErrorRecord "$fileName does not have a duration.", $null, 'InvalidData', $null))
    }
    else {
      $size = $fileObject.Size / 1KB
      $duration = [System.TimeSpan]::Parse($durationString).TotalSeconds
      $ratio = $size / $duration
  
      [SizeDurationRatio] @{
        Path     = $resolvedPath
        Name     = $fileName
        Size     = $size
        Duration = $duration
        Ratio    = $ratio
      }
    }
  }
}

class ExtendedFileProperty {
  [String]$Path
  [String]$FileName
  [Int]$PropertyIndex
  [String]$PropertyName
  [String]$PropertyValue
}

$ExtendedFilePropertyDisplay = @{
  TypeName                  = 'ExtendedFileProperty'
  DefaultDisplayPropertySet = 'FileName', 'PropertyName', 'PropertyValue'
}
Update-TypeData @ExtendedFilePropertyDisplay -Force

function Get-ExtendedFileProperty {
  <#
  .SYNOPSIS
    Gets a file's extended file properties.

  .DESCRIPTION
    Creates a new Shell Folder object from the file's parent folder path. Then creates a FolderItem 
    object for the file. Finally, loops through all indices between 0 and 512 and returns all non-null 
    properties for that file.

  .PARAMETER Path
    The path to the file to get extended file properties for.

  .EXAMPLE
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

  .EXAMPLE
    PS> Get-ExtendedFileProperty example.mp4 | Where-Object PropertyName -like 'Date*'


    FileName    PropertyName  PropertyValue
    --------    ------------  -------------
    example.mp4 Date modified 12/25/2021 11:11 PM
    example.mp4 Date created  12/26/2021 12:04 AM
    example.mp4 Date accessed 12/26/2021 12:37 AM

  .EXAMPLE
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
  #>

  [OutputType([ExtendedFileProperty])]
  [CmdletBinding()]
  param(
    [Parameter(Mandatory, ValueFromPipeline)]
    [ValidateScript({ Test-Path -LiteralPath $_ }, ErrorMessage = "'{0}' is not a valid path.")]
    [String]$Path
  )

  begin {
    $shell = New-Object -ComObject Shell.Application
  }

  process {
    $resolvedPath = Resolve-Path -LiteralPath $Path
    $folderPath = Split-Path $resolvedPath
    $fileName = Split-Path $resolvedPath -Leaf

    $folderObject = $shell.NameSpace($folderPath)
    $fileObject = $folderObject.ParseName($fileName)

    foreach ($i in 0..512) {
      $property = $folderObject.GetDetailsOf($fileObject, $i)
      if ($property) {
        [ExtendedFileProperty] @{
          Path          = $resolvedPath
          FileName      = $fileName
          PropertyIndex = $i
          PropertyName  = $folderObject.GetDetailsOf($null, $i)
          PropertyValue = $property
        }
      }
    }
  }
}

function Get-DocumentationIP {
  <#
  .SYNOPSIS
    Returns an IP address that is suitable for use in documentation.
  
  .DESCRIPTION
    Returns a random IP address from the reserved address blocks described in RFC 5737 (for IPv4) or RFC 3849 (for IPv6).
  
  .PARAMETER IPVersion
    The IP version(s) allowed for the IP address. Valid values are "4", "6", or "Both". The default is "4".
  
  .PARAMETER Count
    Specifies the number of IP addresses to return. The default is 1.
  
  .EXAMPLE
    PS> Get-DocumentationIP
    203.0.113.194
  
  .EXAMPLE
    PS> Get-DocumentationIP -IPVersion 6
    2001:0DB8:164E:C268:CBD9:91FE:A7A3:392A
  
  .EXAMPLE
    PS> Get-DocumentationIP -IPVersion Both -Count 5
    2001:0DB8:C4EB:B3F9:5605:977C:2CFC:DE8A
    2001:0DB8:300C:F09B:B032:A1CC:2DE3:D5DE
    198.51.100.54
    203.0.113.68
    2001:0DB8:B846:485:FD81:91AA:60BA:CA97

  .LINK
    https://datatracker.ietf.org/doc/html/rfc5737

  .LINK
    https://datatracker.ietf.org/doc/html/rfc3849
  #>

  [OutputType([String])]
  [CmdletBinding()]
  param(
    [Parameter(ValueFromPipeline)]
    [ValidateSet('4', '6', 'Both')]
    [String]$IPVersion = '4',

    [Parameter(ValueFromPipeline)]
    [ValidateRange(0, [Int]::MaxValue)]
    [Int]$Count = 1
  )

  begin {
    $ipv4Prefixes = @('192.0.2.', '198.51.100.', '203.0.113.') # CIDR ranges: 192.0.2.0/24, 198.51.100.0/24, and 203.0.113.0/24 
    $ipv6Prefix = '2001:0DB8:' # CIDR range: 2001:DB8::/32
  }

  process {
    while ($Count -gt 0) {
      if ($IPVersion -eq 'Both') {
        $version = ('4', '6' | Get-Random)
      }
      else {
        $version = $IPVersion
      }

      if ($version -eq '4') {
        ($ipv4Prefixes | Get-Random) + (Get-Random -Maximum 255)
      }
      else {
        $ipv6Prefix + (Get-Random -Maximum 65535 -Count 6 | ForEach-Object { '{0:X}' -f $_ } | Join-String -Separator ':')
      }

      $Count--
    }
  }
}

function Get-DocumentationPhoneNumber {
  <#
  .SYNOPSIS
    Returns a telephone number that is suitable for use in documentation.
  
  .DESCRIPTION
    Returns a random North American Numbering Plan (NANP, country code "+1") telephone number from the reserved range described in ATIS-0300115.
  
  .PARAMETER Format
    The format for the telephone number. Valid values are "E.164", "Spaces", "Hyphens", or "US". The default is "E.164".

  .PARAMETER Specificity
    Whether to include the area code or the country code in the telephone number. Valid values are "Country", "Area", or "Local". The default is "Country".
  
  .PARAMETER Count
    Specifies the number of telephone numbers to return. The default is 1.
  
  .EXAMPLE
    PS> Get-DocumentationPhoneNumber
    +18725550194
  
  .EXAMPLE
    PS> Get-DocumentationPhoneNumber -Format US
    +1 (313) 555-0193
  
  .EXAMPLE
    PS> Get-DocumentationPhoneNumber -Format US -Specificity Area -Count 5
    (767) 555-0179
    (985) 555-0168
    (345) 555-0160
    (803) 555-0190
    (706) 555-0177

  .LINK
    https://www.nationalnanpa.com/pdf/NRUF/ATIS-0300115.pdf

  .LINK
    https://en.wikipedia.org/wiki/555_(telephone_number)
  #>

  [OutputType([String])]
  [CmdletBinding()]
  param(
    [Parameter(ValueFromPipeline)]
    [ValidateSet('E.164', 'Spaces', 'Hyphens', 'US')]
    [String]$Format = 'E.164',

    [Parameter(ValueFromPipeline)]
    [ValidateSet('Country', 'Area', 'Local')]
    [String]$Specificity = 'Country',

    [Parameter(ValueFromPipeline)]
    [ValidateRange(0, [Int]::MaxValue)]
    [Int]$Count = 1
  )

  begin {
    # Country code MUST be "+1" (NANP)
    $country = '1'

    # Valid area codes are all three digit NANP area codes that are not suspended and not reserved for special use (e.g., toll numbers)
    # Source: https://www.bennetyee.org/ucsd-pages/area.html
    $area = @('907', '825', '684', '264', '268', '480', '602', '623', '870', '242', '246', '441', '284', '831', '925', '909', '562', '661', '510', '650', '949', '760', '628', '415', '951', '587', '250', '236', '778', '604', '431', '204', '705', '581', '481', '418', '506', '709', '780', '902', '289', '905', '365', '437', '647', '416', '639', '306', '343', '613', '579', '450', '403', '548', '226', '519', '438', '514', '807', '867', '345', '209', '669', '408', '217', '317', '515', '774', '508', '517', '612', '320', '651', '908', '848', '732', '743', '336', '814', '205', '928', '501', '559', '720', '303', '689', '407', '478', '254', '325', '216', '670', '860', '203', '959', '475', '302', '767', '829', '809', '849', '509', '256', '319', '563', '606', '504', '985', '667', '443', '410', '810', '402', '252', '984', '919', '918', '539', '223', '717', '626', '423', '865', '434', '804', '757', '442', '239', '850', '727', '321', '754', '954', '927', '352', '863', '770', '470', '473', '671', '808', '208', '872', '312', '773', '464', '708', '765', '641', '876', '913', '225', '207', '339', '781', '857', '617', '978', '351', '679', '313', '586', '947', '248', '346', '713', '931', '763', '952', '769', '601', '636', '406', '664', '785', '859', '970', '315', '940', '817', '386', '502', '904', '404', '762', '706', '678', '574', '318', '218', '662', '660', '975', '816', '551', '201', '862', '973', '715', '775', '272', '570', '530', '916', '260', '518', '330', '234', '430', '903', '920', '603', '575', '957', '646', '332', '212', '347', '929', '718', '516', '917', '845', '631', '627', '980', '505', '701', '657', '714', '629', '615', '224', '847', '703', '571', '782', '479', '707', '779', '815', '219', '716', '585', '567', '419', '873', '819', '440', '380', '503', '458', '541', '971', '806', '878', '939', '787', '401', '435', '334', '251', '276', '310', '323', '213', '424', '818', '858', '935', '619', '805', '607', '910', '618', '812', '316', '620', '507', '228', '609', '914', '512', '361', '210', '561', '772', '725', '702', '220', '740', '520', '719', '786', '305', '912', '734', '573', '314', '557', '614', '835', '484', '610', '267', '215', '979', '936', '409', '262', '414', '721', '369', '843', '864', '803', '605', '869', '758', '784', '941', '813', '229', '337', '269', '417', '856', '283', '513', '937', '724', '608', '972', '469', '214', '682', '832', '281', '830', '956', '868', '649', '989', '906', '340', '801', '385', '802', '309', '712', '270', '301', '240', '413', '616', '231', '331', '630', '308', '828', '704', '580', '405', '412', '901', '731', '432', '915', '360', '564', '206', '202', '425', '253', '681', '304', '540', '307')

    # Prefix MUST be "555"
    $prefix = '555'

    # Line number MUST be "01XX" (i.e., between 0100 and 0199), as per ATIS-0300115
    $line = @()
    0..99 |  ForEach-Object { $line += '01{0:d2}' -f $_ }

    if ($Format -eq 'Spaces') {
      $delimiter = ' '
    }
    elseif ($Format -eq 'Hyphens') {
      $delimiter = '-'
    }
    else {
      $delimiter = ''
    }
  }

  process {
    while ($Count -gt 0) {
      if ($Specificity -eq 'Country') {
        if ($Format -eq 'US') {
          '+{0} ({1}) {2}-{3}' -f $country, (Get-Random $area), $prefix, (Get-Random $line)
        }
        else {
          '+' + $country + $delimiter + (Get-Random $area) + $delimiter + $prefix + $delimiter + (Get-Random $line)
        }
      }
      elseif ($Specificity -eq 'Area') {
        if ($Format -eq 'US') {
          '({0}) {1}-{2}' -f (Get-Random $area), $prefix, (Get-Random $line)
        }
        else {
          (Get-Random $area) + $delimiter + $prefix + $delimiter + (Get-Random $line)
        }
      }
      else {
        if ($Format -eq 'US') {
          '{0}-{1}' -f $prefix, (Get-Random $line)
        }
        else {
          $prefix + $delimiter + (Get-Random $line)
        }
      }

      $Count--
    }
  }
}

class PortStatus {
  [String]$RemoteHost
  [String]$Protocol
  [Int]$Port
  [Boolean]$PortOpen
}

function Test-TcpPort {
  <#
  .SYNOPSIS
    Tests if a TCP port is open or not.

  .DESCRIPTION
    Uses System.Net.Sockets.TcpClient to connect to a given TCP port and return whether the remote host responded or not. 
    Similar to Test-NetConnection but the timeout duration is adjustable and much smaller by default.

  .PARAMETER RemoteHost
    The name of the remote host to test TCP ports against.

  .PARAMETER Port
    The port number to test. Valid values are integers between 1 and 65535. The default value is 80.

  .PARAMETER Timeout
    The duration (in milliseconds) to wait for a response from the remote host. The default value is 200.

  .EXAMPLE
    PS> Test-TcpPort example.com

    RemoteHost  Protocol Port PortOpen
    ----------  -------- ---- --------
    example.com TCP      80       True

  .EXAMPLE
    PS> @(25, 80, 443) | Test-TcpPort example.com  

    RemoteHost  Protocol Port PortOpen
    ----------  -------- ---- --------
    example.com TCP      25      False
    example.com TCP      80       True
    example.com TCP      443      True
  
  .LINK
    Test-Connection
  
  .LINK
    Test-NetConnection
  #>

  [OutputType([PortStatus])]
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)]
    [String]$RemoteHost,

    [Parameter(ValueFromPipeline)]
    [ValidateRange(1, 65535)]
    [Int]$Port = 80,

    [ValidateRange(1, [Int]::MaxValue)]
    [Int]$Timeout = 200
  )
  
  process {
    $client = New-Object System.Net.Sockets.TcpClient
    $signal = $client.BeginConnect($RemoteHost, $Port, $null, $null).AsyncWaitHandle.WaitOne($Timeout, $false)

    [PortStatus] @{
      RemoteHost = $RemoteHost
      Protocol   = 'TCP'
      Port       = $Port
      PortOpen   = $signal
    }

    $client.Close()
  }
}

function Get-HelpAsMarkdown {
  <#
  .SYNOPSIS
    A minimal wrapper around Get-Help that outputs a markdown string.

  .DESCRIPTION
    Extracts the syntax, synopsis, description, parameters, and examples for a command from Get-Help and converts the output to markdown. 
    This command is intended to generate the minimum viable markdown documentation for a command.

  .PARAMETER Cmdlet
    The cmdlet to generate markdown documentation for.

  .EXAMPLE
    PS> Get-HelpAsMarkdown Get-Date

    # Get-Date

    (...)

    ## Synopsis
    Gets the current date and time.
    ## Description
    The `Get-Date` cmdlet gets a DateTime object that represents the current date or a date that you specify. `Get-Date` can (...)

    (...)
  
  .EXAMPLE
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

  .EXAMPLE
    PS> @('Get-Date', 'Format-Table') | Get-HelpAsMarkdown | Out-File -FilePath ./MyDocumentation.md

    Generates a file called "MyDocumentation.md" which contains the markdown documentation for the "Get-Date" and "Format-Table" commands.

  .EXAMPLE
    PS> Get-Command -Module ArdisUtilities | Get-HelpAsMarkdown | Out-File -FilePath ./ArdisUtilities.md

    Generates a file called "ArdisUtilities.md" which contains the markdown documentation for all the commands in the "ArdisUtilities" module.
  #>

  [OutputType([String])]
  [CmdletBinding()]
  param(
    [Parameter(Mandatory, ValueFromPipeline)]
    [String]$Cmdlet
  )

  begin {
    $output = New-Object System.Collections.Generic.List[String]
    $commonParameters = @(
      'Debug',
      'ErrorAction',
      'ErrorVariable',
      'InformationAction',
      'InformationVariable',
      'OutVariable',
      'OutBuffer',
      'PipelineVariable',
      'Verbose',
      'WarningAction',
      'WarningVariable'
    )
  }

  process {
    $help = Get-Help $Cmdlet
    $properties = $help.PSobject.Properties.Name

    if ($properties -contains 'Name') {
      $output.Add("# $($help.Name)") # Using .Name instead of $Cmdlet will use the capitalization intended by the cmdlet author
    }

    if ($properties -contains 'syntax') {
      $output.Add('```')
      $output.Add($($help.syntax | Out-String -NoNewline))
      $output.Add('```')
    }

    if ($properties -contains 'Synopsis') {
      $output.Add('## Synopsis')
      $output.Add($help.Synopsis)
    }

    if ($properties -contains 'description') {
      $output.Add('## Description')
      $output.Add($($help.description | Out-String -NoNewline))
    }

    if ('' -ne $help.parameters) {
      $output.Add('## Parameters')
      foreach ($parameter in $help.parameters.parameter | Where-Object { $_.Name -notin $commonParameters }) {
        $output.Add("### -$($parameter.Name)")
        $output.Add($($parameter.Description | Out-String -NoNewline))
        $output.Add('```yaml')
        $output.Add("Type: $($parameter.Type.Name)")
        $output.Add("Required: $($parameter.Required)")
        $output.Add("Position: $($parameter.Position)")
        $output.Add("Default value: $($parameter.DefaultValue)")
        $output.Add("Accept pipeline input: $($parameter.PipelineInput)")
        $output.Add('```')
      }
    }
    
    if ($properties -contains 'examples') {
      $output.Add('## Examples')
      $counter = 1
      foreach ($example in $help.examples.example) {
        $output.Add("### Example $counter")
        $output.Add('```powershell')
        $output.Add("PS> $($example.Code)")
        $output.Add($(($example.Remarks | Out-String).TrimEnd()))
        $output.Add('```')
        $counter++
      }
    }

    if ($properties -contains 'relatedLinks') {
      $output.Add('## Related Links')
      foreach ($link in $help.relatedLinks.navigationLink) {
        if ('linkText' -in $link.PSobject.Properties.Name) {
          $text = $link.linkText
        }
        else {
          $text = $link.uri
        }
        $output.Add("- $($text)")
      }
    }
  }

  end {
    $output -Join "`r`n"
  }
}

function Open-ParentFolder {
  <#
  .SYNOPSIS
    Opens the native GUI file explorer (e.g., File Explorer on Windows) in the folder that contains a command.

  .DESCRIPTION
    Uses Get-Command to determine the path to an executable, then passes the path to Split-Path to get the
    parent folder. Finally, opens the parent folder by passing the path as an argument to Invoke-Item.

  .PARAMETER Command
    The name of the executable to open the file explorer to.

  .EXAMPLE
    PS> Open-ParentFolder curl

    Opens file explorer to the folder containing the curl binary.
  #>

  [CmdletBinding()]
  param(
    [Parameter(Mandatory, ValueFromPipeline)]
    [String]$Command
  )

  begin {
    $ErrorActionPreference = 'Stop'
  }
  
  process {
    Invoke-Item ((Get-Command $Command).Source | Split-Path -Parent)
  }
}

class SubresourceIntegrity {
  [String]$Algorithm
  [String]$Hash
  [String]$Subresource
  [String]$Integrity
  [String]$Tag
}

$SubresourceIntegrityDisplay = @{
  TypeName                  = 'SubresourceIntegrity'
  DefaultDisplayPropertySet = 'Subresource', 'Integrity'
}
Update-TypeData @SubresourceIntegrityDisplay -Force

function Get-SubresourceIntegrity {
  <#
  .SYNOPSIS
    Gets the hash of a file for use in a subresource integrity (SRI) check.

  .DESCRIPTION
    Accepts either a local file path OR a URL to a file as input. If the input is a URL, downloads the file.
    Calculates the hash of the given file. Then outputs the hash in base64 with an algorithm prefix,
    so the hash is ready to be used in a subresource integrity (SRI) check.

  .PARAMETER Subresource
    A local file OR a URL to a file to calculate the integrity hash for.

  .PARAMETER Algorithm
    The hashing algorithm to use. Must be 'SHA256', 'SHA384', or 'SHA512'.

  .EXAMPLE
    PS> Get-SubresourceIntegrity ./example.js

    Subresource  Integrity
    -----------  ---------
    ./example.js sha512-X/YkDZyjTf4wyc2Vy16YGCPHwAY8rZJY+POgokZjQB2mhIRFJCckEGc6YyX9eNsPfn0PzThEuNs+uaomE5CO6A==

  .EXAMPLE
    PS> Get-SubresourceIntegrity "https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/js/bootstrap.bundle.min.js" -Algorithm SHA384

    Subresource                                                                  Integrity
    -----------                                                                  ---------
    https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/js/bootstrap.bundle.min.js sha384-C6RzsynM9kWDrMNeT87bh95OGNyZPhcTNXj1NW7RuBCsyN/o0jlpcV8Qyq46cDfL

  .EXAMPLE
    PS> @('./example1.js', './example2.js', './example3.js') | Get-SubresourceIntegrity

    Subresource   Integrity
    -----------   ---------
    ./example1.js sha512-X/YkDZyjTf4wyc2Vy16YGCPHwAY8rZJY+POgokZjQB2mhIRFJCckEGc6YyX9eNsPfn0PzThEuNs+uaomE5CO6A==
    ./example2.js sha512-UxkBbtNVXoNNNOwpKb3EdOtjmGNg3YbF6dq3ns6iPdrcy/WxOz+atgbe8USrqZk8vpKu4O2Rdw3U+ctPgcgwZg==
    ./example3.js sha512-f0Km8/mTw5HtTOWjPoYhh+SCxl7GCgdVE+SvPRzHqNUzzt+QpXTevZzqFC5KKHXSbMny5VR9/qadHYSGluNDEw==

  .LINK
    https://www.w3.org/TR/SRI/

  .LINK
    https://developer.mozilla.org/en-US/docs/Web/Security/Subresource_Integrity
  #>

  [OutputType([SubresourceIntegrity])]
  [CmdletBinding()]
  param(
    [Parameter(Mandatory, ValueFromPipeline)]
    [String]$Subresource,

    [ValidateSet('SHA256', 'SHA384', 'SHA512')]
    [String]$Algorithm = 'SHA512'
  )

  process {
    $isLocalFile = Test-Path -LiteralPath $Subresource -PathType Leaf

    if (!$isLocalFile) {
      try {
        $stream = (Invoke-WebRequest -Uri $Subresource).RawContentStream
      }
      catch {
        throw "$Subresource is not a valid file or URL."
      }
    }

    if ($isLocalFile) {
      $hash = (Get-FileHash -LiteralPath $Subresource -Algorithm $Algorithm).Hash
    }
    else {
      $hash = (Get-FileHash -InputStream $stream -Algorithm $Algorithm).Hash
    }
    $bytes = [System.Convert]::FromHexString($hash)
    $b64 = [System.Convert]::ToBase64String($bytes)

    $integrity = "$($Algorithm.ToLower())-$b64"
    $tag = "<script href=`"$Subresource`" integrity=`"$integrity`" crossorigin></script>"

    [SubresourceIntegrity] @{
      Algorithm   = $Algorithm
      Hash        = $hash
      Subresource = $Subresource
      Integrity   = $integrity
      Tag         = $tag
    }
  }
}

function Open-TemporaryBrowser {
  <#
  .SYNOPSIS
    Opens a new web browser instance with a temporary profile. Optionally passes flags to the temporary instance.

  .DESCRIPTION
    Finds the full path to the web browser, then passes a temporary profile to open a new isolated instance of the application.
    
  .PARAMETER Browser
    The web browser to open. Must be 'Brave', 'Chrome', or 'Edge'. Defaults to 'Chrome'.

  .PARAMETER CORS
    Pass the --disable-web-security flag to disable the same-origin policy, which disables CORS restrictions.

  .EXAMPLE
    PS> Open-TemporaryBrowser -CORS

    Opens a new isolated instance of Chrome with the same-origin policy disabled.
  #>

  [OutputType([System.Void])]
  [CmdletBinding()]
  param(
    [ValidateSet('Brave', 'Chrome', 'Edge')]
    [String]$Browser = 'Chrome',

    [Switch]$CORS
  )

  begin {
    # Retrieve full paths to Chromium browsers
    # Check the registry key for the Start Menu executable, then the key for the Win + R executable, then fallback to hardcoded default path
    # Wrapping in try/catch is required because -ErrorAction is ignored for terminating errors
    foreach ($key in @('Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Clients\StartMenuInternet\Brave\shell\open\command', 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\brave.exe')) {
      try {
        $bravePath ??= Get-ItemPropertyValue -LiteralPath $key -Name '(default)' -ErrorAction SilentlyContinue
      }
      catch {}
    }
    $bravePath ??= 'C:\Program Files\BraveSoftware\Brave-Browser\Application\brave.exe'

    foreach ($key in @('Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Clients\StartMenuInternet\Google Chrome\shell\open\command', 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\chrome.exe')) {
      try {
        $chromePath ??= Get-ItemPropertyValue -LiteralPath $key -Name '(default)' -ErrorAction SilentlyContinue
      }
      catch {}
    }
    $chromePath ??= 'C:\Program Files (x86)\Google\Chrome Dev\Application\chrome.exe'

    foreach ($key in @('Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Clients\StartMenuInternet\Microsoft Edge\shell\open\command', 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\msedge.exe')) {
      try {
        $edgePath ??= Get-ItemPropertyValue -LiteralPath $key -Name '(default)' -ErrorAction SilentlyContinue
      }
      catch {}
    }
    $edgePath ??= 'C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe'
  }

  process {
    switch ($Browser) {
      'Brave' { $execPath = $bravePath }
      'Chrome' { $execPath = $chromePath }
      'Edge' { $execPath = $edgePath }
    }
    $execPath = $execPath.Replace("`"", '') # Registry values have leading and trailing quote literals in the string

    if (-not(Test-Path -LiteralPath $execPath -PathType Leaf)) {
      throw "Could not find browser `"$Browser`" at path `"$execPath`", aborting."
    }

    $temp = Join-Path $Env:Temp $(New-Guid)

    # Directly using the call expression (&) will not work, must either wrap it inside Invoke-Expression or use System.Diagnostics.Process::Start
    # Invoke-Expression "& $execPath --user-data-dir=`"$temp`" $(if ($CORS) {'--disable-web-security'})"
    [System.Diagnostics.Process]::Start($execPath, "--user-data-dir=`"$temp`" $(if ($CORS) {'--disable-web-security'})") | Out-Null
  }
}

function Open-HistoryFile {
  <#
  .SYNOPSIS
    Opens the current session's persistent history file in a text editor.

  .DESCRIPTION
    Besides the in-memory session history which can be retrieved using Get-History, the PSReadLine module also
    maintains a persistent history of commands in a text file saved on disk. This command locates this text
    file using (Get-PSReadlineOption).HistorySavePath then opens it using Invoke-Item.

  .EXAMPLE
    PS> Open-HistoryFile

    Opens the default text editor on the persistent history file.
  #>

  process {
    Invoke-Item (Get-PSReadlineOption).HistorySavePath
  }
}
