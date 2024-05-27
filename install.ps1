[OutputType([System.Void])]
[CmdletBinding()]
param(
  [Parameter()]
  [Switch]$Persist
)

begin {
  # Create a temporary working folder
  $tempFolder = Join-Path $Env:Temp $(New-Guid)
  New-Item -Type Directory -Path $tempFolder | Out-Null
}

process {
  # Download and extract the repository from GitHub
  $zipFile = Join-Path $tempFolder /ArdisUtilities.zip
  Invoke-WebRequest 'https://github.com/ardislu/ArdisUtilities/archive/refs/heads/main.zip' -OutFile $zipFile
  Expand-Archive $zipFile $tempFolder
  $module = Join-Path $tempFolder 'ArdisUtilities-main/ArdisUtilities'

  # Import the module from the extraction
  Import-Module $module

  if ($Persist) {
    $destination = "$HOME/Documents/PowerShell/Modules" # Default path for persistent PowerShell modules
    if (Test-Path -LiteralPath "$destination/ArdisUtilities") {
      Remove-Item "$destination/ArdisUtilities" -Force -Recurse
    }
    Copy-Item -Path $module -Destination $destination -Recurse
  }
}

clean {
  # Clean up the temporary folder
  Remove-Item $tempFolder -Force -Recurse
}
