function Get-ADOrgUnitACL {
<#
https://blogs.technet.microsoft.com/ashleymcglone/2013/03/25/active-directory-ou-permissions-report-free-powershell-script-download/


#>    

    
    [CmdletBinding()]
    [OutputType([System.IO.File])]
    Param(
        [Parameter( Mandatory = $False )]
        [String]
        $Domain = $env:UserDomain,
        
        [Parameter( Mandatory = $False)]
        [String]
        $Path = $PWD
    )
    Begin {
        $ACLReport = @()
        $schemaIDGUID = @{}
        $OrgUnitList = @()
        
        $fileName = "$($Domain)-ACLReport.csv"
        $filePath = Join-Path -Path $Path -ChildPath $fileName
        
        $rootDSE = Get-ADRootDSE -Server $Domain
        $adDomain = Get-ADDomain -Server $Domain
        #---Enumerate the rights
        $paramBaseRights = @{
            SearchBase = $($rootDSE.schemaNamingContext)
            LDAPFilter = '(schemaIDGUID=*)'
            Properties = @(
                'name'
                'schemaIDGUID'
            )
            Server = $Domain
            ErrorAction = 'SilentlyContinue'
        }
        
        Get-ADObject @paramBaseRights| ForEach-Object {
            $schemaIDGUID.add([System.GUID]$_.schemaIDGUID,$_.name)
        }
        
        $paramExtendedRights = @{
            SearchBase = "CN=Extended-Rights,$($rootDSE.configurationNamingContext)"
            LDAPFilter = '(objectClass=controlAccessRight)'
            Properties = @(
                'name'
                'rightsGUID'
            )
            Server = $Domain
            ErrorAction = 'SilentlyContinue'
        }
    
        Get-ADObject @paramExtendedRights | ForEach-Object {
            $schemaIDGUID.add([System.GUID]$_.rightsGUID,$_.name)
        }
        Write-Verbose "Found `'$($schemaIDGUID.Count)`' rights."
        #---Enumerate the OrgUnits
        $paramCommon = @{
            Server = $Domain
        }
        $paramRootContainers = @{
            Server = $Domain
            SearchBase = $($adDomain.DistinguishedName)
            SearchScope = 'OneLevel'
            LDAPFilter = '(objectClass=container)'
        }
        
        $OrgUnitList += @( $($adDomain.distinguishedName) )
        $OrgUnitList += @( Get-ADOrganizationalUnit -Filter * @paramCommon | 
            Select-Object -expandProperty DistinguishedName )
        $OrgUnitList += @( Get-ADObject @paramRootContainers | 
            Select-Object -expandProperty DistinguishedName )
        Write-Verbose "Found `'$($OrgUnitList.Count)`' OUs."
    }
    Process {
        foreach( $OrgUnit in $OrgUnitList){
            Write-Verbose "Processing $OrgUnit..."
            $ACLReport += Get-ACL -Path "AD:\$OrgUnit" | 
                Select-Object -expandProperty Access | 
                Select-Object @{name='organizationalUnit';expression={$OrgUnit} }, @{name='objectTypeName';expression={if($_.objectType.ToString() -eq '00000000-0000-0000-0000-000000000000'){'All'} else{ $schemaIDGUID.Item($_.objectType) } } }, @{ name='inheritedObjectTypeName';expression={ $schemaIDGUID.Item($_.inheritedObjectType) }}, *
        }
        
        $ACLReport | Export-CSV -Path $filePath -NoTypeInformation
    }
}
