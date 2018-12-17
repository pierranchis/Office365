function Show-Menu
{
     param (
           [string]$Title = 'Service Desk Menu'
     )
     cls
     Write-Host "================ $Title ================"
     
     Write-Host "[1] Create a new user"
     Write-Host "[2] Create a new Distribution List"
     Write-Host "[3] Create a new Shared Mailbox"
     Write-Host "[4] Migrate On-Prem mailbox to Office365"
     Write-Host "[5] Assign license to Office 365 mailbox"
     Write-Host "[6] Synchronize Active Directory Servers"
     Write-Host "[7] Disable User"
     Write-Host "[Q] Quit Menu"
}

do
{
     Show-Menu
     $input = Read-Host "Select from the following"
     switch ($input)
     {
        '1' {
                cls
                . "$PSScriptRoot\UserProvisioning.CreateUserAccount.ps1"
            } 
        '2' {
                cls
                . "$PSScriptRoot\UserProvisioning.CreateDistributionList.ps1"
            } 
        '3' {
                cls
                . "$PSScriptRoot\UserProvisioning.CreateSharedMailbox.ps1"
            } 
        '4' {
                cls
                . "$PSScriptRoot\UserProvisioning.MigrateMailboxToO365.ps1"
            } 
        '5' {
                cls
                . "$PSScriptRoot\UserProvisioning.AssignO365RegionAndLicense.ps1"
            } 
        '6' {
                cls
                . "$PSScriptRoot\UserProvisioning.ForceAzureReplication.ps1"
            }
        '7' {
                cls
                . "$PSScriptRoot\UserProvisioning.DisableUserAccount.ps1"
            }  
        'q' {
                    return
            }
     }
     pause
}
until ($input -eq 'q')