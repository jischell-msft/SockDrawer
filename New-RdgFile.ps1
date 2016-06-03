function new-rdgFile {
<#
.Synopsis

.Description
 http://blogs.msdn.com/b/stuartleeks/archive/2014/11/20/importing-windows-azure-cloud-services-into-remote-desktop-connection-manager-rdc-man.aspx 

.Parameter fileName

.Parameter domain

.Parameter userName

.Parameter computerName

.Parameter credProfileName

.Parameter rdSize

.Parameter outConsole

.Example

.Notes

Name:       new-rdgFile
Author:     Jim Schell
Version:    0.1.2 
License:    MIT License

Change Log
2016-05-25::0.1.2
-add param for changing screen size
2016-05-25::0.1.1 
-fixing mismatch on var names
2016-05-25::0.1.0
-finally put something together, long brewing idea to fruition
-here strings are easier to fiddle with then xml sorcery
#>


    [CmdletBinding()]
    Param(
        [Parameter()]
        [String]
        $fileName,
        
        [Parameter(Mandatory = $True)]
        [ValidateNotNullOrEmpty()]
        [String]
        $domain,
        
        [Parameter(Mandatory = $True)]
        [ValidateNotNullOrEmpty()]
        [String]
        $userName,
        
        [Parameter(Mandatory = $True)]
        [ValidateNotNullOrEmpty()]
        [array[]]
        $computerName,
        
        [Parameter(Mandatory = $false)]
        [String[]]
        $credProfileName,
        
        [Parameter()]
        [ValidateSet("1400x900","1366x768","800x600","1024x768","1280x1024","1600x1200","1920x1200")]
        $rdSize = "1400x900",
        
        [Parameter()]
        [String]
        $Path = $pwd,
        
        [Parameter()]
        [switch]$outConsole
    )
    
    $domainShortName = $domain.Split('.')[0]
    
    if($credProfileName.length -lt 1){
        $credProfileName = "$($domainShortName)"
    }
    
    
    $credUserName = $userName
    $credDomain = $domainShortName
    
    $groupName = $domainShortName
    
    if($fileName.length -lt 1){
        $fileName = "RDG-$($domainShortName)"
    }
    
    $rdSizeExpanded = $rdSize.Replace("x"," x ")
    
    #---start of xml as here strings... <smh>
    $rdgFileOpen = @"
<?xml version="1.0" encoding="utf-8"?>
<RDCMan programVersion="2.7" schemaVersion="3">
  <file>
    <properties>
      <expanded>True</expanded>
      <name>$fileName</name>
    </properties>
"@

    $rdgFileClose = @"

  </file>
  <connected />
  <favorites />
  <recentlyUsed />
</RDCMan>
"@
    
    $rdgRemoteDesktopSettings = @"

    <remoteDesktop inherit="None">
      <size>$rdSizeExpanded</size>
      <sameSizeAsClientArea>False</sameSizeAsClientArea>
      <fullScreen>False</fullScreen>
      <colorDepth>24</colorDepth>
    </remoteDesktop>
"@
    
    $rdgLocalResourceSettings = @"
    
    <localResources inherit="None">
      <keyboardHook>Remote</keyboardHook>
      <redirectClipboard>True</redirectClipboard>
      <redirectSmartCards>True</redirectSmartCards>
    </localResources>
"@
    
    $rdgCredentialsProfilesOpen = @"

    <credentialsProfiles>
"@

    $rdgCredentialsProfilesClose = @"

    </credentialsProfiles>
"@

    $rdgCredentialsProfile = @"

      <credentialsProfile inherit="None">
        <profileName scope="Local">$credProfileName</profileName>
        <userName>$credUserName</userName>
        <password />
        <domain>$credDomain</domain>
      </credentialsProfile>
"@
    
    $rdgGroupStart = @"

    <group>
      <properties>
        <expanded>False</expanded>
        <name>$groupName</name>
      </properties>
"@
    
    $rdgGroupCredentials = @"

      <logonCredentials inherit="none">
        <profileName scope="File">$credProfileName</profileName>
      </logonCredentials>
"@

    $rdgGroupEnd = @"

    </group>
"@
    #---End of xml as here strings
    
    $outputFile = $rdgFileOpen + $rdgRemoteDesktopSettings + $rdgLocalResourceSettings
    $outputFile += $rdgCredentialsProfilesOpen + $rdgCredentialsProfile + $rdgCredentialsProfilesClose
    $outputFile += $rdgGroupStart + $rdgGroupCredentials
    
    foreach($computer in $computerName){
        $computerShort = $computer.Split('.')[0]
        
        $serverDisplayName = $computerShort
        $serverStdName = $computer
        
        $rdgServer = @"

      <server>
        <properties>
          <displayName>$serverDisplayName</displayName>
          <name>$serverStdName</name>
        </properties>
      </server>
"@
        $outputFile += $rdgServer
        
    }
    
    $outputFile += $rdgGroupEnd
    $outputFile += $rdgFileClose
    
    if($outConsole){
        $outputFile
    }
    else{
        $outputFile | Out-File -FilePath "$($path)\$($fileName).rdg" -Encoding utf8 
    }
    
}