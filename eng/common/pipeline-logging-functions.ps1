# Source for this file was taken from https://github.com/microsoft/azure-pipelines-task-lib/blob/11c9439d4af17e6475d9fe058e6b2e03914d17e6/powershell/VstsTaskSdk/LoggingCommandFunctions.ps1 and modified.

# NOTE: You should not be calling these method directly as they are likely to change.  Instead you should be calling the Write-Pipeline* functions defined in tools.ps1

$script:loggingCommandPrefix = '##vso['
$script:loggingCommandEscapeMappings = @( # TODO: WHAT ABOUT "="? WHAT ABOUT "%"?
    New-Object psobject -Property @{ Token = ';' ; Replacement = '%3B' }
    New-Object psobject -Property @{ Token = "`r" ; Replacement = '%0D' }
    New-Object psobject -Property @{ Token = "`n" ; Replacement = '%0A' }
    New-Object psobject -Property @{ Token = "]" ; Replacement = '%5D' }
)
# TODO: BUG: Escape % ???
# TODO: Add test to verify don't need to escape "=".

function Write-PipelineTelemetryError {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Category,
        [Parameter(Mandatory = $true)]
        [string]$Message,
        [Parameter(Mandatory = $false)]
        [string]$Type = 'error',
        [string]$ErrCode,
        [string]$SourcePath,
        [string]$LineNumber,
        [string]$ColumnNumber,
        [switch]$AsOutput)

        $PSBoundParameters.Remove("Category") | Out-Null

        $Message = "(NETCORE_ENGINEERING_TELEMETRY=$Category) $Message"
        $PSBoundParameters.Remove("Message") | Out-Null
        $PSBoundParameters.Add("Message", $Message)

        Write-PipelineTaskError @PSBoundParameters
}

function Write-PipelineTaskError {
    [CmdletBinding()]
    param(
      [Parameter(Mandatory = $true)]
      [string]$Message,
      [Parameter(Mandatory = $false)]
      [string]$Type = 'error',
      [string]$ErrCode,
      [string]$SourcePath,
      [string]$LineNumber,
      [string]$ColumnNumber,
      [switch]$AsOutput)
  
      if(!$ci) {
        if($Type -eq 'error') {
          Write-Host $Message -ForegroundColor Red
          return
        }
        elseif ($Type -eq 'warning') {
          Write-Host $Message -ForegroundColor Yellow
          return
        }
      }
  
      if(($Type -ne 'error') -and ($Type -ne 'warning')) {
        Write-Host $Message
        return
      }
      if(-not $PSBoundParameters.ContainsKey('Type')) {
        $PSBoundParameters.Add('Type', 'error')
      }
      Write-LogIssue @PSBoundParameters
  }
  
  function Write-PipelineSetVariable {
    [CmdletBinding()]
    param(
      [Parameter(Mandatory = $true)]
      [string]$Name,
      [string]$Value,
      [switch]$Secret,
      [switch]$AsOutput,
      [bool]$IsMultiJobVariable=$true)

      if($ci) {
        Write-LoggingCommand -Area 'task' -Event 'setvariable' -Data $Value -Properties @{
          'variable' = $Name
          'isSecret' = $Secret
          'isOutput' = $IsMultiJobVariable
        } -AsOutput:$AsOutput
      }
  }
  
  function Write-PipelinePrependPath {
    [CmdletBinding()]
    param(
      [Parameter(Mandatory=$true)]
      [string]$Path,
      [switch]$AsOutput)
      if($ci) {
        Write-LoggingCommand -Area 'task' -Event 'prependpath' -Data $Path -AsOutput:$AsOutput
      }
  }

<########################################
# Private functions.
########################################>
function Format-LoggingCommandData {
    [CmdletBinding()]
    param([string]$Value, [switch]$Reverse)

    if (!$Value) {
        return ''
    }

    if (!$Reverse) {
        foreach ($mapping in $script:loggingCommandEscapeMappings) {
            $Value = $Value.Replace($mapping.Token, $mapping.Replacement)
        }
    } else {
        for ($i = $script:loggingCommandEscapeMappings.Length - 1 ; $i -ge 0 ; $i--) {
            $mapping = $script:loggingCommandEscapeMappings[$i]
            $Value = $Value.Replace($mapping.Replacement, $mapping.Token)
        }
    }

    return $Value
}

function Format-LoggingCommand {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Area,
        [Parameter(Mandatory = $true)]
        [string]$Event,
        [string]$Data,
        [hashtable]$Properties)

    # Append the preamble.
    [System.Text.StringBuilder]$sb = New-Object -TypeName System.Text.StringBuilder
    $null = $sb.Append($script:loggingCommandPrefix).Append($Area).Append('.').Append($Event)

    # Append the properties.
    if ($Properties) {
        $first = $true
        foreach ($key in $Properties.Keys) {
            [string]$value = Format-LoggingCommandData $Properties[$key]
            if ($value) {
                if ($first) {
                    $null = $sb.Append(' ')
                    $first = $false
                } else {
                    $null = $sb.Append(';')
                }

                $null = $sb.Append("$key=$value")
            }
        }
    }

    # Append the tail and output the value.
    $Data = Format-LoggingCommandData $Data
    $sb.Append(']').Append($Data).ToString()
}

function Write-LoggingCommand {
    [CmdletBinding(DefaultParameterSetName = 'Parameters')]
    param(
        [Parameter(Mandatory = $true, ParameterSetName = 'Parameters')]
        [string]$Area,
        [Parameter(Mandatory = $true, ParameterSetName = 'Parameters')]
        [string]$Event,
        [Parameter(ParameterSetName = 'Parameters')]
        [string]$Data,
        [Parameter(ParameterSetName = 'Parameters')]
        [hashtable]$Properties,
        [Parameter(Mandatory = $true, ParameterSetName = 'Object')]
        $Command,
        [switch]$AsOutput)

    if ($PSCmdlet.ParameterSetName -eq 'Object') {
        Write-LoggingCommand -Area $Command.Area -Event $Command.Event -Data $Command.Data -Properties $Command.Properties -AsOutput:$AsOutput
        return
    }

    $command = Format-LoggingCommand -Area $Area -Event $Event -Data $Data -Properties $Properties
    if ($AsOutput) {
        $command
    } else {
        Write-Host $command
    }
}

function Write-LogIssue {
    [CmdletBinding()]
    param(
        [ValidateSet('warning', 'error')]
        [Parameter(Mandatory = $true)]
        [string]$Type,
        [string]$Message,
        [string]$ErrCode,
        [string]$SourcePath,
        [string]$LineNumber,
        [string]$ColumnNumber,
        [switch]$AsOutput)

    $command = Format-LoggingCommand -Area 'task' -Event 'logissue' -Data $Message -Properties @{
            'type' = $Type
            'code' = $ErrCode
            'sourcepath' = $SourcePath
            'linenumber' = $LineNumber
            'columnnumber' = $ColumnNumber
        }
    if ($AsOutput) {
        return $command
    }

    if ($Type -eq 'error') {
        $foregroundColor = $host.PrivateData.ErrorForegroundColor
        $backgroundColor = $host.PrivateData.ErrorBackgroundColor
        if ($foregroundColor -isnot [System.ConsoleColor] -or $backgroundColor -isnot [System.ConsoleColor]) {
            $foregroundColor = [System.ConsoleColor]::Red
            $backgroundColor = [System.ConsoleColor]::Black
        }
    } else {
        $foregroundColor = $host.PrivateData.WarningForegroundColor
        $backgroundColor = $host.PrivateData.WarningBackgroundColor
        if ($foregroundColor -isnot [System.ConsoleColor] -or $backgroundColor -isnot [System.ConsoleColor]) {
            $foregroundColor = [System.ConsoleColor]::Yellow
            $backgroundColor = [System.ConsoleColor]::Black
        }
    }

    Write-Host $command -ForegroundColor $foregroundColor -BackgroundColor $backgroundColor
}
# SIG # Begin signature block
# MIIFuQYJKoZIhvcNAQcCoIIFqjCCBaYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUYp2IEVVKo8rVv/KFAhL6ZQiN
# KDagggNIMIIDRDCCAiygAwIBAgIQLBkaaHaluIJLTW0br70HDDANBgkqhkiG9w0B
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
# gjcCARUwIwYJKoZIhvcNAQkEMRYEFBSfshpR2CsSeYTCt1YHF5naXitYMA0GCSqG
# SIb3DQEBAQUABIIBAEw1qbIyEvcIuVpoKMWdW4CMen9PigmV46Kg+ZUk6xvAJqTC
# ZnzLhjQ3MQ+2lX/zaSOU/VPw5uYeZjb8E534LZcCYWGtkVIFGjZc8Z8z6lhf+F2I
# gykXyXugfofz1EkYx4rNGPlA/MEZwNtsjr3BudayeBlhRTPCfaNXnDEpIqyWZebE
# 8o7/f3G3etCV1i/tu5VHxMFx5PysITkouZfeFxc17Qc2hgNpZWUZwgxnY7gY/Pn+
# NH89ZZhsCg0/bPtb+uEk8e8964XJicbukOsK554lSgeyeEfzarXh6yeg/Lvb03BJ
# 6qHFympsxteohsgIFocVsWTslaEkiuGGqB5+CMk=
# SIG # End signature block
