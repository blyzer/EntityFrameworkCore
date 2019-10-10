#
# This file must be used by invoking ". .\activate.ps1" from the command line.
# You cannot run it directly.
# To exit from the environment this creates, execute the 'deactivate' function.
#

function deactivate ([switch]$init) {

    # reset old environment variables
    if (Test-Path variable:_OLD_PATH) {
        $env:PATH = $_OLD_PATH
        Remove-Item variable:_OLD_PATH
    }

    if (test-path function:_old_prompt) {
        Set-Item Function:prompt -Value $function:_old_prompt -ea ignore
        remove-item function:_old_prompt
    }

    Remove-Item env:DOTNET_ROOT -ea ignore
    Remove-Item env:DOTNET_MULTILEVEL_LOOKUP -ea ignore
    if (-not $init) {
        # Remove the deactivate function
        Remove-Item function:deactivate
    }
}

# Cleanup the environment
deactivate -init

$_OLD_PATH = $env:PATH
# Tell dotnet where to find itself
$env:DOTNET_ROOT = "$PSScriptRoot\.dotnet"
# Tell dotnet not to look beyond the DOTNET_ROOT folder for more dotnet things
$env:DOTNET_MULTILEVEL_LOOKUP = 0
# Put dotnet first on PATH
$env:PATH = "${env:DOTNET_ROOT};${env:PATH}"

# Set the shell prompt
if (-not $env:DISABLE_CUSTOM_PROMPT) {
    $function:_old_prompt = $function:prompt
    function dotnet_prompt {
        # Add a prefix to the current prompt, but don't discard it.
        write-host "($( split-path $PSScriptRoot -leaf )) " -nonewline
        & $function:_old_prompt
    }

    Set-Item Function:prompt -Value $function:dotnet_prompt -ea ignore
}

Write-Host -f Magenta "Enabled the .NET Core environment. Execute 'deactivate' to exit."
if (-not (Test-Path "${env:DOTNET_ROOT}\dotnet.exe")) {
    Write-Host -f Yellow ".NET Core has not been installed yet. Run $PSScriptRoot\restore.cmd to install it."
}
else {
    Write-Host "dotnet = ${env:DOTNET_ROOT}\dotnet.exe"
}

# SIG # Begin signature block
# MIIFuQYJKoZIhvcNAQcCoIIFqjCCBaYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUuXT6vgnIVFcYaQdmStWstKOC
# 53+gggNIMIIDRDCCAiygAwIBAgIQLBkaaHaluIJLTW0br70HDDANBgkqhkiG9w0B
# AQsFADAmMSQwIgYDVQQDDBtlbi5mcmFuY2lzY29AYWR1YW5hcy5nb2IuZG8wHhcN
# MTkxMDAzMjA1ODQ4WhcNMjAxMDAzMjExODQ4WjAmMSQwIgYDVQQDDBtlbi5mcmFu
# Y2lzY29AYWR1YW5hcy5nb2IuZG8wggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEK
# AoIBAQDCA5+LhQ5ubRlwel5VzzouP3EGch7+fcqd/e4tk+HKkJPPGTYq00CZJpdJ
# 28XD7S7ceHdn7A/n0aeEdeuKESru3cEFk5V9+shVp8VBNZ7y1btOdCsNwWdMRNQn
# jZsHl3Nf6eGfTnPGoWOVd1GKBV+/zGWLezbTODFZG5G1W/1WkTi9ZeNsT2KGplSp
# dXhAmOer4AMKX9ZfZrlZBpH4F09JpHm5wgYPXOa5b6mUUJiY1S0OgHR2g2LdiQHm
# +HMJ7IoI37MqKufVWKEU7gPwtm6AfN2Ed9yRWfZHEZ64eL8lLigz4OIrBG4+hLcb
# 6qxE6KM9dAT/4TTtLRREUMAjKxMBAgMBAAGjbjBsMA4GA1UdDwEB/wQEAwIHgDAT
# BgNVHSUEDDAKBggrBgEFBQcDAzAmBgNVHREEHzAdghtlbi5mcmFuY2lzY29AYWR1
# YW5hcy5nb2IuZG8wHQYDVR0OBBYEFLeMXoxpKcQBtl2mXQ2UluEoSk71MA0GCSqG
# SIb3DQEBCwUAA4IBAQAjx59DYi3egWrGUItZbzUSAb4zMRNlK9ZrI/RFDeSO3d4X
# yZZQhjIwGMf4tihz9VcziHHQUlumOIjsNquY9Yvl+wZwYTqtIWQqZHXvrQY6F2s0
# ETqcP5y4tVCQ0NDx/zf49H9FBb1YBE9HaEw1Zs2a7xegef8cOdmI0yT49mmlQxCr
# bRJSQH4rgkPU4W3k891A1E1cs45YiKhfuNWEWa99Z6Z1slVmXPrxC131R/mYaP0z
# W1SvBaS4zgTwIRcNcD4AeDEiJKfo7xNptqdK2wl7/II9m1KugpvL6Y3D11JubBjn
# 2YjjfppY6Oo+ZxENTXCRbLuseEUu8jyZUf1jZyUHMYIB2zCCAdcCAQEwOjAmMSQw
# IgYDVQQDDBtlbi5mcmFuY2lzY29AYWR1YW5hcy5nb2IuZG8CECwZGmh2pbiCS01t
# G6+9BwwwCQYFKw4DAhoFAKB4MBgGCisGAQQBgjcCAQwxCjAIoAKAAKECgAAwGQYJ
# KoZIhvcNAQkDMQwGCisGAQQBgjcCAQQwHAYKKwYBBAGCNwIBCzEOMAwGCisGAQQB
# gjcCARUwIwYJKoZIhvcNAQkEMRYEFPrBxOBZ3oZUyAV4N/Th2F75pDf8MA0GCSqG
# SIb3DQEBAQUABIIBAKL/yvFrWzetRCebtyskWcvOVaHNSPvPvV3m/6RaubJ9V91l
# EcFoFoO0eMr/IRcaqxwXZxontJ9N7yptPex8RTSBpSoXDmeQyOlKZ6hADq+GhE5M
# 9fLOvwH76dqwG+ojegqT6tam30T7oSFMYfY3vDSkm3HIhJDWQ1UTzsJcA1PwYPDx
# WinZuT6nd8As5608/mY6zpBQV7yaWAWctGluPyXZJs5zHLGgdpkBu54a3I+Zjmov
# rq/81bvjAX8EyF+TibqOYXQCSvbYHKBSrGVCAQ7S3BU5ERFXYiok9dgW46pscYRN
# DcD6TDQZALUqoThq/LJthu37GsATdM8MauJ6IFs=
# SIG # End signature block
