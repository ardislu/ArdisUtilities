#!/usr/bin/env pwsh

<#
.SYNOPSIS
  Install the ArdisUtilities module.

.DESCRIPTION
  By default, the ArdisUtilities module will be installed for the current session only.
  If '-Persist' is specified, then the ArdisUtilities module will be installed to 
  the "$HOME/Documents/PowerShell/Modules" folder.

.PARAMETER Persist
  Install the ArdisUtilities module to "$HOME/Documents/PowerShell/Modules".

.EXAMPLE
  PS> ./install.ps1

  Installs ArdisUtilities in the current session only.

.EXAMPLE
  PS> ./install.ps1 -Persist

  Installs ArdisUtilities to "$HOME/Documents/PowerShell/Modules", persisting the module across sessions.

.EXAMPLE
  PS> irm 'https://raw.githubusercontent.com/ardislu/ArdisUtilities/main/install.ps1' | iex

  Invoke this script from GitHub, installing ArdisUtilities in the current session only.

.EXAMPLE
  PS> "& { $(irm 'https://raw.githubusercontent.com/ardislu/ArdisUtilities/main/install.ps1') } -Persist" | iex

  Invoke this script from GitHub, installing ArdisUtilities to "$HOME/Documents/PowerShell/Modules" and
  persisting the module across sessions.
#>
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
