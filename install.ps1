#!/usr/bin/env pwsh

<#
.SYNOPSIS
  Install the ArdisUtilities module.

.DESCRIPTION
  By default, the ArdisUtilities module will be installed for the current session only.
  If '-Persist' is specified, then the ArdisUtilities module will be installed to 
  the first location found in $env:PSModulePath. If no location is found in $env:PSModulePath,
  ArdisUtilities will be installed to "$HOME\Documents\PowerShell\Modules" (Windows) or
  "$HOME/.local/share/powershell/Modules" (non-Windows).

.PARAMETER Persist
  Install the ArdisUtilities module to the first location found in $env:PSModulePath, or
  "$HOME\Documents\PowerShell\Modules" (Windows) or "$HOME/.local/share/powershell/Modules" (non-Windows)
  if no location is found.

.EXAMPLE
  PS> ./install.ps1

  Installs ArdisUtilities in the current session only.

.EXAMPLE
  PS> ./install.ps1 -Persist

  Installs ArdisUtilities to the first location in $env:PSModulePath, persisting the module across sessions.

.EXAMPLE
  PS> irm 'https://raw.githubusercontent.com/ardislu/ArdisUtilities/main/install.ps1' | iex

  Invoke this script from GitHub, installing ArdisUtilities in the current session only.

.EXAMPLE
  PS> "& { $(irm 'https://raw.githubusercontent.com/ardislu/ArdisUtilities/main/install.ps1') } -Persist" | iex

  Invoke this script from GitHub, installing ArdisUtilities to the first location in $env:PSModulePath and
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
    $destination = ($env:PSModulePath -Split ';')[0]
    
    # If no folder is found from PSModulePath, use default location for the CurrentUser scope. See:
    # https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_psmodulepath
    if (-Not (Test-Path -LiteralPath $destination)) {
      if ($IsWindows) {
        $destination = "$HOME/Documents/PowerShell/Modules"
      }
      else {
        $destination = "$HOME/.local/share/powershell/Modules"
      }
    }

    if (Test-Path -LiteralPath "$destination/ArdisUtilities") {
      Remove-Item "$destination/ArdisUtilities" -Force -Recurse
    }

    Copy-Item -Path $module -Destination $destination -Recurse
    Write-Output "Successfully installed ArdisUtilities to `"$(Resolve-Path "$destination/ArdisUtilities")`"."
  }
  else {
    Write-Output "Successfully installed ArdisUtilities in the current session."
  }

  Write-Output ""
  Write-Output "Show all ArdisUtilities commands:"
  Write-Output "Get-Command -Module ArdisUtilities"
}

clean {
  # Clean up the temporary folder
  Remove-Item $tempFolder -Force -Recurse
}
