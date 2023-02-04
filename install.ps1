# Create a temporary working folder
$tempFolder = Join-Path $Env:Temp $(New-Guid)
New-Item -Type Directory -Path $tempFolder | Out-Null

# Download and extract the repository from GitHub
$zipFile = Join-Path $tempFolder /ArdisUtilities.zip
Invoke-WebRequest 'https://github.com/ardislu/ArdisUtilities/archive/refs/heads/main.zip' -OutFile $zipFile
Expand-Archive $zipFile $tempFolder

# Import the module from the extraction
Import-Module (Join-Path $tempFolder /ArdisUtilities-main/ArdisUtilities)
