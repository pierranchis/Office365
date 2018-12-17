<#
############################################################################################################
# Created by pierranchis                         #    Description: Sets regional settings and license SKU  #
# Setting Regional settings and license SKU      #                 to the specified account                #
# Created: 05/22/2018                            #                                                         #
############################################################################################################
#>

# Variable Declaraions
. "$PSScriptRoot\UserProvisioning.GlobalVariables.ps1"

import-module MSOnline

# Connect to MS Online Service
    Write-Host "READ ME! Authentication: Enter your Microsoft Online Services credentials. Username Example; username@company.com." -ForegroundColor Yellow
    $MsolCredential = Get-Credential
    $MsolSession = Connect-MsolService -Credential $MsolCredential

# Retrieve Username
    $Username = Read-Host -Prompt "Enter User's username. Example; jdoe"
    $UPN = $Username + $FullDomain

# Set Regional Setting
    Set-MsolUser -Userprincipalname $UPN -UsageLocation $O365RegionCode

# Assign License
    Set-MsolUserLicense -User $UPN -AddLicenses $O365ProductSKU
