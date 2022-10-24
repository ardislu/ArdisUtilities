@{
  RootModule        = 'ArdisUtilities.psm1'
  ModuleVersion     = '0.1.0'
  GUID              = '57a6bea3-0ea5-44b3-95d2-71d122772f1c'
  Author            = 'Ardis Lu'
  Description       = 'My personal utility functions.'
  FunctionsToExport = @('Invoke-RandomFile', 'ConvertTo-Base64String', 'Get-StringHash', 'Get-SizeDurationRatio', 'Get-ExtendedFileProperty', 'Get-DocumentationIP', 'Test-TcpPort', 'Get-HelpAsMarkdown')
  CmdletsToExport   = @()
  VariablesToExport = @()
  AliasesToExport   = @()
  PrivateData       = @{
    PSData = @{
      ProjectUri = 'https://github.com/ardislu/ArdisUtilities'
    }
  }
}
