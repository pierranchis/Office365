<#
############################################################################################################
# Created by pierranchis                         #    Description: Forces Delta Azure Directory Sync       #
# Force Delta Azure Directory Sync               #                                                         #
# Created: 05/22/2018                            #                                                         #
############################################################################################################
#>

# Variable Declarations
    . "$PSScriptRoot\UserProvisioning.GlobalVariables.ps1"

# Initialize Azure DS Force Sync Function
    function Start-DeltaSync
        {
            $session = New-PSSession -ComputerName $AzureADServer
            Invoke-Command -Session $session -ScriptBlock {Start-ADSyncSyncCycle Delta}
            Remove-PSSession $session
        }

# Force Azure Directory Service Replication
    Start-DeltaSync