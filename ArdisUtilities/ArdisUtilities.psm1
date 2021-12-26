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
    [ValidateRange(1, [int]::MaxValue)]
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

class ExtendedFileProperties {
  [String]$Path
  [String]$FileName
  [String]$PropertyIndex
  [String]$PropertyName
  [String]$PropertyValue
}

$ExtendedFilePropertiesDisplay = @{
  TypeName                  = 'ExtendedFileProperties'
  DefaultDisplayPropertySet = 'FileName', 'PropertyName', 'PropertyValue'
}
Update-TypeData @ExtendedFilePropertiesDisplay -Force

function Get-ExtendedFileProperties {
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
    PS> Get-ExtendedFileProperties example.mp4 

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
    PS> Get-ExtendedFileProperties example.mp4 | where PropertyName -like 'Date*'


    FileName    PropertyName  PropertyValue
    --------    ------------  -------------
    example.mp4 Date modified 12/25/2021 11:11 PM
    example.mp4 Date created  12/26/2021 12:04 AM
    example.mp4 Date accessed 12/26/2021 12:37 AM

  .EXAMPLE
    PS> @('example.mp4', 'example2.mp4') | Get-ExtendedFileProperties | where PropertyName -in 'Size', 'Length', 'Frame width', 'Frame height', 'Total bitrate'


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

  [OutputType([ExtendedFileProperties])]
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
        [ExtendedFileProperties] @{
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
