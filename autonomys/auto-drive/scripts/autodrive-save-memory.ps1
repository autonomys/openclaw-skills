#Requires -Version 7.0
# Save a memory experience to Auto-Drive as part of the linked list chain
# Usage: autodrive-save-memory.ps1 <DataArg> [-AgentName NAME] [-StateFile PATH]
# Env: AUTO_DRIVE_API_KEY (required)
# Output: JSON with cid, previousCid, chainLength (stdout)
#
# If DataArg is a file path, its JSON contents become the data payload.
# If DataArg is a plain string, it is wrapped as {"type":"memory","content":"..."}.
#
# Note: parameter is named $DataArg (not $input) to avoid shadowing PowerShell's
# automatic $input variable for pipeline input.

param(
    [Parameter(Mandatory)][string]$DataArg,
    [string]$AgentName = '',
    [string]$StateFile = ''
)

$ErrorActionPreference = 'Stop'

$ScriptDir = $PSScriptRoot
$ApiBase  = "https://mainnet.auto-drive.autonomys.xyz/api"

if (-not $AgentName) {
    $AgentName = if ($env:AGENT_NAME) { $env:AGENT_NAME } else { "openclaw-agent" }
}

$WorkspaceRoot = if ($env:OPENCLAW_WORKSPACE) { $env:OPENCLAW_WORKSPACE } else {
    [IO.Path]::Combine($HOME, ".openclaw", "workspace")
}

if (-not $StateFile) {
    $StateFile = [IO.Path]::Combine($WorkspaceRoot, "memory", "autodrive-state.json")
}

$ApiKey = $env:AUTO_DRIVE_API_KEY
if (-not $ApiKey) {
    [Console]::Error.WriteLine("Error: AUTO_DRIVE_API_KEY not set.")
    [Console]::Error.WriteLine("Get a free key at https://ai3.storage (sign in with Google/GitHub → Developers → Create API Key)")
    exit 1
}

# Determine if DataArg is a file path or a plain string
if (Test-Path $DataArg -PathType Leaf) {
    $DataRaw = Get-Content $DataArg -Raw
    try {
        $DataJson = $DataRaw | ConvertFrom-Json -Depth 20
    } catch {
        [Console]::Error.WriteLine("Error: Data file is not valid JSON: $DataArg")
        exit 1
    }
} else {
    $DataJson = [ordered]@{
        type    = "memory"
        content = $DataArg
    }
}

# Read previous CID and chain length from state file
$PreviousCid = $null
$ChainLength  = 0
if (Test-Path $StateFile -PathType Leaf) {
    try {
        $State       = Get-Content $StateFile -Raw | ConvertFrom-Json
        $PreviousCid = $State.lastCid
        $ChainLength  = if ($null -ne $State.chainLength) { [int]$State.chainLength } else { 0 }
    } catch {
        # Ignore corrupt state file — start fresh
        $PreviousCid = $null
        $ChainLength  = 0
    }
}

$Timestamp = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.000Z")

# Build the experience JSON with header/data structure
$Experience = [ordered]@{
    header = [ordered]@{
        agentName    = $AgentName
        agentVersion = "1.0.0"
        timestamp    = $Timestamp
        previousCid  = $PreviousCid
    }
    data = $DataJson
}

# Write to temp file and upload via the upload script
$TmpFile = [IO.Path]::Combine([IO.Path]::GetTempPath(), "autodrive-memory-$(New-Guid).json")
try {
    $Experience | ConvertTo-Json -Depth 10 | Set-Content $TmpFile -Encoding UTF8
    $UploadScript = [IO.Path]::Combine($ScriptDir, "autodrive-upload.ps1")
    $Cid = & $UploadScript $TmpFile -Json -Compress

    if (-not $Cid) {
        [Console]::Error.WriteLine("Error: Upload failed — no CID returned")
        exit 1
    }
} finally {
    if (Test-Path $TmpFile) { Remove-Item $TmpFile }
}

# Validate CID format (Autonomys CIDs are base32-encoded, starting with "bafy" or "bafk")
if ($Cid -notmatch '^baf[a-z2-7]+$') {
    [Console]::Error.WriteLine("Error: Invalid CID format returned: $Cid")
    exit 1
}

# Verify the upload is accessible before updating state — prevents chain corruption
# if the API returns a CID for malformed/incomplete data that can't be retrieved later
[Console]::Error.WriteLine("Verifying upload is accessible...")
$VerifyHeaders = @{
    "Authorization"   = "Bearer $ApiKey"
    "X-Auth-Provider" = "apikey"
}
try {
    $null = Invoke-WebRequest -Uri "$ApiBase/downloads/$Cid" -Headers $VerifyHeaders
} catch {
    [Console]::Error.WriteLine("Error: Post-upload verification failed — CID $Cid is not accessible")
    [Console]::Error.WriteLine("State not updated to prevent chain corruption.")
    exit 1
}
[Console]::Error.WriteLine("Verified accessible.")

# Update state file
$NewLength = $ChainLength + 1
$StateDir = Split-Path $StateFile -Parent
if (-not (Test-Path $StateDir)) { New-Item -ItemType Directory -Path $StateDir -Force | Out-Null }
[ordered]@{
    lastCid             = $Cid
    lastUploadTimestamp = $Timestamp
    chainLength         = $NewLength
} | ConvertTo-Json | Set-Content $StateFile -Encoding UTF8

# Pin latest CID to MEMORY.md for session continuity (if it exists)
$MemoryFile = [IO.Path]::Combine($WorkspaceRoot, "MEMORY.md")
if (Test-Path $MemoryFile -PathType Leaf) {
    $MemContent = Get-Content $MemoryFile -Raw
    $CidLine    = "- **Latest CID:** ``$Cid`` (chain length: $NewLength, updated: $Timestamp)"
    if ($MemContent -match '(?m)^## Auto-Drive Chain') {
        if ($MemContent -match '(?m)^- \*\*Latest CID:\*\*') {
            $MemContent = $MemContent -replace '(?m)^- \*\*Latest CID:\*\*.*', $CidLine
        } else {
            $MemContent = $MemContent + "`n$CidLine"
        }
    } else {
        $MemContent = $MemContent + "`n`n## Auto-Drive Chain`n$CidLine"
    }
    [IO.File]::WriteAllText($MemoryFile, $MemContent)
}

# Output structured result
[ordered]@{
    cid         = $Cid
    previousCid = $PreviousCid
    chainLength = $NewLength
} | ConvertTo-Json -Compress
