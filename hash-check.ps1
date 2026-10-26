# ============================================================
# KASPERSKY OPENTIP HASH CHECKER
# MD5 / SHA1 / SHA256
# ============================================================

Clear-Host

# ------------------------------------------------------------
# API KEY
# ------------------------------------------------------------

$ApiKey = "/EJeyiUVQumN/FtlZuj7ZA=="

if ([string]::IsNullOrWhiteSpace($ApiKey) -or
$ApiKey -eq "YOUR_KASPERSKY_API_KEY") {

Write-Host ""
Write-Host "[ERROR] Kaspersky API Key is not configured." -ForegroundColor Red
Write-Host ""
exit
}

$ApiKey = $ApiKey.Trim()

# ------------------------------------------------------------
# HASH INPUT
# ------------------------------------------------------------

Write-Host "============================================================" -ForegroundColor DarkGray
Write-Host " KASPERSKY OPENTIP HASH CHECKER" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor DarkGray
Write-Host ""

$Hash = Read-Host "Enter MD5 / SHA1 / SHA256"

$Hash = $Hash.Trim().ToLower()

# ------------------------------------------------------------
# VALIDATE HASH
# ------------------------------------------------------------

if ($Hash -match '^[a-f0-9]{32}$') {

$HashType = "MD5"

}
elseif ($Hash -match '^[a-f0-9]{40}$') {

$HashType = "SHA1"

}
elseif ($Hash -match '^[a-f0-9]{64}$') {

$HashType = "SHA256"

}
else {

Write-Host ""
Write-Host "[ERROR] Invalid hash." -ForegroundColor Red
Write-Host ""
Write-Host "MD5 = 32 characters"
Write-Host "SHA1 = 40 characters"
Write-Host "SHA256 = 64 characters"
Write-Host ""

Read-Host "Press ENTER"
exit
}

Write-Host ""
Write-Host "Hash Type : $HashType" -ForegroundColor Gray
Write-Host "Hash : $Hash" -ForegroundColor Gray
Write-Host ""

# ------------------------------------------------------------
# API REQUEST
# ------------------------------------------------------------

$Headers = @{
"x-api-key" = $ApiKey
"Accept" = "application/json"
}

$EncodedHash = [System.Uri]::EscapeDataString($Hash)

$Uri = "https://opentip.kaspersky.com/api/v1/search/hash?request=$EncodedHash"

Write-Host "[*] Querying Kaspersky OpenTIP..." -ForegroundColor Cyan
Write-Host ""

try {

$Response = Invoke-WebRequest `
-Uri $Uri `
-Headers $Headers `
-Method GET `
-TimeoutSec 60 `
-UseBasicParsing `
-ErrorAction Stop

# --------------------------------------------------------
# SUCCESS
# --------------------------------------------------------

if ($Response.StatusCode -eq 200) {

$Data = $Response.Content | ConvertFrom-Json

Write-Host "============================================================"
Write-Host " KASPERSKY RESULT" -ForegroundColor Cyan
Write-Host "============================================================"
Write-Host ""

# ----------------------------------------------------
# MAIN STATUS
# ----------------------------------------------------

$Zone = [string]$Data.Zone
$FileStatus = [string]$Data.FileStatus

Write-Host "ZONE : $Zone"
Write-Host "FILE STATUS : $FileStatus"

Write-Host ""

switch ($Zone) {

"Red" {

Write-Host "VERDICT : MALICIOUS" -ForegroundColor Red
}

"Yellow" {

Write-Host "VERDICT : ADWARE / OTHER" -ForegroundColor Yellow
}

"Green" {

Write-Host "VERDICT : CLEAN / NO THREATS DETECTED" -ForegroundColor Green
}

"Grey" {

Write-Host "VERDICT : UNKNOWN / INSUFFICIENT DATA" -ForegroundColor Yellow
}

default {

Write-Host "VERDICT : UNKNOWN" -ForegroundColor Yellow
}
}

Write-Host ""

# ----------------------------------------------------
# FILE INFORMATION
# ----------------------------------------------------

Write-Host "------------------------------------------------------------"
Write-Host "FILE INFORMATION" -ForegroundColor Cyan
Write-Host "------------------------------------------------------------"

Write-Host "MD5 : $($Data.Md5)"
Write-Host "SHA1 : $($Data.Sha1)"
Write-Host "SHA256 : $($Data.Sha256)"
Write-Host "Type : $($Data.Type)"
Write-Host "Size : $($Data.Size)"
Write-Host "Signer : $($Data.Signer)"
Write-Host "Packer : $($Data.Packer)"
Write-Host "First Seen : $($Data.FirstSeen)"
Write-Host "Last Seen : $($Data.LastSeen)"
Write-Host "Hits : $($Data.HitsCount)"

# ----------------------------------------------------
# DETECTIONS
# ----------------------------------------------------

if ($null -ne $Data.DetectionsInfo) {

Write-Host ""
Write-Host "------------------------------------------------------------"
Write-Host "DETECTIONS" -ForegroundColor Red
Write-Host "------------------------------------------------------------"

foreach ($Detection in $Data.DetectionsInfo) {

Write-Host ""
Write-Host "Detection : $($Detection.DetectionName)"
Write-Host "Method : $($Detection.DetectionMethod)"
Write-Host "Zone : $($Detection.Zone)"
Write-Host "Last Detect : $($Detection.LastDetectDate)"

if ($Detection.DescriptionUrl) {
Write-Host "Description : $($Detection.DescriptionUrl)"
}
}
}

# ----------------------------------------------------
# DYNAMIC DETECTIONS
# ----------------------------------------------------

if ($null -ne $Data.DynamicDetections) {

Write-Host ""
Write-Host "------------------------------------------------------------"
Write-Host "DYNAMIC DETECTIONS" -ForegroundColor Red
Write-Host "------------------------------------------------------------"

$Data.DynamicDetections |
ConvertTo-Json -Depth 10
}

# ----------------------------------------------------
# SUSPICIOUS ACTIVITIES
# ----------------------------------------------------

if ($null -ne $Data.SuspiciousActivities) {

Write-Host ""
Write-Host "------------------------------------------------------------"
Write-Host "SUSPICIOUS ACTIVITIES" -ForegroundColor Yellow
Write-Host "------------------------------------------------------------"

$Data.SuspiciousActivities |
ConvertTo-Json -Depth 10
}

# ----------------------------------------------------
# NETWORK ACTIVITIES
# ----------------------------------------------------

if ($null -ne $Data.NetworkActivities) {

Write-Host ""
Write-Host "------------------------------------------------------------"
Write-Host "NETWORK ACTIVITIES" -ForegroundColor Cyan
Write-Host "------------------------------------------------------------"

$Data.NetworkActivities |
ConvertTo-Json -Depth 10
}

Write-Host ""
Write-Host "============================================================"
}

}
catch {

# ========================================================
# HTTP ERROR HANDLING
# ========================================================

$Response = $_.Exception.Response

if ($null -ne $Response) {

$StatusCode = [int]$Response.StatusCode

Write-Host ""
Write-Host "HTTP STATUS : $StatusCode" -ForegroundColor Yellow
Write-Host ""

switch ($StatusCode) {

400 {

Write-Host "BAD REQUEST" -ForegroundColor Red
Write-Host ""
Write-Host "Hash/query format is incorrect."
}

401 {

Write-Host "UNAUTHORIZED" -ForegroundColor Red
Write-Host ""
Write-Host "Kaspersky rejected the API token."
Write-Host "Check that the token is valid and active."
}

403 {

Write-Host "FORBIDDEN / QUOTA LIMIT" -ForegroundColor Red
Write-Host ""
Write-Host "API quota or request limit has been exceeded."
}

404 {

Write-Host "HASH NOT FOUND" -ForegroundColor Yellow
Write-Host ""
Write-Host "Kaspersky has no lookup result for this hash."
Write-Host ""
Write-Host "IMPORTANT:"
Write-Host "404 here does NOT mean CLEAN."
Write-Host "It means there is no result for this hash."
}

default {

Write-Host "KASPERSKY API ERROR" -ForegroundColor Red
Write-Host ""
Write-Host $_.Exception.Message
}
}

# ----------------------------------------------------
# READ SERVER RESPONSE
# ----------------------------------------------------

try {

$Reader = New-Object System.IO.StreamReader(
$Response.GetResponseStream()
)

$ServerBody = $Reader.ReadToEnd()

if (-not [string]::IsNullOrWhiteSpace($ServerBody)) {

Write-Host ""
Write-Host "SERVER RESPONSE:" -ForegroundColor DarkGray
Write-Host $ServerBody -ForegroundColor DarkGray
}

}
catch {}

}
else {

Write-Host ""
Write-Host "REQUEST FAILED" -ForegroundColor Red
Write-Host ""
Write-Host $_.Exception.Message
}
}

Write-Host ""
Read-Host "Press ENTER to exit"