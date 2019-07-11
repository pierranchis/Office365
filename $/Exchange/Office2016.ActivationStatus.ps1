# Script checks for valid Office 2016 directory, runs the activation script, then filters the line confirming license.
# Value greater than 0 means that Office 2016 is activated. Running lines 12+13 alone will also confirm activation.
# Goal for this script was to create a baseline in SCCM and auto-remediate, hence the $Value variable returning an integer. 

$Value = 0
$Directories = Test-Path "C:\Program Files\Microsoft Office\Office16"
if ($Directories -eq $true) {} 
else {
        $Value
        exit
     }

cd "C:\Program Files\Microsoft Office\Office16"
$Status = cscript ospp.vbs /dstatus | Select-String -Pattern '---licensed---'
if ($Status -ne $null) {$Value = $Value +1}

cd "C:\Program Files (x86)\Microsoft Office\Office16"
$Status = cscript ospp.vbs /dstatus | Select-String -Pattern '---licensed---'
if ($Status -ne $null) {$Value = $Value +1}

$Value
