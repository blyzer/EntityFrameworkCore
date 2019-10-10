param(
  [Parameter(Mandatory=$true)][string] $InputPath,           # Full path to directory where Symbols.NuGet packages to be checked are stored
  [Parameter(Mandatory=$true)][string] $ExtractPath,         # Full path to directory where the packages will be extracted during validation
  [Parameter(Mandatory=$true)][string] $SourceLinkToolPath,  # Full path to directory where dotnet SourceLink CLI was installed
  [Parameter(Mandatory=$true)][string] $GHRepoName,          # GitHub name of the repo including the Org. E.g., dotnet/arcade
  [Parameter(Mandatory=$true)][string] $GHCommit             # GitHub commit SHA used to build the packages
)

# Cache/HashMap (File -> Exist flag) used to consult whether a file exist 
# in the repository at a specific commit point. This is populated by inserting
# all files present in the repo at a specific commit point.
$global:RepoFiles = @{}

$ValidatePackage = {
  param( 
    [string] $PackagePath                                 # Full path to a Symbols.NuGet package
  )

  # Ensure input file exist
  if (!(Test-Path $PackagePath)) {
    throw "Input file does not exist: $PackagePath"
  }

  # Extensions for which we'll look for SourceLink information
  # For now we'll only care about Portable & Embedded PDBs
  $RelevantExtensions = @(".dll", ".exe", ".pdb")
 
  Write-Host -NoNewLine "Validating" ([System.IO.Path]::GetFileName($PackagePath)) "... "

  $PackageId = [System.IO.Path]::GetFileNameWithoutExtension($PackagePath)
  $ExtractPath = Join-Path -Path $using:ExtractPath -ChildPath $PackageId
  $FailedFiles = 0

  Add-Type -AssemblyName System.IO.Compression.FileSystem

  [System.IO.Directory]::CreateDirectory($ExtractPath);

  $zip = [System.IO.Compression.ZipFile]::OpenRead($PackagePath)

  $zip.Entries | 
    Where-Object {$RelevantExtensions -contains [System.IO.Path]::GetExtension($_.Name)} |
      ForEach-Object {
        $FileName = $_.FullName
        $Extension = [System.IO.Path]::GetExtension($_.Name)
        $FakeName = -Join((New-Guid), $Extension)
        $TargetFile = Join-Path -Path $ExtractPath -ChildPath $FakeName 

        # We ignore resource DLLs
        if ($FileName.EndsWith(".resources.dll")) {
          return
        }

        [System.IO.Compression.ZipFileExtensions]::ExtractToFile($_, $TargetFile, $true)

        $ValidateFile = {
          param( 
            [string] $FullPath,                                # Full path to the module that has to be checked
            [string] $RealPath,
            [ref] $FailedFiles
          )

          # Makes easier to reference `sourcelink cli`
          Push-Location $using:SourceLinkToolPath

          $SourceLinkInfos = .\sourcelink.exe print-urls $FullPath | Out-String

          if ($LASTEXITCODE -eq 0 -and -not ([string]::IsNullOrEmpty($SourceLinkInfos))) {
            $NumFailedLinks = 0

            # We only care about Http addresses
            $Matches = (Select-String '(http[s]?)(:\/\/)([^\s,]+)' -Input $SourceLinkInfos -AllMatches).Matches

            if ($Matches.Count -ne 0) {
              $Matches.Value |
                ForEach-Object {
                  $Link = $_
                  $CommitUrl = -Join("https://raw.githubusercontent.com/", $using:GHRepoName, "/", $using:GHCommit, "/")
                  $FilePath = $Link.Replace($CommitUrl, "")
                  $Status = 200
                  $Cache = $using:RepoFiles

                  if ( !($Cache.ContainsKey($FilePath)) ) {
                    try {
                      $Uri = $Link -as [System.URI]
                    
                      # Only GitHub links are valid
                      if ($Uri.AbsoluteURI -ne $null -and $Uri.Host -match "github") {
                        $Status = (Invoke-WebRequest -Uri $Link -UseBasicParsing -Method HEAD -TimeoutSec 5).StatusCode
                      }
                      else {
                        $Status = 0
                      }
                    }
                    catch {
                      $Status = 0
                    }
                  }

                  if ($Status -ne 200) {
                    if ($NumFailedLinks -eq 0) {
                      if ($FailedFiles.Value -eq 0) {
                        Write-Host
                      }

                      Write-Host "`tFile $RealPath has broken links:"
                    }

                    Write-Host "`t`tFailed to retrieve $Link"

                    $NumFailedLinks++
                  }
                }
            }

            if ($NumFailedLinks -ne 0) {
              $FailedFiles.value++
              $global:LASTEXITCODE = 1
            }
          }

          Pop-Location
        }
      
        &$ValidateFile $TargetFile $FileName ([ref]$FailedFiles)
      }

  $zip.Dispose()

  if ($FailedFiles -eq 0) {
    Write-Host "Passed."
  }
}

function ValidateSourceLinkLinks {
  if (!($GHRepoName -Match "^[^\s\/]+/[^\s\/]+$")) {
    Write-Host "GHRepoName should be in the format <org>/<repo>"
    $global:LASTEXITCODE = 1
    return
  }

  if (!($GHCommit -Match "^[0-9a-fA-F]{40}$")) {
    Write-Host "GHCommit should be a 40 chars hexadecimal string"
    $global:LASTEXITCODE = 1
    return
  }

  $RepoTreeURL = -Join("https://api.github.com/repos/", $GHRepoName, "/git/trees/", $GHCommit, "?recursive=1")
  $CodeExtensions = @(".cs", ".vb", ".fs", ".fsi", ".fsx", ".fsscript")

  try {
    # Retrieve the list of files in the repo at that particular commit point and store them in the RepoFiles hash
    $Data = Invoke-WebRequest $RepoTreeURL | ConvertFrom-Json | Select-Object -ExpandProperty tree
  
    foreach ($file in $Data) {
      $Extension = [System.IO.Path]::GetExtension($file.path)

      if ($CodeExtensions.Contains($Extension)) {
        $RepoFiles[$file.path] = 1
      }
    }
  }
  catch {
    Write-Host "Problems downloading the list of files from the repo. Url used: $RepoTreeURL"
    $global:LASTEXITCODE = 1
    return
  }
  
  if (Test-Path $ExtractPath) {
    Remove-Item $ExtractPath -Force -Recurse -ErrorAction SilentlyContinue
  }

  # Process each NuGet package in parallel
  $Jobs = @()
  Get-ChildItem "$InputPath\*.symbols.nupkg" |
    ForEach-Object {
      $Jobs += Start-Job -ScriptBlock $ValidatePackage -ArgumentList $_.FullName
    }

  foreach ($Job in $Jobs) {
    Wait-Job -Id $Job.Id | Receive-Job
  }
}

Measure-Command { ValidateSourceLinkLinks }

# SIG # Begin signature block
# MIIFuQYJKoZIhvcNAQcCoIIFqjCCBaYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUGcQ71DCx3r/yGEaXFJ5tflzr
# o3qgggNIMIIDRDCCAiygAwIBAgIQLBkaaHaluIJLTW0br70HDDANBgkqhkiG9w0B
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
# gjcCARUwIwYJKoZIhvcNAQkEMRYEFEy1xeRpJb5Ci4utFtlvIF3irjywMA0GCSqG
# SIb3DQEBAQUABIIBAFfTCd7lGSwBKrxuOF22imzGUUTlWtiRUnxpMupOzvrEx9tZ
# hqGWbPFxFN4cBhzUUE7mNWI+XpJVrfPPD4qa7vmvkhygxgjWUVFAqxsABtVRJxMp
# IdYc19cd2uLSEAX6eqXhPBo993H/4rA5GIIzbOT/g0On/QanT32fwwIkQ9TBB60S
# fgcyI02G61BOOfuqBQqBfSPvxAciJGDi5LkbMsTymYnORSvZ6ISRsJohGSObHzkz
# e3LVYhHb2EJtzWk1gtumWdGb+HI2eAm4b8h/sP3jo3Jr1bqmimjZR2I14ggkJf/7
# bZ05rDQzdGeDlyRxacoZnMfHfZWUTwBtZO0R5WE=
# SIG # End signature block
