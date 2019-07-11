# Variable Declarations
. "$PSScriptRoot\NewUserProvisioning.GlobalVariables.ps1"

# Prompt the user for Login Credentials
  Write-Host "READ ME! Authentication: Enter your privileged user account. Example; jdoe" -ForegroundColor Yellow
    $DomainUser = Read-Host -Prompt "Privileged User Account"
    $UPNLogin = $DomainUser + $FullDomain
    $DomainLogin = $LocalDomain + $DomainUser
  Write-Host "READ ME! Authentication: Enter your privileged user account password." -ForegroundColor Yellow
    $DomainPassword = Read-Host -AsSecureString "Privileged User Account Password"

    # Create credential sets
      $UPNCredentials = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $UPNLogin,$DomainPassword
      $DomainCredentials = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $DomainLogin,$DomainPassword

# Function Declarations
. "$PSScriptRoot\NewUserProvisioning.Functions.ps1"

do
    {
         Show-Menu
         $input = Read-Host "Select from the following"
         switch ($input)
          {
            '1' {
                    cls
                    CreateUserAccount
                } 
            '2' {
                    cls
                    CreateDistributionList
                } 
            '3' {
                    cls
                    CreateSharedMailbox
                } 
            '4' {
                    cls
                    MigrateMailboxO365
                } 
            '5' {
                    cls
                    O365License
                } 
            '6' {
                    cls
                    Start-DeltaSync
                }
            '7' {
                    cls
                    DisableUserAccount
                }  
            'q' {
                        return
                }
          }
         pause
    }
until ($input -eq 'q')
