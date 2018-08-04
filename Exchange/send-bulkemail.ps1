 $scriptSettings = @{
  NumberOfEmails = 1000
  TimeBetweenEmails = 1 #in seconds
  MailDestination = "duser1@questskdemo.onmicrosoft.com","duser2@questskdemo.onmicrosoft.com","duser3@questskdemo.onmicrosoft.com"
  MailSubject = 'This is a prepopulated messages to test email backup.'
  MailServer = 'smtp.office365.com'
  MailFrom = 'gcook@questsystems.onmicrosoft.com'
}
$cred = Get-Credential
for ($i=1; $i -le $scriptSettings.NumberOfEmails; $i++) {
  try { 
  write-host "Processing message #$i"
  foreach($mailuser in $scriptsettings.MailDestination)
  {
    Send-MailMessage -Credential $cred -To $mailuser -Subject "$scriptSettings.mailSubject Message #$i" -SmtpServer $scriptSettings.mailServer -From $scriptSettings.mailFrom -Body "This is the body of the email.  This is test message email number $i" -UseSsl
    write-host "Sent message to user $mailuser"
  }
  } catch { 
    "Error sending email $i" 
  }
  write-host "Pausing"
  Start-Sleep -Seconds $scriptSettings.TimeBetweenEmails
}  