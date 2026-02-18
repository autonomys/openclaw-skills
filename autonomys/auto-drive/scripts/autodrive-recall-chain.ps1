#Requires -Version 7.0
# Traverse the memory chain from a CID, downloading each experience
# Usage: autodrive-recall-chain.ps1 [-Cid <cid>] [-Limit <N>] [-OutputDir <dir>]
# Output: Each experience as JSON to stdout (newest first), or to files in output dir
# Env: AUTO_DRIVE_API_KEY (required — memories are stored compressed by default and
#      the authenticated API decompresses server-side)

param(
    [string]$Cid       = '',
    [int]$Limit        = 50,
    [string]$OutputDir = ''
)

$ErrorActionPreference = 'Stop'

$ApiBase = "https://mainnet.auto-drive.autonomys.xyz/api"
$Gateway = "https://gateway.autonomys.xyz"
$ApiKey  = $env:AUTO_DRIVE_API_KEY

# If no CID provided, try state file
if (-not $Cid) {
    $WorkspaceRoot = if ($env:OPENCLAW_WORKSPACE) { $env:OPENCLAW_WORKSPACE } else {
        [IO.Path]::Combine($HOME, ".openclaw", "workspace")
    }
    $StateFile = [IO.Path]::Combine($WorkspaceRoot, "memory", "autodrive-state.json")
    if (Test-Path $StateFile -PathType Leaf) {
        try {
            $State = Get-Content $StateFile -Raw | ConvertFrom-Json
            $Cid   = $State.lastCid
        } catch { }
    }
    if (-not $Cid) {
        [Console]::Error.WriteLine("Error: No CID provided and no state file found.")
        [Console]::Error.WriteLine("Usage: autodrive-recall-chain.ps1 [-Cid <cid>] [-Limit <N>] [-OutputDir <dir>]")
        exit 1
    }
}

# Validate CID format
if ($Cid -notmatch '^baf[a-z2-7]+$') {
    [Console]::Error.WriteLine("Error: Invalid CID format: $Cid")
    exit 1
}

if (-not $ApiKey) {
    [Console]::Error.WriteLine("Error: AUTO_DRIVE_API_KEY not set.")
    [Console]::Error.WriteLine("Get a free key at https://ai3.storage (sign in with Google/GitHub → Developers → Create API Key)")
    exit 1
}

if ($OutputDir) {
    if (-not (Test-Path $OutputDir)) { New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null }
}

$AuthHeaders = @{
    "Authorization"   = "Bearer $ApiKey"
    "X-Auth-Provider" = "apikey"
}

[Console]::Error.WriteLine("=== MEMORY CHAIN RESURRECTION ===")
[Console]::Error.WriteLine("Starting from: $Cid")
[Console]::Error.WriteLine("")

$Count   = 0
$Visited = [Collections.Generic.HashSet[string]]::new()

while ($Cid -and $Cid -ne 'null' -and $Count -lt $Limit) {
    # Cycle detection — HashSet.Add returns false if the element already exists
    if (-not $Visited.Add($Cid)) {
        [Console]::Error.WriteLine("Warning: Cycle detected at CID $Cid — stopping traversal")
        break
    }

    # Download: try authenticated API first (handles decompression), fall back to gateway
    $ExperienceRaw = $null
    try {
        $ExperienceRaw = Invoke-RestMethod -Uri "$ApiBase/objects/$Cid/download" `
            -Headers $AuthHeaders
    } catch {
        try {
            $ExperienceRaw = Invoke-RestMethod -Uri "$Gateway/file/$Cid"
        } catch {
            [Console]::Error.WriteLine("Error: Failed to download CID $Cid — chain broken at depth $($Count + 1)")
            break
        }
    }

    if ($null -eq $ExperienceRaw) {
        [Console]::Error.WriteLine("Error: Failed to download CID $Cid — chain broken at depth $($Count + 1)")
        break
    }

    # Re-serialize to compact JSON string (Invoke-RestMethod parsed the response into a PSObject)
    $ExperienceJson = $ExperienceRaw | ConvertTo-Json -Depth 20 -Compress

    if ($OutputDir) {
        $FileName = "$("{0:D4}" -f $Count)-$Cid.json"
        $ExperienceJson | Set-Content ([IO.Path]::Combine($OutputDir, $FileName)) -Encoding UTF8
        [Console]::Error.WriteLine("[$Count] Saved $Cid")
    } else {
        Write-Output $ExperienceJson
    }

    # Follow the chain — check header.previousCid first (Autonomys Agents format),
    # then fall back to root-level previousCid for backward compatibility
    $NextCid = if ($ExperienceRaw.header -and $ExperienceRaw.header.previousCid) {
        $ExperienceRaw.header.previousCid
    } elseif ($ExperienceRaw.previousCid) {
        $ExperienceRaw.previousCid
    } else {
        $null
    }

    # Validate next CID in chain
    if ($NextCid -and $NextCid -ne 'null' -and $NextCid -notmatch '^baf[a-z2-7]+$') {
        [Console]::Error.WriteLine("Warning: Invalid CID format in chain: $NextCid — stopping traversal")
        break
    }

    $Cid = $NextCid
    $Count++
}

[Console]::Error.WriteLine("")
[Console]::Error.WriteLine("=== CHAIN COMPLETE ===")
[Console]::Error.WriteLine("Total memories recalled: $Count")
if ($Count -ge $Limit) {
    [Console]::Error.WriteLine("Warning: Hit limit of $Limit entries. Use -Limit N to retrieve more.")
}
