# ArdisUtilities

A [PowerShell module](https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_modules) containing my personal utility functions.

## Installation

### Using `install.ps1`

The `install.ps1` script will download the module to a temporary folder then use [`Import-Module`](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/import-module) to add the module to the **current session** only. To keep the module installed on future sessions, see [Persistence](https://github.com/ardislu/ArdisUtilities#persistence).

```PowerShell
iwr 'https://raw.githubusercontent.com/ardislu/ArdisUtilities/main/install.ps1' | iex
```

### Manual

You can also add the module to the current session manually by following these steps:

1. Download the `ArdisUtilities` folder

2. In PowerShell:

```PowerShell
Import-Module ./path/to/ArdisUtilities/
```

### Persistence

To persist this module on new sessions:
- Copy the `ArdisUtilities` folder to any folder on `$env:PSModulePath` ([reference](https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_psmodulepath)), or
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
