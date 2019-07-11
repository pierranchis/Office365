<#
Note: Run powershell as local administrator. Running "As Administrator" is not the same.
Will need to source .NetFramework 4.5.2 and MS Online Assistant
#>

#Variables
    $Net452Path = "\\path\NetFramework452.exe"
    $MsolPath = "\\path\MS.Online.Assistant.msi"

# Set execution policy to remote signed
    Set-ExecutionPolicy -ExecutionPolicy RemoteSigned

# Install .Net Framework 4.5.2
    $Net452Path /q /norestart

# Install Microsoft Online Services Sign-in Assistant
    Msiexec.exe /i $MsolPath /qn /norestart

# Install Windows Azure Active Directory Module
    Install-Module -Name AzureAD -confirm:$false #-Force

# Install Microsoft Online Assistant Module
    Install-Module –name msonline -confirm:$false #-Force

# Test by connecting to Office 365
    Connect-MsolService
