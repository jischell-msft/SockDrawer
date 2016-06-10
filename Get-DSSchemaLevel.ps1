#Requires -Module ActiveDirectory
function Get-DSSchemaLevel {
<#
.Synopsis
Get the schema level of both Active Directory and Exchange, and when both were 
last modified.

.Description
Get the schema level of both Active Directory and Exchange, and when both were 
last modified. Also returns the server that was queried

.Example
    PS > Get-DSSchemaLevel
    ADSchema                : 57
    ADSchema Modified       : 2016/02/30 13:58:43
    ExchangeSchema          : 9001
    ExchangeSchema Modified : 2010/04/31 12:49:07
    Server                  : fooBaz001.local.example.com
    
Description
-----------
Returns the current schema level of the current domain.

.Parameter Server
Specifies the server to query for schema infomration

.Inputs
Name of server (or domain) to get the schema version of AD and Exchange.

.Outputs
Returns an object with ADSchema level, ADSchema modified time, ExchangeSchema 
level, ExchangeSchema modified time, and server queried.

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

#### Name:       Get-DSschemaLevel
#### Author:     Jim Schell
#### Version:    0.1.3
#### License:    MIT

### Change Log

###### 2016-06-03::0.1.3
- update help, include basics (scrubbing old scripts)
- update param 'server', add outputType
###### 2016-04-21::0.1.2
- Add try/catch for potential of exchange objects not being loaded
###### 2016-04-21::0.1.1
- Update object returned to include modified time for AD Schema and Exchange Schema
- Update object returned to use [ordered] for the hashtable
###### 2016-04-21::0.1.0
- Initial creation
#>


    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    Param(
        [Parameter(Mandatory = $false,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true )]
        [String]
        $Server
    )
    
    $paramServer = @{}
    if($server){
        $paramServer += @{ server = $server }
    }
    
    $namingContext = get-adRootDSE @paramServer
    $server = $namingContext.dnsHostName
    
    $configNC = $namingContext.configurationNamingContext
    
    $schemaDN = "CN=Schema,$($configNC)"
    $exchSchemaDN = "CN=ms-exch-schema-version-pt,CN=Schema,$($configNC)"
    
    try {
        $adSchemaObj = get-adObject -identity $schemaDN -property objectVersion, modified @paramServer
    }
    catch [Microsoft.ActiveDirectory.Management.ADIdentityNotFoundException] {
        $msgObjNotFound = "Could not find $($_.targetObject), something is very wrong"
        Write-Warning $msgObjNotFound
        break
    }
    try {
        $exchSchemaObj = get-adObject -identity $exchSchemaDN -property rangeUpper, modified @paramServer
    }
    catch [Microsoft.ActiveDirectory.Management.ADIdentityNotFoundException] {
        $msgObjNotFound = "Could not find $($_.targetObject)"
        Write-Warning $msgObjNotFound
    }
    
    $results = New-Object -typeName PSObject -Property ([ordered]@{
        ADSchema = "$($adSchemaObj.objectVersion)"
        'ADSchema Modified' = "$($adSchemaObj.modified)"
        ExchangeSchema = "$($exchSchemaObj.rangeUpper)"
        'ExchangeSchema Modified' = "$($exchSchemaObj.modified)"
        Server = "$($server)"
    })
    
    $results
}