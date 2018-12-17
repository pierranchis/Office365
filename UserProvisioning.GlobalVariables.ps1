#Domain
    $AzureADServer = 'AzureDirectoryServer'
    $FullDomain = '@domain.com'
    $LocalDomain = 'domain\'
    $UserToCopyInput = $SamAccountName = $SamAccountName2 = $UPN = $Name = $DisplayName = $GivenName = $SurName = ""
    $Department = $Office = $Phone = $Title = $Company = $Database = $SSN = $Manager = $Password = ""    

#Exchange On-Prem
    $OnPremURI = 'http://exchangeserver.domain.local/PowerShell/'
    $OnPremExRemoteHostName = 'mail.company.com'
    $MailboxDatabase = 'exchange database name'
    $SharedMBOU = "OU where the shared mailbox AD account will be created"
    $DistListOU = "OU where the distribution group will be created"

#Exchange Office 365    
    $O365TenantName = 'domain.mail.onmicrosoft.com'
    $O365RegionCode = 'regioncode'
    $O365ProductSku = 'License name'
    $O365URI = 'https://outlook.office365.com/powershell-liveid/'