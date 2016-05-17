# Filemaker
Powershell - Install script for Filemaker

Installs Filemaker v14 client
Currently has a function "Get-MsiDatabaseVersion" which finds the version number from an msi for variable

The script should find any versions of Filemaker older than the msi version and uninstall it, and then installs the new version if it's not already installed
