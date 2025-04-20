# ArdisUtilities

A [PowerShell module](https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_modules) containing my personal utility functions.

Requires [PowerShell 7+](https://github.com/PowerShell/PowerShell), which is [different from](https://ardislu.dev/powershell-versions) Windows PowerShell (PowerShell 5).

## Installation

### Using `install.ps1`

Use `install.ps1` to install or upgrade `ArdisUtilities`.

By default, the module is added to the **current session** only:

```PowerShell
irm 'https://raw.githubusercontent.com/ardislu/ArdisUtilities/main/install.ps1' | iex
```

To keep the module installed on future sessions, pass the `-Persist` parameter:

```PowerShell
"& { $(irm 'https://raw.githubusercontent.com/ardislu/ArdisUtilities/main/install.ps1') } -Persist" | iex
```

To uninstall, delete the `ArdisUtilities` folder. You can open this folder in your file explorer using:

```PowerShell
Open-ParentFolder (Get-Module -Name ArdisUtilities -ListAvailable).Path
```

### Manual

You can add the module to the current session manually by following these steps:

1. Download the `ArdisUtilities` folder

2. In PowerShell:

```PowerShell
Import-Module ./path/to/ArdisUtilities/
```

To persist this module on new sessions:
- Copy the `ArdisUtilities` folder to any folder on `$env:PSModulePath` ([reference](https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_psmodulepath)), or
- Register this module using [`Register-PSRepository`](https://learn.microsoft.com/en-us/powershell/module/powershellget/register-psrepository) then install the module using [`Install-Module`](https://learn.microsoft.com/en-us/powershell/module/powershellget/install-module) ([reference](https://stackoverflow.com/questions/49987884/how-to-install-update-a-powershell-module-from-a-local-folder-set-up-an-intern)), or
- Add the `Import-Module` command to your `$profile` ([reference](https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_profiles))

## Usage

View the imported utility functions:

```PowerShell
Get-Command -Module ArdisUtilities
```

Get usage help and examples for a specific function:

```PowerShell
Get-Help Invoke-RandomFile
```

## Documentation

[Click here](https://github.com/ardislu/ArdisUtilities/blob/docs/README.md) to view the full online documentation this module.
