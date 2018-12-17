<#
############################################################################################################
# Created by pierranchis                            # Description: Migrates mailbox to Office 365, assigns #
# Migrate Mailbox to O365                           # region code, and license.                            #
# Created:                                          #                                                      #
############################################################################################################
#>

# Variable Declarations
  . "$PSScriptRoot\UserProvisioning.GlobalVariables.ps1"

# Import the AD powershell module
    Import-Module activedirectory

# Initializing a Countdown Function
    Function Start-Countdown
      {
        Param(
                [Int32]$Seconds = 30,
                [string]$Message = "Pausing for 30 seconds..."
              )
        ForEach ($Count in (1..$Seconds))
          {
            Write-Progress -Id 1 -Activity $Message -Status "Time Left: $Seconds seconds, $($Seconds - $Count)" -PercentComplete (($Count / $Seconds) * 100)
            Start-Sleep -Seconds 1
          }
        Write-Progress -Id 1 -Activity $Message -Status "Completed" -PercentComplete 100 -Completed
      }

# Initializing Azure DS Force Sync Function
  function Start-DeltaSync
    {
      $session = New-PSSession -ComputerName $AzureADServer
      Invoke-Command -Session $session -ScriptBlock {Start-ADSyncSyncCycle Delta}
      Remove-PSSession $session
    }

# Forcing Azure Directory Synchronization with Domain Controllers
  Start-DeltaSync

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

# Connect to Exchange On-Prem
  $ExSession = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri $OnPremURI -Credential $DomainCredentials
  Import-PSSession $ExSession -AllowClobber

# Connect to Exchange O365
  $O365Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri $O365URI -Credential $UPNCredentials -Authentication Basic -AllowRedirection
  Import-PSSession $O365Session -AllowClobber

# Connect to Microsoft Online Services
  $MsolSession = Connect-MsolService -Credential $UPNCredentials

# Prompt for the email address to migrate
  $Username = Read-Host -Prompt "Enter User's username. Example; jdoe"
  $UPN = $Username + $FullDomain

# Check if the user has been replicated to Office365
    do {
           $CheckIfUserAccountExists = Get-MsolUser -UserPrincipalName $UPN -ErrorAction SilentlyContinue
           Write-Host "Checking if $UPN has been migrated to Office365. Waiting 15 seconds."
           Start-Countdown -Seconds 15 -Message "Checking if $UPN has been migrated to Office365. Waiting 15 seconds."
        }
    While ($CheckIfUserAccountExists -eq $Null)

# Migrate user
  New-MoveRequest -Remote -RemoteHostName $OnPremExRemoteHostName -RemoteCredential $DomainCredentials -TargetDeliveryDomain $O365TenantName -Identity $UPN -BadItemLimit 200

# Assign User Regional Setting and License
  Set-MsolUser -Userprincipalname $UPN -UsageLocation $O365RegionCode
  Set-MsolUserLicense -User $UPN -AddLicenses $O365ProductSku

# End of Script Notification
  Write-Host "User Migration script has completed." -ForegroundColor Green

# Disconnect Exhange sessions
  Remove-PSSession $ExSession
  Remove-PSSession $O365Session