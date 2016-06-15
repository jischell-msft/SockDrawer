function Test-PsRemoting {
<#
.Synopsis
Tests the status of PsRemoting for one or more computers

.Description
Tests the status of PsRemoting by establishing a PsRemoting session with the computer(s) 
specified. If an error is caught, or an unexpected value is returned, the return value
will be false.

.Example
PS > Test-PsRemoting
    True
    
Description
-----------
When no computerName is specified, the test will be run against '$env:ComputerName'.

.Example
PS > Test-PsRemoting foo.local, baz.local
    True
    True
    
Description
-----------
Testing PSRemoting for 'foo.local' and 'baz.local' returned True for both computers.

.Parameter ComputerName
Specifies the Computer(s) that should be tested for PSRemoting functionality.

.Link
http://www.leeholmes.com/blog/2009/11/20/testing-for-powershell-remoting-test-psremoting/

.Outputs
Returns status as [Bool] (True|False) for each computer tested.

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


#### Name:       Test-PsRemoting
#### Author:     Jim Schell
#### Version:    0.1.1
#### License:    MIT License

### Change Log

##### 2016-06-10::0.1.1
- Updated help 

##### 2016-06-10::0.1.0
- intial creation
- adapted from http://www.leeholmes.com/blog/2009/11/20/testing-for-powershell-remoting-test-psremoting/
#>


    [CmdletBinding()]
    [OutputType([Bool])]
    Param( 
        [Parameter(Mandatory = $False)]
        [String[]]
        $ComputerName = $env:ComputerName
    ) 
    
    Process {
        ForEach($Computer in $ComputerName) {
            Try { 
                $errorActionPreference = "Stop" 
                $Result = Invoke-Command -ComputerName $Computer { 1 } 
            } 
            Catch { 
                $msgPsRemotingFailure = @"
                
Test-PsRemoting
$_
"@
                Write-Verbose $msgPsRemotingFailure
                Return $False 
            } 

            if($Result -ne 1) { 
                Write-Verbose "Remoting to $Computer returned an unexpected result." 
                Return $False 
            } 
             
            $True     
        }
    }
    
}
 