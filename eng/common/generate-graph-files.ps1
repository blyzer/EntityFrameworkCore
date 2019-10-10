Param(
  [Parameter(Mandatory=$true)][string] $barToken,       # Token generated at https://maestro-prod.westus2.cloudapp.azure.com/Account/Tokens
  [Parameter(Mandatory=$true)][string] $gitHubPat,      # GitHub personal access token from https://github.com/settings/tokens (no auth scopes needed)
  [Parameter(Mandatory=$true)][string] $azdoPat,        # Azure Dev Ops tokens from https://dev.azure.com/dnceng/_details/security/tokens (code read scope needed)
  [Parameter(Mandatory=$true)][string] $outputFolder,   # Where the graphviz.txt file will be created
  [string] $darcVersion = '1.1.0-beta.19175.6',         # darc's version
  [string] $graphvizVersion = '2.38',                   # GraphViz version
  [switch] $includeToolset                              # Whether the graph should include toolset dependencies or not. i.e. arcade, optimization. For more about
                                                        # toolset dependencies see https://github.com/dotnet/arcade/blob/master/Documentation/Darc.md#toolset-vs-product-dependencies
)

$ErrorActionPreference = "Stop"
. $PSScriptRoot\tools.ps1

Import-Module -Name (Join-Path $PSScriptRoot "native\CommonLibrary.psm1")

function CheckExitCode ([string]$stage)
{
  $exitCode = $LASTEXITCODE
  if ($exitCode  -ne 0) {
    Write-Host "Something failed in stage: '$stage'. Check for errors above. Exiting now..."
    ExitWithExitCode $exitCode
  }
}

try {
  Push-Location $PSScriptRoot

  Write-Host "Installing darc..."
  . .\darc-init.ps1 -darcVersion $darcVersion
  CheckExitCode "Running darc-init"

  $engCommonBaseDir = Join-Path $PSScriptRoot "native\"
  $graphvizInstallDir = CommonLibrary\Get-NativeInstallDirectory
  $nativeToolBaseUri = "https://netcorenativeassets.blob.core.windows.net/resource-packages/external"
  $installBin = Join-Path $graphvizInstallDir "bin"

  Write-Host "Installing dot..."
  .\native\install-tool.ps1 -ToolName graphviz -InstallPath $installBin -BaseUri $nativeToolBaseUri -CommonLibraryDirectory $engCommonBaseDir -Version $graphvizVersion -Verbose

  $darcExe = "$env:USERPROFILE\.dotnet\tools"
  $darcExe = Resolve-Path "$darcExe\darc.exe"

  Create-Directory $outputFolder

  # Generate 3 graph descriptions:
  # 1. Flat with coherency information
  # 2. Graphviz (dot) file
  # 3. Standard dependency graph
  $graphVizFilePath = "$outputFolder\graphviz.txt"
  $graphVizImageFilePath = "$outputFolder\graph.png"
  $normalGraphFilePath = "$outputFolder\graph-full.txt"
  $flatGraphFilePath = "$outputFolder\graph-flat.txt"
  $baseOptions = @( "--github-pat", "$gitHubPat", "--azdev-pat", "$azdoPat", "--password", "$barToken" )

  if ($includeToolset) {
    Write-Host "Toolsets will be included in the graph..."
    $baseOptions += @( "--include-toolset" )
  }

  Write-Host "Generating standard dependency graph..."
  & "$darcExe" get-dependency-graph @baseOptions --output-file $normalGraphFilePath
  CheckExitCode "Generating normal dependency graph"

  Write-Host "Generating flat dependency graph and graphviz file..."
  & "$darcExe" get-dependency-graph @baseOptions --flat --coherency --graphviz $graphVizFilePath --output-file $flatGraphFilePath
  CheckExitCode "Generating flat and graphviz dependency graph"

  Write-Host "Generating graph image $graphVizFilePath"
  $dotFilePath = Join-Path $installBin "graphviz\$graphvizVersion\release\bin\dot.exe"
  & "$dotFilePath" -Tpng -o"$graphVizImageFilePath" "$graphVizFilePath"
  CheckExitCode "Generating graphviz image"

  Write-Host "'$graphVizFilePath', '$flatGraphFilePath', '$normalGraphFilePath' and '$graphVizImageFilePath' created!"
}
catch {
  if (!$includeToolset) {
    Write-Host "This might be a toolset repo which includes only toolset dependencies. " -NoNewline -ForegroundColor Yellow
    Write-Host "Since -includeToolset is not set there is no graph to create. Include -includeToolset and try again..." -ForegroundColor Yellow
  }
  Write-Host $_
  Write-Host $_.Exception
  Write-Host $_.ScriptStackTrace
  ExitWithExitCode 1
} finally {
    Pop-Location
}
# SIG # Begin signature block
# MIIFuQYJKoZIhvcNAQcCoIIFqjCCBaYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUzMT2vRRt9+X4fd4BYd6xXH9H
# 4ymgggNIMIIDRDCCAiygAwIBAgIQLBkaaHaluIJLTW0br70HDDANBgkqhkiG9w0B
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
# gjcCARUwIwYJKoZIhvcNAQkEMRYEFHlq8+6cgR1lO5jzNVsR787SC6FBMA0GCSqG
# SIb3DQEBAQUABIIBADThMLzHHuIgQ0xov7dvNyE/Nljwl82d93v7Nm4Yohf6SkDE
# b9I3xi4YdDxB9QB07wK3fKDD1bDeYWTx448kFTp4kMu6ggp/PlCWwhNcZq8TQubI
# uX48ckOHP1+LOUEUxhaCtAfHy7kXy3RNWsItiAIVbP6D8R8efXfTs0Nfy71EWx69
# NfmdW6DPQhkVVhIaXxCSBjgZBhbcE4MYJqVBayTOS8JlY2uAN7b/GU1FzQ1imv+W
# m5Ql4Q0rCP0Q6y73B7Dqg+pL3kMqDKlonuseCutrXuUxMbXIm2+htIBESlQImpS0
# 0D31fo+nYHS4uj8DUCIWmK1TqCJ0Xoayc0n3+nU=
# SIG # End signature block
