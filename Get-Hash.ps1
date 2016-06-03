function Get-Hash {
<#
2016-06-03::0.1.1
- add begin/ process/ end blocks
2016-06-02::0.1.0
- initial creation
#>


    [CmdletBinding()]
    [OutputType([String])]
    Param(
        [Parameter( Mandatory = $true,
            ValueFromPipeline = $true )]
        [string]
        $inputString,

        [Parameter( Mandatory = $false )]
        [ValidateSet("SHA1","SHA256","SHA384","SHA512","MD5")]
        [string]
        $Algorithm = "SHA1"
    )
    begin {
        $utf8 = new-object -TypeName System.Text.UTF8Encoding

        $sha512 = new-object -typeName System.Security.Cryptography.SHA512CryptoServiceProvider
        $sha384 = new-object -typeName System.Security.Cryptography.SHA384CryptoServiceProvider
        $sha256 = new-object -typeName System.Security.Cryptography.SHA256CryptoServiceProvider
        $sha1 = new-object -typeName System.Security.Cryptography.SHA1CryptoServiceProvider
        $md5 = new-object -typeName System.Security.Cryptography.MD5CryptoServiceProvider
    }
    process {
        $algorithmToUse = (Get-Variable $algorithm).value

        $hash = [System.BitConverter]::ToString($algorithmToUse.ComputeHash($utf8.GetBytes($inputString)))
        $hash = $hash.Replace('-','')
        $hash        
    }
    end {
        $sha512.Dispose()
        $sha384.Dispose()
        $sha256.Dispose()
        $sha1.Dispose()
        $md5.Dispose()
    }
    
}