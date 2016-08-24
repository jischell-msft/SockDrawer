function Get-UserByAlias {
<#
.Synopsis
Get users by alias (samAccountName)

.Description
Using ADSI, get users based on samAccountName.

.Example

PS> Get-UserByAlias -samAccountName jdoe

Description
-----------
Creates new CSV file in the present working directory, containing details of the 'jdoe' user object.

.Example

PS> Get-UserByAlias -alias jdoe,abob,fflam -path c:\MyPath

Description
-----------
Creates new CSV file in the 'c:\MyPath' directory, containing details of the 'jdoe', 'abob' and 'fflam' user objects.

.Example

PS> Get-Content .\myAliasList.txt | Get-UserByAlias -path c:\MyPath

Description
-----------
Reads the content of the 'myAliasList' file to the pipeline, get-userByAlias creates a new CSV file in the 'c:\MyPath' directory, containing details of the user objects in the initial text file.


.Parameter samAccountName
Specifies the samAccountName (or names) to find

.Parameter NoGlobalCatalog
Switch parameter, when used the query will only use LDAP/389 instead of the default GC/3268

.Parameter Path
Specifies the path where the output files will be written. Default value is the present working directory.

.Parameter Delimiter
Specifies the delimiter to use for the CSV output. Default value is the semicolon ';' character.

.Parameter PassThru
Switch parameter, when used the results will be passed to the console or specified object.

.Notes

Name:       Get-UserByAlias
Author:     Jim Schell
Version:    0.2.0
License:    MIT License

ChangeLog

2016-08-24:0.2.0
- updated to GC default, specifying which domain no longer necessary

2016-08-23:0.1.1
- easier formating of manager details
- added another example

2016-08-23:0.1.0
- initial creation

#>    
    
    
    [CmdletBinding()]
    [OutputType([System.IO.File])]
    [OutputType([PsCustomObject])]
    Param(
        [Parameter( Mandatory = $True, 
            ValueFromPipeline = $True )]
        [Alias('Alias')]
        [String[]]
        $samAccountName,
        
        [Parameter( Mandatory = $False )]
        [Switch]
        $NoGlobalCatalog,
                
        [Parameter( Mandatory = $False )]
        [String]
        $Path = $PWD,
        
        [Parameter(Mandatory = $false)]
        [String]
        $Delimiter = ',',
        
        [Parameter( Mandatory = $False )]
        [Switch]
        $PassThru
    )
    
    Begin {
        $UsersFound = @()
        
        $shortTime = [dateTime]::Now.ToString("s")
        $shortTimeFileFriendly = $shortTime.Replace(':','.')
        
        $fileName = "$($shortTimeFileFriendly)-getUserByAlias.csv"
        $filePath = Join-Path -Path $Path -ChildPath $fileName
        
        $currentDomain = [System.DirectoryServices.ActiveDirectory.Domain]::GetCurrentDomain().name
        
        $ldapPath = [ADSI]"LDAP://$($currentDomain):389"
        $gcPath = [ADSI]"GC://$($currentDomain):3268"
        
        if($NoGlobalCatalog){
            $searchPath = $ldapPath
        }
        else{
            $searchPath = $gcPath
        }
        
        $PropertiesForCSV = @(
            "alias"
            "name"
            "mail"
            "title"
            "manager"
            "managerMail"
            "department"
            "office"
        )
    }
    Process {
        $samAccountNameUnique = $samAccountName | Select-Object -Unique
        foreach( $object in $samAccountNameUnique ){
            $objectFilter = "(&(objectCategory=person)(objectClass=person)(samAccountName=$($object)))"
            $search = [adsiSearcher]($searchPath)
            $search.Filter = $objectFilter
            $searchResult = $search.FindOne()
            
            if($searchResult.Count -eq 1){
                $UserManagerPath = [ADSI]"LDAP://$($searchResult.Properties.manager)"
                $UserManagerAlias = $($UserManagerPath.Properties.samaccountname)
                $UserManagerMail = $($UserManagerPath.Properties.mail)
                
                $UserFound = New-Object -TypeName PsObject -Property ([ordered]@{
                    alias = $($searchResult.Properties.samaccountname)
                    name = $($searchResult.Properties.name)
                    mail = $($searchResult.Properties.mail)
                    title = $($searchResult.Properties.title)
                    manager = $UserManagerAlias
                    managerMail = $UserManagerMail
                    department = $($searchResult.Properties.department)
                    office = $($searchResult.Properties.physicaldeliveryofficename)
                })
                $UsersFound += @( $UserFound )    
            }
            else{
                $msgDidNotFindObject = "Could not find user object with samAccountName of `'$($object)`'"
                Write-Verbose $msgDidNotFindObject
            }
        }
        
        $UsersFound | Select-Object $PropertiesForCSV |
            ConvertTo-CSV -Delimiter $Delimiter -NoTypeInformation | 
            Out-File -FilePath $filePath -Encoding UTF8
            
        if( $PassThru ){
            return $UsersFound
        }
    }
}