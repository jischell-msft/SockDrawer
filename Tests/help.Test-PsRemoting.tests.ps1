<#
.Synopsis
Basic test for validating help has been filled in correctly

.Description
Test for synopsis, description, examples, non-default parameters being present 
in the help. Also checks for name, author, version and license.

.Example
PS > invoke-pester help.FunctionName.tests.ps1

Description
-----------
Tests if the function specified has properly completed help.

.Link
 https://github.com/juneb/PesterTDD/blob/master/Module.Help.Tests.ps1

.Link
 https://github.com/devblackops/POSHOrigin/blob/master/Tests/Help.tests.ps1

.Link
 http://www.lazywinadmin.com/2016/05/using-pester-to-test-your-comment-based.html


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

#### Name:      help.FunctionName.tests.ps1
#### Author:    Jim Schell
#### Version:   0.1.3
#### License    MIT

### Change Log

##### 2016-06-06::0.1.3
- updated to allow for tests to be in directory other than where the test is invoked. If the test is in a directory named 'test' or 'tests', will go up one level, search recursively for [functionName].ps1

##### 2016-06-06::0.1.2
- update to have help, reworked to be easier reading/ flow

##### 2016-05-31::0.1.1
- update to look for name, author, version, and license

##### 2016-05-27::0.1.0
- initial creation

#>

$functionName = "Test-PsRemoting"

if($psScriptRoot -match ("\\Test\\|\\Tests\\") ){
    $functionPath = Get-ChildItem -path $psScriptRoot\.. -filter "$($functionName).ps1" -recurse
    . "$(functionPath.FullName)"
}
else {
    . "$($psScriptRoot)\$($functionName).ps1"
}


Describe "Test help for $functionName" {

    # If help is not found, synopsis in auto-generated help is the syntax diagram
    It "should not be auto-generated" {
        $Help.Synopsis | Should Not BeLike '*`[`<CommonParameters`>`]*'
    }

    # Should be a description for every function
    It "gets description for $functionName" {
        $Help.Description | Should Not BeNullOrEmpty
    }

    # Should be at least one example
    It "gets example code from $functionName" {
        ($Help.Examples.Example | Select-Object -First 1).Code | Should Not BeNullOrEmpty
    }

    # Should be at least one example description
    It "gets example help from $functionName" {
        ($Help.Examples.Example.Remarks | Select-Object -First 1).Text | Should Not BeNullOrEmpty
    }

    Context "Test parameter help for $functionName" {
        
        $commonParam = @(
        'Debug'
        'ErrorAction'
        'ErrorVariable'
        'InformationAction'
        'InformationVariable'
        'OutBuffer'
        'OutVariable'
        'PipelineVariable'
        'Verbose'
        'WarningAction'
        'WarningVariable' 
        )

        $parameters = (Get-Command -Name $functionName).ParameterSets.Parameters | 
            Sort-Object -Property Name -Unique | Where-Object {$_.name -notIn $commonParam}
        
        $parameterNames = $parameters.Name
        $HelpParameterNames = $Help.Parameters.Parameter.Name | Sort-Object -Unique

        foreach ($parameter in $parameters) {
            $parameterName = $parameter.Name
            $parameterHelp = $Help.parameters.parameter | Where-Object Name -EQ $parameterName

            # Should be a description for every parameter
            It "gets help for parameter: $parameterName : in $functionName" {
                $parameterHelp.Description.Text | Should Not BeNullOrEmpty
            }

            # Required value in Help should match IsMandatory property of parameter
            It "help for $parameterName parameter in $functionName has correct Mandatory value" {
                $codeMandatory = $parameter.IsMandatory.toString()
                $parameterHelp.Required | Should Be $codeMandatory
            }

            foreach ($helpParm in $HelpParameterNames) {
                # Shouldn't find extra parameters in help.
                It "finds help parameter in code: $helpParm" {
                    $helpParm -in $parameterNames | Should Be $true
                }
            }
        }
    }
    
     # Notes should exist, contain name of function, author, version, and license
    Context "Test notes for `'$functionName`'" {
        
        $notes = @(($help.AlertSet.Alert.Text) -split '\n')
        
        It "Notes attribute `'name`' should contain $functionName" {
            $notesName = $notes | Select-String -pattern "Name:*"
            $notesName | Should Match "Name:\s*$($functionName)"
        }
        
        It "Notes attribute `'author`' should exist" {
            $notesAuthor = $notes | Select-String -pattern "Author:"
            $notesAuthor | Should Match "Author:*"
        }
        
        It "Notes attribute `'version`' should be in System.Version format" {
            $notesVersion = $notes | Select-String -pattern "Version:"
            $notesVersion | Should Match 'Version:\s*(\d{1,9}\.){2,4}'
        }
        
        It "Notes attribute `'license`' should exist" {
            $notesLicense = $notes | Select-String -pattern "License:"
            $notesLicense | Should Match 'License:*'
        }
        
    }
    
}