[CmdletBinding(PositionalBinding=$false)]
Param(
  [string] $verbosity = "minimal",
  [string] $architecture = "",
  [string] $version = "Latest",
  [string] $runtime = "dotnet"
)

. $PSScriptRoot\tools.ps1

$dotnetRoot = Join-Path $RepoRoot ".dotnet"

$installdir = $dotnetRoot
try {
    if ($architecture -and $architecture.Trim() -eq "x86") {
        $installdir = Join-Path $installdir "x86"
    }
   InstallDotNet $installdir $version $architecture $runtime $true
} 
catch {
  Write-Host $_
  Write-Host $_.Exception
  Write-Host $_.ScriptStackTrace
  ExitWithExitCode 1
}

ExitWithExitCode 0

# SIG # Begin signature block
# MIIFuQYJKoZIhvcNAQcCoIIFqjCCBaYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUiW7fsUJjBcay3XnbwB0lBJIZ
# NuigggNIMIIDRDCCAiygAwIBAgIQLBkaaHaluIJLTW0br70HDDANBgkqhkiG9w0B
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
# gjcCARUwIwYJKoZIhvcNAQkEMRYEFDygPCHE5xm5dkmFZtIwCdkixdREMA0GCSqG
# SIb3DQEBAQUABIIBACtaWCrwttX8lS6Xb2JqwQM4VLlEuyEfA0Pp5Ph+UgCkkyXo
# JWUDtMu0eIL7zlqo93PaDJVIrrjBWOY9/J1LiSRwINztFtAnGCCttLtBGJO+LccR
# i9cwjAT+4pimrYZOoeeV4hATOIkYayOzqi7fWcEta6eMmzqKwTrkIIhn+R2GEsHg
# gLN5Hp8RHzq2627+OYBjG0MQN7oc3WmYmNQpS2PrbvlzVkUGar8SgaLUZA0QwFAy
# Aga0Xzswj41ksu68KEzecKDt86CkJC5Fq+tKvzfzPkRgdam2xelw1JoVumVhbQCg
# 9iZx4I0yS2cmEHtzZiYKHKmL3RjYnxT25lnseVY=
# SIG # End signature block
