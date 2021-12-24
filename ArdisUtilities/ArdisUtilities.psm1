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
    [ValidateScript({ Test-Path -LiteralPath $_ })]
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
    PS> "Example from pipe" | ConvertTo-Base64String

    RXhhbXBsZSBmcm9tIHBpcGU=
  #>

  [OutputType([String])]
  [CmdletBinding()]
  param(
    [Parameter(ValueFromPipeline)]
    [String]$InputString
  )

  process {
    [System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($InputString))
  }
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
    PS> Get-StringHash "Example"

    Algorithm       Hash                                                                   Path
    ---------       ----                                                                   ----
    SHA1            0F01ED56A1E32A05E5EF96E4D779F34784AF9A96

  .EXAMPLE
    PS> Get-StringHash "Example" -Algorithm SHA256

    Algorithm       Hash                                                                   Path
    ---------       ----                                                                   ----
    SHA256          D029F87E3D80F8FD9B1BE67C7426B4CC1FF47B4A9D0A8461C826A59D8C5EB6CD      

  .EXAMPLE
    PS> "Example from pipe" | Get-StringHash -Algorithm MD5   

    Algorithm       Hash                                                                   Path
    ---------       ----                                                                   ----
    MD5             B5E635A46089D9BB16C688383D1E98C6
  #>

  [OutputType('Microsoft.PowerShell.Commands.FileHashInfo')]
  [CmdletBinding()]
  param(
    [Parameter(ValueFromPipeline)]
    [String]$InputString = '',

    [ValidateSet('SHA1', 'SHA256', 'SHA384', 'SHA512', 'MD5')]
    [String]$Algorithm = 'SHA1'
  )

  process {
    $stream = [System.IO.MemoryStream]::new([byte[]][char[]]$InputString)
    Get-FileHash -InputStream $stream -Algorithm $Algorithm
  }
}
