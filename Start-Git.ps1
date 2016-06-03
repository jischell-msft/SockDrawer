function Start-Git {
<#

.Notes

##### 2016-06-03::0.1.0
- initial creation
- wrapper for starting posh-git with the correct settings 
#>

    # Remove PSReadline :( it can't play nicely with posh-git
    if( Get-Module PSReadline){
        Remove-Module PSReadline
    }
    
    # Load posh-git module from current directory
    Import-Module posh-git

    # Set up a simple prompt, adding the git prompt parts inside git repos
    function global:prompt {
        $realLASTEXITCODE = $LASTEXITCODE

        Write-Host($pwd.ProviderPath) # -nonewline
        Write-Host "PS" -nonewline
        Write-VcsStatus

        $global:LASTEXITCODE = $realLASTEXITCODE
        return " > "
    }

    Start-SshAgent -Quiet

}