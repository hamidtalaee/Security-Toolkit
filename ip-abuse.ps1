# ============================================================
# ABUSEIPDB IP CHECKER
# ============================================================

# API Key
$Key = "3ffd85331a2ba2deb0d0e6cb13fc2e01df99472522823ce4f9e86b3b73a8b772c33de39b9bba9309"

# ============================================================
# GET IP FROM USER
# ============================================================

$IP = Read-Host "Enter IP Address"

$IP = $IP.Trim()

if ([string]::IsNullOrWhiteSpace($IP)) {
Write-Host ""
Write-Host "ERROR: IP address cannot be empty." -ForegroundColor Red
exit
}

# ============================================================
# HEADERS
# ============================================================

$Headers = @{
"Key" = $Key
"Accept" = "application/json"
}

# ============================================================
# API URL
# ============================================================

$Uri = "https://api.abuseipdb.com/api/v2/check?ipAddress=$IP&maxAgeInDays=365"

# ============================================================
# CHECK ABUSEIPDB
# ============================================================

try {

Write-Host ""
Write-Host "[*] Checking IP: $IP" -ForegroundColor Cyan
Write-Host ""

$r = Invoke-WebRequest `
-Uri $Uri `
-Headers $Headers `
-Method GET `
-UseBasicParsing

$json = $r.Content | ConvertFrom-Json
$data = $json.data

# ========================================================
# RESULT
# ========================================================

Write-Host "========================================" -ForegroundColor DarkGray
Write-Host " ABUSEIPDB RESULT" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor DarkGray
Write-Host ""

Write-Host "IP Address : $($data.ipAddress)"
Write-Host "Abuse Confidence : $($data.abuseConfidenceScore)%"
Write-Host "Total Reports : $($data.totalReports)"
Write-Host "Distinct Reporters : $($data.numDistinctUsers)"
Write-Host "Country : $($data.countryCode)"
Write-Host "ISP : $($data.isp)"
Write-Host "Domain : $($data.domain)"
Write-Host "Usage Type : $($data.usageType)"
Write-Host "TOR : $($data.isTor)"
Write-Host "Last Reported : $($data.lastReportedAt)"

Write-Host ""

# ========================================================
# ASSESSMENT
# ========================================================

$Score = [int]$data.abuseConfidenceScore

if ($Score -eq 100) {

Write-Host "ASSESSMENT : 100% ABUSIVE" -ForegroundColor Red

}
elseif ($Score -ge 80) {

Write-Host "ASSESSMENT : HIGH RISK" -ForegroundColor Red

}
elseif ($Score -ge 50) {

Write-Host "ASSESSMENT : MEDIUM RISK" -ForegroundColor Yellow

}
elseif ($Score -gt 0) {

Write-Host "ASSESSMENT : REPORTED" -ForegroundColor Yellow

}
else {

Write-Host "ASSESSMENT : LOW / NO ABUSE SCORE" -ForegroundColor Green
}

Write-Host ""

Write-Host "HTTP STATUS : $($r.StatusCode)" -ForegroundColor Green

Write-Host ""
Write-Host "========================================" -ForegroundColor DarkGray

}
catch {

Write-Host ""
Write-Host "========================================" -ForegroundColor Red
Write-Host " ERROR" -ForegroundColor Red
Write-Host "========================================" -ForegroundColor Red
Write-Host ""

Write-Host "$($_.Exception.Message)" -ForegroundColor Red

Write-Host ""
}