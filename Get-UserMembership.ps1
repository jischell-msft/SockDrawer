function Get-UserMembership {
<#
.Synopsis
Get the total number of groups for a given (WindowsIdentity) Principal

.Description
This is one of the tools used to test for token bloat issues. While a group membership count 
greater than 1015 (1024 - 9) does not guarantee there will be an issue, we have yet to 
encounter a case where it has *not* been a problem.

Caveat: If DirectorySearcher cannot resolve in a timely manner, the domain will be returned
as '##External/ Could not resolve'. This does not mean that the next run (one minute later,
one hour later, etc...) will be unable to resolve.

.Example
PS > Get-UserMembership

    Name            Value
    ----            -----
    UserName        CONTOSO\jdoe
    TotalGroups     33
    Membership      {@{UserName=CONTOSO\jdoe; DomainName=--Summary--; Count=33}, @{Use...

Description
-----------
When no principal/ user is specified, the current user name ($env:USERNAME) will be used
for the WindowsIdentity Principal to check.

.Example
PS > Get-UserMembership -Principal jdoe,ejefe

    Name            Value
    ----            -----
    UserName        CONTOSO\jdoe
    TotalGroups     33
    Membership      {@{UserName=CONTOSO\jdoe; DomainName=--Summary--; Count=33}, @{Use...
    UserName        CONTOSO\ejefe
    TotalGroups     42
    Membership      {@{UserName=CONTOSO\ejefe; DomainName=--Summary--; Count=42}, @{Us...

Description
-----------
Specifying more than one principal is allowed, and will return the results as an array, 
in the order entered.

.Parameter Principal
Specifies the user(s) that should be checked.

.Parameter FailureVariable
Specifies the variable that should be used for storing the entries that could not be mapped.

.Notes

The MIT License (MIT) 
Copyright (c) 2016 Jim Schell

Permission is hereby granted, free of charge, to any person obtaining a copy 
of this software and associated documentation files (the "Software"), to deal 
in the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies 
of the Software, and to permit persons to whom the Software is furnished to do 
so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all 
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR 
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, 
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE 
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER 
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, 
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.


#### Name:       Get-UserMembership
#### Author:     Jim Schell
#### Version:    0.2.0
#### License:    MIT License

### Change Log

##### 2016-08-31::0.2.0
- Updated content returned to include groups (SID and SamAccountName)

##### 2016-06-14::0.1.0
- Initial re(creation)
- Added proper help
- Updated name from 'Count-Group' to 'Get-UserMembership'
- Added catch for user disabled/ not found
#>


    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $False)]
        [String[]]
        $Principal = ($env:userName),
        
        [Parameter(Mandatory = $False)]
        [String]
        $FailureVariable
    )
    
    
    Begin{
        $PrincipalResults = $null
        $FailedToMapObject = $null
    }
    Process {
        foreach($Entry in $Principal){
            Try{
                $user = New-Object System.Security.Principal.WindowsIdentity($Entry)
                $userGroupMem = $user.Groups | Group-Object -Property AccountDomainSid | Select-Object count, name, group

                $userResults = New-Object -typeName PSObject ([ordered]@{
                    UserName = $user.name
                    totalGroups = $user.groups.count
                    membership = @()
                })
                $summary = New-Object -typeName PSObject -property ([ordered]@{
                    UserName = $user.name
                    DomainName = "--Summary--"
                    Count = $user.groups.count
                    SID = "--Summary--"
                    GroupSID = @()
                    GroupName = @()
                })
                $userResults.Membership += @($summary)
                # $summaryView = $userResults.Membership.Where({$_.DomainName -eq '--Summary--'})
                foreach($domain in $userGroupMem) {
                    $domainNameResolved = $null
                    if( $($domain.Name) -eq "" ){
                        $domainNameResolved = "Default Groups"
                    }
                    else {
                        $domainNameQuery = [ADSI]"LDAP://<SID=$($domain.Name)>"
                        if( $domainNameQuery.distinguishedName.length -lt 1 ){
                            $domainNameResolved = "##External/ Could not resolve"
                        }
                        else {
                            $domainNameResolved = $domainNameQuery.distinguishedName.replace('DC=','').replace(',','.')
                        }
                    }
                    $membershipByDomain = New-Object -typeName PSObject -property ([ordered]@{
                        UserName = $user.name
                        DomainName = $domainNameResolved
                        Count = $domain.Count
                        DomainSID = $domain.Name
                        GroupSID = @()
                        GroupName = @()
                    })
                    
                    $groupSID = @( $userGroupMem.Where({$_.name -eq $($domain.Name)}) | 
                        Select-Object -expandProperty Group | Select-Object -expandProperty Value )
                    $groupName = @()
                    foreach($sid in $groupSID ){
                        $groupLookup = ([ADSI]"LDAP://<SID=$($sid)>")
                        $groupName += @( $($groupLookup.properties.samaccountname) )
                        Write-Verbose "Group name: $($groupLookup.properties.samaccountname)"
                    }
                    $membershipByDomain.GroupSID = $groupSID
                    $membershipByDomain.GroupName = $groupName
                    $userResults.Membership[0].GroupSID += @( $groupSID )
                    $userResults.Membership[0].GroupName += @( $groupName )
                    
                    $userResults.Membership += @($membershipByDomain)
                }
                $userResults.Membership = $userResults.Membership | Sort-Object Count -Descending 
                $PrincipalResults += @($userResults)
                $user.Dispose()
            }
            Catch {
                Write-Warning "$_"
                Write-Warning "`'$Entry`' - $($_.Exception.InnerException.Message)"
                $FailedToMapObject += @($Entry)
            }
        }
        $PrincipalResults
        
        if($FailureVariable){
            New-Variable -Name $($FailureVariable) -Value $FailedToMapObject -Scope Global -Force
        }
    }
}
