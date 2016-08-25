#Requires -Modules ActiveDirectory
function Get-ADAttribute {
<#
.Synopsis
Get one or more attributes for one or more users accross an entire domain.

.Description
Check the value of specified attributes for one or more users throughout the domain. Useful when checking on non-replicated attributes.

.Example

PS> Get-ADAttribute -Identity "CN=John Doe,OU=Standerd Users,DC=Contoso,DC=com" -Attribute ExtensionAttribute1

ComputerName    Property            PropertyValue   Identity
------------    --------            -------------   --------
DC1.Contoso.com ExtensionAttribute1 4               jdoe
DC2.Contoso.com ExtensionAttribute1 2               jdoe

Description
-----------
Searches the domain of the user invoking the function for the attribute 'ExtensionAttribute1' for the 'John Doe' user, returning the results as shown.

.Example

PS> Get-ADAttribute -Identity jdoe -Attribute lastLogonTimeStamp,LockedOut

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

PS> Get-ADAttribute -Identity jdoe, "CN=Alice Robert,OU=Standerd Users,DC=Contoso,DC=com" -Attribute logonCount

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
Specifies the user(s) to target for the search.

.Parameter Attribute
Specifies the attribute(s) to request from each domain controller, for each identity.

.Parameter Domain
Specifies the domain to search; defaults to the current user's domain ( $env:UserDomain ).

.Notes

Name:       Get-ADAttribute
Author:     Jim Schell
Version:    0.1.1
License:    MIT License

ChangeLog

2016-08-25:0.1.1
- Proper examples added

2016-08-25:0.1.0
- initial creation
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
        $DomainControllerList = @(Get-AdDomainController -Filter * -Server $Domain | 
            Select-Object -ExpandProperty Hostname | Sort-Object )
        $msgDCFoundCount = "Found $($DomainControllerList.Count) DCs for the $($Domain) domain."
        Write-Verbose $msgDCFoundCount
    }
    Process {
        $CompleteResult = @()
        foreach($Object in $Identity){
            $ObjectResult = @()
            Try {
                $ObjectFound = Get-AdUser -Identity $Object
                $msgObjectFound = "Found object with samAccountName of `'$($ObjectFound.samAccountName)`'"
                Write-Verbose $msgObjectFound
                foreach($Property in $Attribute){
                    $PropertyResult = @()
                    Try {
                        $ValidateProperty = Get-AdUser -Identity $ObjectFound -Property $Property | Out-Null
                        foreach($DC in $DomainControllerList){
                            $msgDCSearch = "Now checking `'$Property`' on computer `'$($DC)`'"
                            Write-Verbose $msgDCSearch
                            $DCSpecificResult = Get-AdUser -Identity $ObjectFound -Property $Property -Server $DC
                            $DCPropertyResult = New-Object -TypeName PsObject -Property @{
                                Identity = $($ObjectFound.samAccountName)
                                ComputerName = $DC
                                Property = $Property
                                PropertyValue = $($DCSpecificResult.$($Property))
                            }
                            $PropertyResult += @($DCPropertyResult)
                        }
                    }
                    Catch {
                        "$_"
                    }
                    $ObjectResult += @($PropertyResult)
                }
            }
            Catch {
                "$_"
            }
            $CompleteResult += @( $ObjectResult )
        }
        Return $CompleteResult
    }
}
