$Host.UI.RawUI.WindowTitle = "Filemaker Pro Install Script"
<# 	Install Filemaker Pro 14 x64 for Westlake Boys' High School
	
	To change in next version:
	-Change DisplayVersion query to Version query (better integer for math-ing)
	-Sanitize script for any versions (should only need to make one change per version)
	-Add proper exit logging for troubleshooting
    -Add another clause for major version changes
	-Fix Get-MsiDatabaseVersion as it fails to pass a readable string
#>

<#	Functions
#>
function Get-MsiDatabaseVersion {
    param ([IO.FileInfo] $FilePath)
    try {
        $windowsInstaller = New-Object -com WindowsInstaller.Installer
        $database = $windowsInstaller.GetType().InvokeMember(
                "OpenDatabase", "InvokeMethod", $Null, 
                $windowsInstaller, @($FilePath.FullName, 0))
        $q = "SELECT Value FROM Property WHERE Property = 'ProductVersion'"
        $View = $database.GetType().InvokeMember(
                "OpenView", "InvokeMethod", $Null, $database, ($q))
        $View.GetType().InvokeMember("Execute", "InvokeMethod", $Null, $View, $Null)
        $record = $View.GetType().InvokeMember(
                "Fetch", "InvokeMethod", $Null, $View, $Null)
        $productVersion = $record.GetType().InvokeMember(
                "StringData", "GetProperty", $Null, $record, 1)
        $View.GetType().InvokeMember("Close", "InvokeMethod", $Null, $View, $Null)
        return $productVersion} 
	catch {
        throw "Failed to get MSI file version the error was: {0}." -f $_
    }
}

Function Install-Software {
	param ($File,$Arguments)
	$Install = Start-Process $File -ArgumentList $Arguments -Wait -PassThru
	If($Install.ExitCode -eq 0){
		Write-Host "Installation was OK" -ForegroundColor GREEN|Tee-Object -filepath $LogPath\$LogFile -append
		}
	Else{
		Write-Host "Installation failed $("$Install.ExitCode")" -ForegroundColor RED|Tee-Object -filepath $LogPath\$LogFile -append
		}
}

Function Parse-IniFile ($file) {
  $ini = @{}

 # Create a default section if none exist in the file. Like a java prop file.
 $section = "NO_SECTION"
 $ini[$section] = @{}

  switch -regex -file $file {
    "^\[(.+)\]$" {
      $section = $matches[1].Trim()
      $ini[$section] = @{}
    }
    "^\s*([^#].+?)\s*=\s*(.*)" {
      $name,$value = $matches[1..2]
      # skip comments that start with semicolon:
      if (!($name.StartsWith(";"))) {
        $ini[$section][$name] = $value.Trim()
      }
    }
  }
  $ini
}

<#	User defined variables
	Change these as necessary
#>
$FMInstallerVersion = Get-MsiDatabaseVersion "\\westlake.local\shared\admininstall\Filemaker14\CurrentVersion\Files\FileMaker Pro 14 Advanced.msi"		#Version number of new version
$FMInstallerProductID13 = "{4B2ABFE4-3A1D-4FFB-B6E8-A256ADFB0D7A}"															#GUID of version 13 to remove (Changes between major versions)
$FMInstallerProductID14 = "{593FFA0C-970C-4867-BEAE-3D7D7F3F69CF}"															#GUID of version 14 (Changes between major versions)

<#	Script defined variables
	These should never need to change
#>
$CUR_DATE=get-date -f "yyyy-MM-dd"																							#current date in a nice format for logging
$FMInstaller = "\\westlake.local\shared\admininstall\Filemaker14\CurrentVersion\Files\FileMaker Pro 14 Advanced.msi"		#location of new version's .msi (the files here will be updated by Ronald)
$FMInstallerArguments = "/qn"																								#.msi install arguments (Should not ever need to change)
$FMInstallerDisplayName = "FileMaker Pro"																					#Filemaker display name
$QueryRPath = "HKLM:SOFTWARE"																								#Registry path for uninstall GUID
$OldQueryRPath = "HKLM:SOFTWARE\Wow6432Node"																				#Registry path for 32bit installs
$LogPath = "C:\Logs"																										#Path to logs folder (default is C:\Logs)
$LogFile = "Filemaker.log"																									#Name of the log file
$VersionNumber142 = "234881026"																								#integer for v14.2.0
$VersionNumber143 = "234881027"																								#integer for v14.3.0
$VersionNumber144 = "234881028"																								#integer for v14.4.0

<# 	Checks to see if there is an uninstall key that matches the display name and major version criteria for v13
	If the query comes back with a positive result an uninstall command is run on the ProductID GUID specified above
#>
$Query1 = Get-ItemProperty "$OldQueryRPath\Microsoft\Windows\CurrentVersion\Uninstall\*" | where {$_.DisplayName -like "$FMInstallerDisplayName*" -and $_.VersionMajor -le "13"}
if ($Query1 -ne $null)
{
	"Removing version 13 of $FMInstallerDisplayName, please wait..."|Tee-Object -filepath $LogPath\$LogFile -append
	$Uninstallation = Start-Process msiexec -ArgumentList "/X $FMInstallerProductID13 /qn /norestart" -Wait -PassThru
	If (@(0,3010) -contains $Uninstallation.exitcode) 
		{"Removal of $FMInstallerDisplayName v13 has been completed on $CUR_DATE!"|Tee-Object -filepath $LogPath\$LogFile -append} 
	else 
		{write-error "Something went wrong"}
	#Install-Software -file msiexec -Arguments "/X $FMInstallerProductID /qn /norestart"
}

<# 	Checks if there is an uninstall key that matches the version number query for major versions the same as current, but smaller minor versions i.e 14.4 vs 14.2
	If the query comes back with a positive result an uninstall command is run on the ProductID GUID specified above
#>
$Query2 = Get-ItemProperty "$QueryRPath\Microsoft\Windows\CurrentVersion\Uninstall\*" | where {$_.DisplayName -like "$FMInstallerDisplayName*" -and $_.Version -lt $VersionNumber144}
if ($Query2 -ne $null)
{
	"Found an older version of Filemaker v14 installed"|Tee-Object -filepath $LogPath\$LogFile -append
	"Removing older version of $FMInstallerDisplayName, please wait..."|Tee-Object -filepath $LogPath\$LogFile -append
	$Uninstallation = Start-Process msiexec -ArgumentList "/X $FMInstallerProductID14 /qn /norestart" -Wait -PassThru
	If (@(0,3010) -contains $Uninstallation.exitcode) 
		{"Removal of $FMInstallerDisplayName has been completed on $CUR_DATE!"|Tee-Object -filepath $LogPath\$LogFile -append} 
	else 
		{write-error "Something went wrong"}
	#Install-Software -file msiexec -Arguments "/X $FMInstallerProductID /qn /norestart"
}

<# 	Checks if new version is already installed, and install if not 
#>
$Query3 = Get-ItemProperty "$QueryRPath\Microsoft\Windows\CurrentVersion\Uninstall\*" | where {$_.DisplayName -like "$FMInstallerDisplayName*" -and $_.DisplayVersion -eq "14.0.4.0"}
if ($Query3 -eq $null)
{
	"Installing $FMInstallerDisplayName $FMInstallerVersion, please wait..."|Tee-Object -filepath $LogPath\$LogFile -append
	$Installation = Start-Process $FMInstaller -ArgumentList $FMInstallerArguments -Wait -PassThru
	If (@(0,3010) -contains $Installation.exitcode) 
		{"Installation of $FMInstallerDisplayName $FMInstallerVersion has completed on $CUR_DATE!"|Tee-Object -filepath $LogPath\$LogFile -append} 
	else 
		{write-error "Something went wrong"}
	#Install-Software -file $FMInstaller -Arguments $FMInstallerArguments
	
}

#Install-Software Function example
# Install-Software -file C:\share\7z920-x64.msi -Arguments /qn