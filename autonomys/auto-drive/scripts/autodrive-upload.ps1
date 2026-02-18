#Requires -Version 7.0
# Upload a file or JSON object to Auto-Drive (3-step chunked upload)
# Usage: autodrive-upload.ps1 <FilePath> [-Json] [-Compress]
# Env: AUTO_DRIVE_API_KEY (required)
# Output: CID on success (stdout), status messages on stderr

param(
    [Parameter(Mandatory)][string]$FilePath,
    [switch]$Json,
    [switch]$Compress
)

$ErrorActionPreference = 'Stop'

$ApiBase = "https://mainnet.auto-drive.autonomys.xyz/api"

$ApiKey = $env:AUTO_DRIVE_API_KEY
if (-not $ApiKey) {
    [Console]::Error.WriteLine("Error: AUTO_DRIVE_API_KEY not set.")
    [Console]::Error.WriteLine("Get a free key at https://ai3.storage (sign in with Google/GitHub → Developers → Create API Key)")
    exit 1
}

if (-not (Test-Path $FilePath -PathType Leaf)) {
    [Console]::Error.WriteLine("Error: File not found: $FilePath")
    exit 1
}

$FileName = Split-Path $FilePath -Leaf
if ($Json) {
    $Mime = "application/json"
} else {
    Add-Type -AssemblyName System.Web
    $Mime = [System.Web.MimeMapping]::GetMimeMapping($FilePath)
    if (-not $Mime) { $Mime = "application/octet-stream" }
}

$Headers = @{
    "Authorization"   = "Bearer $ApiKey"
    "X-Auth-Provider" = "apikey"
}

# Step 1: Create upload
[Console]::Error.WriteLine("Creating upload for '$FileName'...")
$UploadOptions = if ($Compress) {
    @{ compression = @{ algorithm = "ZLIB" } }
} else {
    @{}
}

$UploadBody = @{
    filename      = $FileName
    mimeType      = $Mime
    uploadOptions = $UploadOptions
} | ConvertTo-Json -Depth 5

try {
    $Step1 = Invoke-RestMethod -Method Post -Uri "$ApiBase/uploads/file" `
        -Headers $Headers `
        -ContentType "application/json" `
        -Body $UploadBody
} catch {
    [Console]::Error.WriteLine("Error: Failed to create upload — $($_.Exception.Message)")
    exit 1
}

$UploadId = $Step1.id
if (-not $UploadId) {
    [Console]::Error.WriteLine("Error: Failed to create upload — no upload ID returned")
    exit 1
}

# Step 2: Upload chunk (multipart)
[Console]::Error.WriteLine("Uploading file data...")

$Form = @{
    file  = Get-Item $FilePath
    index = "0"
}

try {
    Invoke-RestMethod -Method Post -Uri "$ApiBase/uploads/file/$UploadId/chunk" `
        -Headers $Headers `
        -Form $Form | Out-Null
} catch {
    [Console]::Error.WriteLine("Error: Failed to upload chunk — $($_.Exception.Message)")
    exit 1
}

# Step 3: Complete upload → get CID
[Console]::Error.WriteLine("Completing upload...")

try {
    $Step3 = Invoke-RestMethod -Method Post -Uri "$ApiBase/uploads/$UploadId/complete" `
        -Headers $Headers
} catch {
    [Console]::Error.WriteLine("Error: Failed to complete upload — $($_.Exception.Message)")
    exit 1
}

$Cid = $Step3.cid
if (-not $Cid) {
    [Console]::Error.WriteLine("Error: Upload completed but no CID returned")
    exit 1
}

# Validate CID format to prevent chain corruption
# Autonomys CIDs are base32-encoded and must start with "baf" followed by valid base32 chars
if ($Cid -notmatch '^baf[a-z2-7]+$') {
    [Console]::Error.WriteLine("Error: Invalid CID format returned: $Cid")
    exit 1
}

[Console]::Error.WriteLine("Upload successful! CID: $Cid")
[Console]::Error.WriteLine("Gateway URL: https://gateway.autonomys.xyz/file/$Cid")
Write-Output $Cid
