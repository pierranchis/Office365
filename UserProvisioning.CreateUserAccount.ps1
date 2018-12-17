<#
############################################################################################################
# Created by pierranchis                         #    Description: Creates AD user, mailbox, migrates to   #
# User Onboarding                                #                 Office365, assigns region code, and     #
# Created: 06/12/2018                            #                 license.                                #
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
            
            # Prompt the user for the account to copy
	            $UserToCopyInput = Read-Host -Prompt "`nEnter the existing user account to copy"
	            $UserToCopy = $(try {Get-ADUser $UserToCopyInput} catch {$null})
	    
            # If we could not get anything keep looping until we do
	            while($UserToCopy -eq $null) 
                    {
		                Write-Host "Could not find $UserToCopyInput, try again."
		                $UserToCopyInput = Read-Host -Prompt "User to copy"
		                $UserToCopy = $(try {Get-ADUser $UserToCopyInput} catch {$null})
	                }

	        #Loop until first name is given
	            while($GivenName -eq "")
                    {
		                $GivenName = Read-Host -Prompt "Enter First Name"
	                }
                        $GivenName = $GivenName.Trim()
	        # Loop until last name is given
	            while($SurName -eq "")
                    {
		                $SurName = Read-Host -Prompt "Enter Last Name"
	                }
	                    $SurName = $SurName.Trim()
            # Set the Whole name and display name
	            $Name = $DisplayName = $GivenName + " " + $SurName

	        #Try to create SamAccountName and UPN based off first and last name
	            $SamAccountName = $GivenName.Substring(0,1) + $SurName
	    
            # Try to see if the sam account already exists in the domain
	            $TmpUser = $(try {Get-ADUser $SamAccountName} catch {$null})
	    
            # Loop until we get a sam account that is not in the domain
	            while ($TmpUser -ne $null) 
                    {
		                Write-Host "$SamAccountName is already in AD, please enter SamAccount manually."
		                $SamAccountName = Read-Host -Prompt "SamAccount"
		                $TmpUser = $(try {Get-ADUser $SamAccountName} catch {$null})
	                }
	                    $SamAccountName = $SamAccountName.ToLower()
            # Set the UPN based off the Sam Account Name
	            $UPN = $SamAccountName + $FullDomain

	        # Set the path for our user object from the user to copy
	            $userinstance = Get-ADUser -Identity $UserToCopyInput
	            $DN = $userinstance.distinguishedName
	            $OldUser = [ADSI]"LDAP://$DN"
	            $Parent = $OldUser.Parent
	            $OU = [ADSI]$Parent
	            $OUDN = $OU.distinguishedName
	
	        # Set the Department, Title, and Company from the User to Copy
	            $DeptTitleComp = Get-ADUser -Identity $UserToCopyInput -Properties Department,Title,Company
	
	
	        # Prompt user for Office info
	            while($Office -eq "")
                    {
		                $Office = Read-Host -Prompt "Enter Office"
	                }

	        # Prompt user for Phone info
	            while($Phone -eq "")
                    {
		                $Phone = Read-Host -Prompt "Enter Phone Number"
	                }
	        # Prompt user for SSN info
	            while($SSN -eq "")
                    {
		                $SSN = Read-Host -Prompt "Enter SSN"
	                }

	        # Prompt user for Password
	            while($Password -eq "")
                    {
		                $Password = Read-Host -Prompt "Enter Password"
	                }

	        # Create the AD User
	            New-ADUser `
	                -SamAccountName $SamAccountName `
	                -UserPrincipalName $UPN `
	                -Name $Name `
	                -DisplayName $DisplayName `
	                -GivenName $GivenName `
	                -SurName $SurName `
	                -Department $DeptTitleComp.Department `
	                -Office $Office `
	                -OfficePhone $Phone `
	                -Title $DeptTitleComp.Title `
	                -Description $DeptTitleComp.Title `
	                -Company $DeptTitleComp.Company `
	                -POBox $SSN `
	                -Path "$OUDN" `
	                -AccountPassword (ConvertTo-SecureString "$Password" -AsPlainText -force) `
	                -Enabled $True

	        # Prompt user for Manager info
	            while($Manager -eq "")
                    {
		                $Manager = Read-Host -Prompt "Enter Manager"
		                $MgrObject = $(try {Get-ADUser -Filter "displayName -like '$($Manager)'"} catch {$null})
		            
                        # This block executes if the display name is entered
		                    if ($MgrObject -ne $null) 
                                {
			                        Set-ADUser -Identity $SamAccountName -Manager $MgrObject.SamAccountName
		                        }

		                # This block executes if the sam account name is entered
		                    else 
                                {
			                        Set-ADUser -Identity $SamAccountName -Manager $Manager
		                        }
	                }

<#----------------------------------- End of Input Logic -----------------------------------#>

# Copies group membership(s) to the new user
    Get-ADUser -Identity $UserToCopy -Properties memberof |
    Select-Object -ExpandProperty memberof |
    Add-ADGroupMember -Members $SamAccountName

# Countdown for 30 seconds to allow Domain Controllers to replicate.
    Write-Host
    Write-Host
    Write-Host "Replicating Domain Controllers. Waiting 30 seconds.`n "  
    Write-Host
    Write-Host            
    Start-Countdown -Seconds 30 -Message "Replicating Domain Controllers. Waiting 30 seconds."

# Connect to Exchange On-Prem
    $ExSession = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri $OnPremURI -Credential $DomainCredentials
    Import-PSSession $ExSession -AllowClobber

# Create a Mailbox for User
    try {Enable-Mailbox -Identity $SamAccountName -Database $MailboxDatabase -RetentionPolicy 'DeletedItemsPolicy'} catch {ErrorAction 'SilentlyContinue'}
            
# Countdown 30 seconds for Exchange to finalize mailbox creation
    Write-Host
    Write-Host
    Write-Host "Finalizing Mailbox creation. Waiting 30 seconds.`n " 
    Write-Host
    Write-Host
    Start-Countdown -Seconds 30 -Message "Finalizing Mailbox creation. Waiting 30 seconds"
 
# Forcing Azure Directory Synchronization with Domain Controllers
    Start-DeltaSync

# Connect to Exchange O365
    $O365Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri $O365URI -Credential $UPNCredentials -Authentication Basic -AllowRedirection
    Import-PSSession $O365Session -AllowClobber
                
# Connect to Microsoft Online Services
    $MsolSession = Connect-MsolService -Credential $UPNCredentials

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
                             
# Disable ActiveSync
    Start-Countdown -Seconds 60 -Message "Applying License. Waiting 60 seconds."
    Set-CASMailbox -Identity $UPN -ActiveSyncEnabled $False

# End of Script Notification
    Write-Host "User Provisioning script has completed." -ForegroundColor Green

# Disconnect Exhange sessions
    Remove-PSSession $ExSession
    Remove-PSSession $O365Session