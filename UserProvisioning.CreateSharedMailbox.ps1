<#
############################################################################################################
# Created by pierranchis                         #    Description: Creates shared mailbox, and migrates to #
# Create Shared Mailbox                          #                 Office365                               #
# Created: 10/19/2018                            #                                                         #
############################################################################################################
#>

# Variable Declarations
    . "$PSScriptRoot\UserProvisioning.GlobalVariables.ps1"

# Import the AD powershell module
    Import-Module activedirectory

<#----------------------------------- Beginning of Functions -----------------------------------#>

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
        Function Start-DeltaSync
            {
                $session = New-PSSession -ComputerName $AzureADServer
                Invoke-Command -Session $session -ScriptBlock {Start-ADSyncSyncCycle Delta}
                Remove-PSSession $session
            }
<#----------------------------------- End of Functions -----------------------------------#>



<#----------------------------------- Beginning of Input Logic -----------------------------------#>
             
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
            
# Prompt User for Distribution List information 
    Write-Host "Enter Mailbox Name. Example: IT Support Staff" -ForegroundColor Yellow
    $MailboxName = Read-Host -Prompt "Distribution List Name"

    Write-Host "Enter Mailbox Display Name. Example: IT Support Staff" -ForegroundColor Yellow
    $MailboxDisplayName = Read-Host -Prompt  "Distribution List Display Name"

    Write-Host "Enter Mailbox Alias. Example: itsupportstaff" -ForegroundColor Yellow
    $MailboxAlias = Read-Host -Prompt  "Distribution List Alias"
    $MailboxAlias = $MailboxAlias.ToLower().Trim()

    # Verify if sam account already exists in the domain
        $TmpUser = $(try {Get-ADUser $MailboxAlias} catch {$null})
	    
    # Loop until we get a sam account that is not in the domain
        while ($TmpUser -ne $null) 
            {
                Write-Host "$MailboxAlias is already in use, please enter Alias manually."
                $MailboxAlias = Read-Host -Prompt "Enter Distribution List Alias. Example: itsupportstaff" 
                $MailboxAlias = $MailboxAlias.ToLower().Trim()
                $TmpUser = $(try {Get-ADUser $MailboxAlias} catch {$null})
            }

    Write-Host "Enter Mailbox Description. Example: Mailbox for IT Support Staff" -ForegroundColor Yellow
    $MailboxDescription = Read-Host -Prompt "Distribution List Description"
                
# Set the UPN
    $UPN = $MailboxAlias + $FullDomain

<#----------------------------------- End of Input Logic -----------------------------------#>

	        # Connect to Exchange On-Prem
                $ExSession = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri $OnPremURI -Credential $DomainCredentials
	            Import-PSSession $ExSession -AllowClobber

            # Create Mailbox           
                New-Mailbox -Shared -Name $MailboxName -DisplayName $MailboxDisplayName -Alias $MailboxAlias -Database $MailboxDatabase -OrganizationalUnit $SharedMBOU

            # Replicate between internal domain controllers
                Write-Host
                Write-Host
                Write-Host "Replicating to Domain Controllers. Waiting 30 seconds." 
                Write-Host
                Write-Host
                Start-Countdown -Seconds 30 -Message "Replicating to Domain Controllers. Waiting 30 seconds."
	
	        # Set the desccription
	            Set-ADUser $MailboxName -Description $MailboxDescription
  
            # Forcing Azure Directory Synchronization with Domain Controllers
                Start-DeltaSync

            # Connect to Exchange O365
                $O365Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri $O365URI -Credential $UPNCredentials -Authentication Basic -AllowRedirection 
                Import-PSSession $O365Session -AllowClobber

            # Check if the user has been migrated to Office365
                do {
                       $CheckIfUserAccountExists = Get-MsolUser -UserPrincipalName $UPN -ErrorAction SilentlyContinue
                       Write-Host "Checking if $UPN has been migrated to Office365. Waiting 15 seconds."
                       Start-Countdown -Seconds 15 -Message "Checking if $UPN has been migrated to Office365. Waiting 15 seconds."
                    }
                While ($CheckIfUserAccountExists -eq $Null)
                
            # Migrate mailbox to O365 using the information from the keyboard input
                New-MoveRequest -Remote -RemoteHostName $OnPremExRemoteHostName -RemoteCredential $DomainCredentials -TargetDeliveryDomain $O365TenantName -Identity $UPN -BadItemLimit 200     
            
            # End of Script Notification
                Write-Host "Provisioning has completed." -ForegroundColor Green

# Disconnect Exhange sessions
    Remove-PSSession $ExSession
    Remove-PSSession $O365Session