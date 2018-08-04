<# Loads the Exchange Shell into a regular poweershell window#>


$Exver = 2016
#load exchange shell
        try
	    {
		switch ($Exver)
		{
			2007 {
				Add-PSSnapin Microsoft.Exchange.Management.PowerShell.Admin
			}
			2010 {
				Add-PSSnapin Microsoft.Exchange.Management.PowerShell.E2010
			}
			2013 {
				Add-PSSnapin Microsoft.Exchange.Management.PowerShell.SnapIn
			}
			2016 {
				Add-PSSnapin Microsoft.Exchange.Management.PowerShell.SnapIn
			}
			default
			{
				Write-Debug -Message "Exchange Version not supported"
				End
			}
		}
	    }
	# Catch all other exceptions thrown by one of those commands
	catch
	{
		Write-debug "Errors found during attempt to load Exchange Shell:`n$_"
		End
	}