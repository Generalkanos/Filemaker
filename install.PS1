$Host.UI.RawUI.WindowTitle = "Filemaker Pro Install Script"
<# 	
	Install Filemaker Pro 15 x64
	
	To change in next version:
	-Change DisplayVersion query to Version Number query (better integer for math-ing)
	-Sanitize script for any versions (should only need to make one change per version)
	-Add proper exit logging for troubleshooting
    -Add another clause for major version changes
	-Fix Get-MsiDatabaseVersion as it fails to pass a readable string
#>

<#	
	User defined variables
	Change these as necessary
#>
$FMInstallerProductID13 = "{4B2ABFE4-3A1D-4FFB-B6E8-A256ADFB0D7A}"															#GUID of version 13
$FMInstallerProductID14 = "{593FFA0C-970C-4867-BEAE-3D7D7F3F69CF}"															#GUID of version 14 to remove (Changes between major versions)
$FMInstallerProductID15 = "{C221AAF3-7C43-40CC-BDB7-82647C79B9FA}"															#GUID of version 15 (Changes between major versions)

<#	
	Script defined variables
	These should never really need to change
#>
$CUR_DATE=get-date -f "dd-MM-yyyy"																							#current date in a nice format for logging
$InstallPath = ""
$FMInstaller = $InstallPath + "\CurrentVersion\Files\FileMaker Pro 15 Advanced.msi"		
$FMInstallerArguments = "/qn"																								#.msi install arguments (Should not ever need to change)
$FMInstallerDisplayName = "FileMaker Pro"																					#Filemaker display name
$FMInstallerVersion = "v15.3"																								#Full version of Filemaker
$QueryRPath = "HKLM:\SOFTWARE"																								#Registry path for uninstall GUID (v14 onward)
$LogPath = "C:\Logs"																										#Path to logs folder (default is C:\Logs)
$LogFile = "Filemaker.log"																									#Name of the log file
$VersionNumber142 = "234881026"																								#integer for v14.0.2
$VersionNumber143 = "234881027"																								#integer for v14.0.3
$VersionNumber144 = "234881028"																								#integer for v14.0.4
$VersionNumber145 = "234881029"																								#integer for v14.0.5
$VersionNumber151 = "251658241"																								#integer for v15.0.1
$VersionNumber152 = "251658242"																								#integer for v15.0.2
$VersionNumber153 = "251658243"																								#integer for v15.0.3

<# 	
	Checks to see if there is an uninstall key that matches the display name and major version criteria for v14
	If the query comes back with a positive result an uninstall command is run on the ProductID GUID specified above
#>

$Query1 = Get-ItemProperty "$QueryRPath\Microsoft\Windows\CurrentVersion\Uninstall\*" | where {$_.DisplayName -like "$FMInstallerDisplayName*" -and $_.VersionMajor -le "14"}
if ($Query1 -ne $null)
{
	"-------------------------------------------------------" | Out-File $LogPath\$LogFile -append
	$DateTime = Get-Date -f u
	"$DateTime - Version 14 of FileMaker was found; Uninstalling..." | Out-File $LogPath\$LogFile -append
	"An older version of FileMaker was found; Uninstalling..."
	$Uninstallation = Start-Process msiexec -ArgumentList "/X $FMInstallerProductID14 /qn /norestart" -Wait -PassThru
	If (@(0,3010) -contains $Uninstallation.exitcode) 
		{
			$DateTime = Get-Date -f u
			"$DateTime - Removal of $FMInstallerDisplayName v14 has been completed successfully"|Out-File $LogPath\$LogFile -append
			"Removal of $FMInstallerDisplayName v14 has been completed successfully"
		} 
	else 
		{
			$DateTime = Get-Date -f u
			"$DateTime - Removal of $FMInstallerDisplayName v14 failed. Check the application event logs for more information"|Out-File $LogPath\$LogFile -append
			write-error "Removal of $FMInstallerDisplayName v14 failed"
		}
}

<# 	
	Checks if there is an uninstall key that matches the version number query for major versions the same as current, but smaller minor versions i.e 14.4 vs 14.2
	If the query comes back with a positive result an uninstall command is run on the ProductID GUID specified above
#>

$Query2 = Get-ItemProperty "$QueryRPath\Microsoft\Windows\CurrentVersion\Uninstall\*" | where {$_.DisplayName -like "$FMInstallerDisplayName*" -and $_.VersionMajor -le "15" -and $_.Version -lt $VersionNumber152}
if ($Query2 -ne $null)
{
	"-------------------------------------------------------" | Out-File $LogPath\$LogFile -append
	$DateTime = Get-Date -f u
    "$DateTime - An older version of FileMaker v15 was found; Uninstalling..." | Out-File $LogPath\$LogFile -append
	"An older version of FileMaker v15 was found; Uninstalling..."
	$Uninstallation = Start-Process msiexec -ArgumentList "/X $FMInstallerProductID15 /qn /norestart" -Wait -PassThru
	If (@(0,3010) -contains $Uninstallation.exitcode) 
		{
			$DateTime = Get-Date -f u
			"$DateTime - Removal of an older version of $FMInstallerDisplayName v15 has been completed successfully"|Out-File $LogPath\$LogFile -append
			"Removal of an older version of $FMInstallerDisplayName v15 has been completed successfully"
		} 
	else 
		{
			$DateTime = Get-Date -f u
			"$DateTime - Removal of $FMInstallerDisplayName v15 failed. Check the application event logs for more information"|Out-File $LogPath\$LogFile -append
			write-error "Removal of $FMInstallerDisplayName v15 failed"
		}
}

<# 	
	Checks if new version is already installed, and install if not 
#>
$Query3 = Get-ItemProperty "$QueryRPath\Microsoft\Windows\CurrentVersion\Uninstall\*" | where {$_.DisplayName -like "$FMInstallerDisplayName*" -and $_.Version -eq $versionNumber153}
if ($Query3 -eq $null)
{
	$DateTime = Get-Date -f u
    "$DateTime - Installing $FMInstallerDisplayName $FMInstallerVersion" | Out-File $LogPath\$LogFile -append
	"Installing $FMInstallerDisplayName $FMInstallerVersion, please wait..."
	$Installation = Start-Process $FMInstaller -ArgumentList $FMInstallerArguments -Wait -PassThru
	If (@(0,3010) -contains $Installation.exitcode) 
		{
			$DateTime = Get-Date -f u
			"$DateTime - Installation of $FMInstallerDisplayName $FMInstallerVersion has completed successfully"|Out-File $LogPath\$LogFile -append
			"Installation of $FMInstallerDisplayName $FMInstallerVersion has completed successfully"
			"-------------------------------------------------------" | Out-File $LogPath\$LogFile -append
		}
	else 
		{
			$DateTime = Get-Date -f u
			"$DateTime - Installation of $FMInstallerDisplayName $FMInstallerVersion failed. Check the application event logs for more information"|Out-File $LogPath\$LogFile -append
			write-error "Installation of $FMInstallerDisplayName $FMInstallerVersion failed"
			"-------------------------------------------------------" | Out-File $LogPath\$LogFile -append
		}	
}
