#Let's get us an admin cred!
$userCredential = Get-Credential

$ExoSession = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://outlook.office365.com/powershell-liveid/ -Credential $userCredential -Authentication Basic -AllowRedirection
Import-PSSession $ExoSession

$UserInboxRules = @()
$UserDelegates = @()

$mailboxes = Get-Mailbox -ResultSize Unlimited
$SMTPForwarding  = $mailboxes | select DisplayName,ForwardingAddress,ForwardingSMTPAddress,DeliverToMailboxandForward | where {$_.ForwardingSMTPAddress -ne $null} | ? { $_.ForwardingAddress -ne $null } 

$i = 1
foreach ($User in $Mailboxes)
{
   [int]$percent = [math]::Round($i / $($mailboxes.count) * 100) 
   write-progress -activity "Checking Mailboxes" -Status "$i/$($mailboxes.count) complete." -PercentComplete $percent
   Write-Host "Checking inbox rules and delegates for user: " $User.UserPrincipalName;
   $UserInboxRules += Get-InboxRule -Mailbox $User.UserPrincipalname | Select Name, Description, Enabled, Priority, ForwardTo, ForwardAsAttachmentTo, RedirectTo, DeleteMessage | Where-Object {($_.ForwardTo -ne $null) -or ($_.ForwardAsAttachmentTo -ne $null) -or ($_.RedirectsTo -ne $null)}
   $UserDelegates += Get-MailboxPermission -Identity $User.UserPrincipalName | Where-Object {($_.IsInherited -ne "True") -and ($_.User -notlike "*SELF*")}
   $i++
}

$UserInboxRules | Export-Csv MailForwardingRulesToExternalDomains.csv
$UserDelegates | Export-Csv MailboxDelegatePermissions.csv
$SMTPForwarding | Export-Csv Mailboxsmtpforwarding.csv
