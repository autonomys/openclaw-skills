#Requires -Version 7.0
# Download a file from Auto-Drive by CID
# Usage: autodrive-download.ps1 <Cid> [-OutputPath <path>]
# Tries the authenticated API first (handles server-side decompression); falls back to
# the public gateway if the API fails. If no API key is set, uses the gateway directly.
# If OutputPath is omitted, outputs raw bytes to stdout.

param(
    [Parameter(Mandatory)][string]$Cid,
    [string]$OutputPath = ''
)

$ErrorActionPreference = 'Stop'

# Validate CID format
if ($Cid -notmatch '^baf[a-z2-7]+$') {
    [Console]::Error.WriteLine("Error: Invalid CID format: $Cid")
    exit 1
}

$Gateway = "https://gateway.autonomys.xyz"
$ApiBase = "https://mainnet.auto-drive.autonomys.xyz/api"
$ApiKey  = $env:AUTO_DRIVE_API_KEY

$AuthHeaders = @{
    "Authorization"   = "Bearer $ApiKey"
    "X-Auth-Provider" = "apikey"
}

if (-not $OutputPath) {
    # Output raw bytes to stdout (handles both text and binary content)
    $Response = $null
    if ($ApiKey) {
        try {
            $Response = Invoke-WebRequest -Uri "$ApiBase/objects/$Cid/download" -Headers $AuthHeaders
        } catch {
            try {
                $Response = Invoke-WebRequest -Uri "$Gateway/file/$Cid"
            } catch {
                [Console]::Error.WriteLine("Error: Download failed — $($_.Exception.Message)")
                exit 1
            }
        }
    } else {
        try {
            $Response = Invoke-WebRequest -Uri "$Gateway/file/$Cid"
        } catch {
            [Console]::Error.WriteLine("Error: Download failed — $($_.Exception.Message)")
            exit 1
        }
    }
    $Stdout = [Console]::OpenStandardOutput()
    $Stdout.Write($Response.Content, 0, $Response.Content.Length)
    $Stdout.Flush()
} else {
    # Output to file
    if ($ApiKey) {
        try {
            Invoke-WebRequest -Uri "$ApiBase/objects/$Cid/download" `
                -Headers $AuthHeaders `
                -OutFile $OutputPath
            [Console]::Error.WriteLine("Saved to: $OutputPath")
        } catch {
            [Console]::Error.WriteLine("Error: API download failed — trying gateway")
            try {
                Invoke-WebRequest -Uri "$Gateway/file/$Cid" -OutFile $OutputPath
                [Console]::Error.WriteLine("Saved to: $OutputPath (via gateway)")
            } catch {
                [Console]::Error.WriteLine("Error: Gateway download also failed — $($_.Exception.Message)")
                if (Test-Path $OutputPath) { Remove-Item $OutputPath }
                exit 1
            }
        }
    } else {
        try {
            Invoke-WebRequest -Uri "$Gateway/file/$Cid" -OutFile $OutputPath
            [Console]::Error.WriteLine("Saved to: $OutputPath")
        } catch {
            [Console]::Error.WriteLine("Error: Download failed — $($_.Exception.Message)")
            if (Test-Path $OutputPath) { Remove-Item $OutputPath }
            exit 1
        }
    }
}
