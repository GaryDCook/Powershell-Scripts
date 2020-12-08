Function Set-Owner {
    <#
        .SYNOPSIS
            Changes owner of a file or folder to another user or group.

        .DESCRIPTION
            Changes owner of a file or folder to another user or group.

		.PARAMETER Path
            The folder or file that will have the owner changed.

        .PARAMETER Account
            Optional parameter to change owner of a file or folder to specified account.

            Default value is 'Builtin\Administrators'

        .PARAMETER Recurse
            Recursively set ownership on subfolders and files beneath given folder.

        .NOTES
            Name: Set-Owner
            Author: Boe Prox
            Version History:
                 1.0 - Boe Prox
                    - Initial Version
				 2.0 - Gary Cook
					- Added PShellLogging to capture Success and Error Information
					- Fixed issues processing owner on specific server OS's
	
			Requires the PSHellLogging Modules Available on PowerShell gallery
			https://www.powershellgallery.com/packages/PShellLogging/1.1.13
			Use "Install-Module -Name PShellLogging" on powershell 5.0 and higher to install

        .EXAMPLE
            Set-Owner -Path C:\temp\test.txt -Log c:\logs\ownerlog.csv -logtype CSV

            Description
            -----------
            Changes the owner of test.txt to Builtin\Administrators, Logs output to c:\logs\ownerlog.csv in comma Seperated Format

        .EXAMPLE
            Set-Owner -Path C:\temp\test.txt -Account 'Domain\bprox -Log c:\logs\ownerlog.TXT -logtype TXT

            Description
            -----------
            Changes the owner of test.txt to Domain\bprox, Logs output to c:\logs\ownerlog.csv in text format

        .EXAMPLE
            Set-Owner -Path C:\temp -Recurse -Log c:\logs\ownerlog.csv -logtype CSV

            Description
            -----------
            Changes the owner of all files and folders under C:\Temp to Builtin\Administrators, Logs output to c:\logs\ownerlog.csv in comma Seperated Format

        .EXAMPLE
            Get-ChildItem C:\Temp | Set-Owner -Recurse -Account 'Domain\bprox' -Log c:\logs\ownerlog.csv -logtype CSV

            Description
            -----------
            Changes the owner of all files and folders under C:\Temp to Domain\bprox, Logs output to c:\logs\ownerlog.csv in comma Seperated Format
    #>
    [cmdletbinding(
        SupportsShouldProcess = $True
    )]
    Param (
        [parameter(mandatory = $true,ValueFromPipeline=$True,ValueFromPipelineByPropertyName=$True)]
        [Alias('FullName')]
        [string[]]$Path,
        [parameter()]
        [string]$Account = 'Builtin\Administrators',
        [parameter()]
		[switch]$Recurse,
		[parameter()]
		[string]$Log,
		[parameter()]
		[ValidateSet("TXT", "CSV", "JSON")]
		[string]$logtype = "CSV"
    )
	Begin
	{
		#Create Log if necessary
		if ($Log -ne $null)
		{
			$MyLog = Start-Log -Log $Log -Type $logtype
			$logging = $true
		}
        #Prevent Confirmation on each Write-Debug command when using -Debug
        If ($PSBoundParameters['Debug']) {
            $DebugPreference = 'Continue'
        }
        Try {
			[void][TokenAdjuster]
		} Catch {
            $AdjustTokenPrivileges = @"
            using System;
            using System.Runtime.InteropServices;

             public class TokenAdjuster
             {
              [DllImport("advapi32.dll", ExactSpelling = true, SetLastError = true)]
              internal static extern bool AdjustTokenPrivileges(IntPtr htok, bool disall,
              ref TokPriv1Luid newst, int len, IntPtr prev, IntPtr relen);
              [DllImport("kernel32.dll", ExactSpelling = true)]
              internal static extern IntPtr GetCurrentProcess();
              [DllImport("advapi32.dll", ExactSpelling = true, SetLastError = true)]
              internal static extern bool OpenProcessToken(IntPtr h, int acc, ref IntPtr
              phtok);
              [DllImport("advapi32.dll", SetLastError = true)]
              internal static extern bool LookupPrivilegeValue(string host, string name,
              ref long pluid);
              [StructLayout(LayoutKind.Sequential, Pack = 1)]
              internal struct TokPriv1Luid
              {
               public int Count;
               public long Luid;
               public int Attr;
              }
              internal const int SE_PRIVILEGE_DISABLED = 0x00000000;
              internal const int SE_PRIVILEGE_ENABLED = 0x00000002;
              internal const int TOKEN_QUERY = 0x00000008;
              internal const int TOKEN_ADJUST_PRIVILEGES = 0x00000020;
              public static bool AddPrivilege(string privilege)
              {
               try
               {
                bool retVal;
                TokPriv1Luid tp;
                IntPtr hproc = GetCurrentProcess();
                IntPtr htok = IntPtr.Zero;
                retVal = OpenProcessToken(hproc, TOKEN_ADJUST_PRIVILEGES | TOKEN_QUERY, ref htok);
                tp.Count = 1;
                tp.Luid = 0;
                tp.Attr = SE_PRIVILEGE_ENABLED;
                retVal = LookupPrivilegeValue(null, privilege, ref tp.Luid);
                retVal = AdjustTokenPrivileges(htok, false, ref tp, 0, IntPtr.Zero, IntPtr.Zero);
                return retVal;
               }
               catch (Exception ex)
               {
                throw ex;
               }
              }
              public static bool RemovePrivilege(string privilege)
              {
               try
               {
                bool retVal;
                TokPriv1Luid tp;
                IntPtr hproc = GetCurrentProcess();
                IntPtr htok = IntPtr.Zero;
                retVal = OpenProcessToken(hproc, TOKEN_ADJUST_PRIVILEGES | TOKEN_QUERY, ref htok);
                tp.Count = 1;
                tp.Luid = 0;
                tp.Attr = SE_PRIVILEGE_DISABLED;
                retVal = LookupPrivilegeValue(null, privilege, ref tp.Luid);
                retVal = AdjustTokenPrivileges(htok, false, ref tp, 0, IntPtr.Zero, IntPtr.Zero);
                return retVal;
               }
               catch (Exception ex)
               {
                throw ex;
               }
              }
             }
"@
            Add-Type $AdjustTokenPrivileges
        }

        #Activate necessary admin privileges to make changes without NTFS perms
        [void][TokenAdjuster]::AddPrivilege("SeRestorePrivilege") #Necessary to set Owner Permissions
        [void][TokenAdjuster]::AddPrivilege("SeBackupPrivilege") #Necessary to bypass Traverse Checking
        [void][TokenAdjuster]::AddPrivilege("SeTakeOwnershipPrivilege") #Necessary to override FilePermissions
    }
    Process {
        ForEach ($Item in $Path) {
			Write-Verbose "FullName: $Item"
			if ($logging)
			{
				$MyLog | Write-Log -Line "Proicessing item $($Item)" -Level Info
			}
            #The ACL objects do not like being used more than once, so re-create them on the Process block
            $DirOwner = New-Object System.Security.AccessControl.DirectorySecurity
            $DirOwner.SetOwner([System.Security.Principal.NTAccount]$Account)
            $FileOwner = New-Object System.Security.AccessControl.FileSecurity
            $FileOwner.SetOwner([System.Security.Principal.NTAccount]$Account)
            $DirAdminAcl = New-Object System.Security.AccessControl.DirectorySecurity
            $FileAdminAcl = New-Object System.Security.AccessControl.DirectorySecurity
            $AdminACL = New-Object System.Security.AccessControl.FileSystemAccessRule('Builtin\Administrators','FullControl','ContainerInherit,ObjectInherit','InheritOnly','Allow')
            $FileAdminAcl.AddAccessRule($AdminACL)
            $DirAdminAcl.AddAccessRule($AdminACL)
            Try {
                $Item = Get-Item -LiteralPath $Item -Force -ErrorAction Stop
                If (-NOT $Item.PSIsContainer) {
                    If ($PSCmdlet.ShouldProcess($Item, 'Set File Owner')) {
                        Try {
                            $Item.SetAccessControl($FileOwner)
                        } Catch {
                            Write-Warning "Couldn't take ownership of $($Item.FullName)! Taking FullControl of $($Item.Directory.FullName)"
                            $Item.Directory.SetAccessControl($FileAdminAcl)
                            $Item.SetAccessControl($FileOwner)
                        }
                    }
                } Else {
                    If ($PSCmdlet.ShouldProcess($Item, 'Set Directory Owner')) {                        
                        Try {
                            $Item.SetAccessControl($DirOwner)
                        } Catch {
                            Write-Warning "Couldn't take ownership of $($Item.FullName)! Taking FullControl of $($Item.Parent.FullName)"
                            $Item.Parent.SetAccessControl($DirAdminAcl) 
                            $Item.SetAccessControl($DirOwner)
                        }
                    }
                    If ($Recurse) {
                        [void]$PSBoundParameters.Remove('Path')
                        Get-ChildItem $Item -Force | Set-Owner @PSBoundParameters
                    }
				}
				if ($logging)
				{
					$MyLog | Write-Log -Line "Item $($Item) was successfully processed" -Level Info
				}
			}
			Catch
			{
				Write-Warning "$($Item): $($_.Exception.Message)"
				if ($logging)
				{
					$MyLog | Write-Log -Line "Item $($Item) processing failed error message $($_.Exception.Message)" -Level Error
				}
			}
		}
	}
	End {  
        #Remove priviledges that had been granted
        [void][TokenAdjuster]::RemovePrivilege("SeRestorePrivilege") 
        [void][TokenAdjuster]::RemovePrivilege("SeBackupPrivilege")
		[void][TokenAdjuster]::RemovePrivilege("SeTakeOwnershipPrivilege")
		if ($logging)
		{
			$MyLog | Close-Log 
		}
    }
}
