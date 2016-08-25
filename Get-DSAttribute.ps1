function Get-DSAttribute {
<#
.Synopsis
Get one or more attributes for one or more users accross an entire domain. Does not require the Active Directory module.

.Description
Check the value of specified attributes for one or more users throughout the domain. Useful when checking on non-replicated attributes.

.Example

PS> Get-DSAttribute -Identity jdoe -Attribute ExtensionAttribute1

ComputerName    Property            PropertyValue   Identity
------------    --------            -------------   --------
DC1.Contoso.com ExtensionAttribute1 4               jdoe
DC2.Contoso.com ExtensionAttribute1 2               jdoe

Description
-----------
Searches the domain of the user invoking the function for the attribute 'ExtensionAttribute1' for the 'John Doe' user, returning the results as shown.

.Example

PS> Get-DSAttribute -Identity jdoe -Attribute lastLogonTimeStamp,LockedOut

ComputerName    Property            PropertyValue       Identity
------------    --------            -------------       --------
DC1.Contoso.com lastLogonTimeStamp  131415926535897932  jdoe
DC2.Contoso.com lastLogonTimeStamp  138462643383279502  jdoe
DC1.Contoso.com LockedOut           False               jdoe
DC2.Contoso.com LockedOut           False               jdoe

Description
-----------
Searches the domain of the user invoking the function for the attributes 'lastLogonTimeStamp' and 'LockedOut' for the 'John Doe' user, returning the results as shown.

.Example

PS> Get-DSAttribute -Identity jdoe,alicer -Attribute logonCount

ComputerName    Property    PropertyValue   Identity
------------    --------    -------------   --------
DC1.Contoso.com logonCount  12              jdoe
DC2.Contoso.com logonCount  34              jdoe
DC1.Contoso.com logonCount  56              alicer
DC2.Contoso.com logonCount  78              alicer

Description
-----------
Searches the domain of the user invoking the function for the attributes 'logonCount' for the 'John Doe' and 'Alice Robert' users, returning the results as shown.

.Parameter Identity
Specifies the user(s) samAccountName(s) to target for the search.

.Parameter Attribute
Specifies the attribute(s) to request from each domain controller, for each identity.

.Parameter Domain
Specifies the domain to search; defaults to the current user's domain ( $env:UserDomain ).

.Notes

Name:       Get-DSAttribute
Author:     Jim Schell
Version:    0.1.0
License:    MIT License

ChangeLog

2016-08-25:0.1.0
- initial creation, modification of the 'Get-ADAttribute' function which requires AD module
#>

    
    [CmdletBinding()]
    [OutputType([PsCustomObject])]
    Param(
        [Parameter( Mandatory = $True,
            ValueFromPipeline = $True )]
        [String[]]
        $Identity,
        
        [Parameter( Mandatory = $True )]
        [String[]]
        $Attribute,
        
        [Parameter( Mandatory = $False )]
        [String]
        $Domain = $env:UserDomain
    )
    
    
    Begin {
        $DomainContext = New-Object System.DirectoryServices.ActiveDirectory.DirectoryContext("Domain", $Domain)
        $DomainEntry = [System.DirectoryServices.ActiveDirectory.Domain]::GetDomain($DomainContext)
        $DomainName = $DomainEntry.Name
        $DomainControllerList = @($DomainEntry.DomainControllers | 
            Select-Object -ExpandProperty Name | Sort-Object )
        $DomainEntry.Dispose()
        $ldapDomainPath = "LDAP://$DomainName:389"
        $msgDCFoundCount = "Found $($DomainControllerList.Count) DCs for the $($Domain) domain."
        Write-Verbose $msgDCFoundCount
    }
    Process {
        $CompleteResult = @()
        foreach($Object in $Identity){
            $ObjectResult = @()
            $ObjectFilter =  "(&(objectCategory=person)(objectClass=person)(samaccountname=$($Object)))"
        
            $BasicSearch = [adsisearcher]($ldapDomainPath)
            $BasicSearch.Filter = $ObjectFilter
            $ObjectFound = $BasicSearch.FindOne()
            $BasicSearch.Dispose()
            if($ObjectFound.Count -eq 1){
                $msgObjectFound = "Found object with samAccountName of `'$($ObjectFound.properties.samaccountname)`'"
                Write-Verbose $msgObjectFound
                foreach($Property in $Attribute){
                    $PropertyLDAPFriendly = $Property.ToLower()
                    $PropertyResult = @()
                    
                    foreach($DC in $DomainControllerList){
                        $msgDCSearch = "Now checking `'$Property`' on computer `'$($DC)`'"
                        Write-Verbose $msgDCSearch
                        $DCSpecificPath = "LDAP://$($DC):389"
                        $DCSearch = [adsisearcher]($DCSpecificPath)
                        $DCSearch.Filter = $ObjectFilter
                        $DCSpecificResult = $DCSearch.FindOne()
                        $DCPropertyResult = New-Object -TypeName PsObject -Property @{
                            Identity = $($ObjectFound.properties.samaccountname)
                            ComputerName = $DC
                            Property = $Property
                            PropertyValue = $($DCSpecificResult.properties.$($PropertyLDAPFriendly))
                        }
                        $DCSearch.Dispose()
                        $PropertyResult += @($DCPropertyResult)
                    }
                    $ObjectResult += @($PropertyResult)
                }
            }
            $CompleteResult += @( $ObjectResult )
        }
        Return $CompleteResult
    }
}
