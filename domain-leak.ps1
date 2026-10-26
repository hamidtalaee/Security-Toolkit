# ============================================================
# Domain Exposure & OSINT Checker
# PowerShell - No external modules required
# ============================================================

param(
[Parameter(Mandatory = $true)]
[string]$Domain
)

$ErrorActionPreference = "SilentlyContinue"

# ------------------------------------------------------------
# Normalize Domain
# ------------------------------------------------------------

$Domain = $Domain.Trim().ToLower()

$Domain = $Domain -replace "^https?://", ""
$Domain = $Domain.Split("/")[0]
$Domain = $Domain.Split(":")[0]

# ------------------------------------------------------------
# Functions
# ------------------------------------------------------------

function Write-Section {
param([string]$Title)

Write-Host ""
Write-Host "============================================================"
Write-Host " $Title"
Write-Host "============================================================"
}

function Write-Result {
param(
[string]$Name,
[string]$Value
)

Write-Host ("{0,-28}: {1}" -f $Name, $Value)
}

function Test-DomainDNS {

try {

$dns = Resolve-DnsName `
-Name $Domain `
-Type A `
-ErrorAction Stop

$ips = $dns |
Where-Object { $_.IPAddress } |
Select-Object -ExpandProperty IPAddress -Unique

if ($ips) {

Write-Result "DNS Status" "OK"

foreach ($ip in $ips) {
Write-Result "IPv4" $ip
}

return $true
}

}
catch {
Write-Result "DNS Status" "FAILED"
}

return $false
}

function Test-MX {

try {

$mx = Resolve-DnsName `
-Name $Domain `
-Type MX `
-ErrorAction Stop

Write-Result "MX Status" "OK"

foreach ($record in $mx) {

if ($record.NameExchange) {

Write-Result `
"Mail Server" `
$record.NameExchange
}
}

}
catch {

Write-Result "MX Status" "NOT FOUND"
}
}

function Test-HTTPS {

$url = "https://$Domain"

try {

$response = Invoke-WebRequest `
-Uri $url `
-Method Head `
-TimeoutSec 15 `
-MaximumRedirection 5 `
-UseBasicParsing

Write-Result "HTTPS Status" "OK"
Write-Result "HTTP Code" $response.StatusCode
Write-Result "Final URL" $response.BaseResponse.ResponseUri.AbsoluteUri

}
catch {

Write-Result "HTTPS Status" "FAILED"
}
}

function Test-SecurityTxt {

$urls = @(
"https://$Domain/.well-known/security.txt",
"https://$Domain/security.txt"
)

$found = $false

foreach ($url in $urls) {

try {

$response = Invoke-WebRequest `
-Uri $url `
-Method Get `
-TimeoutSec 10 `
-UseBasicParsing

if ($response.StatusCode -eq 200) {

Write-Result "security.txt" "FOUND"
Write-Result "Location" $url

$found = $true
break
}
}
catch {}
}

if (-not $found) {
Write-Result "security.txt" "NOT FOUND"
}
}

function Test-RDAP {

$url = "https://rdap.org/domain/$Domain"

try {

$response = Invoke-RestMethod `
-Uri $url `
-Method Get `
-TimeoutSec 15

Write-Result "RDAP Status" "OK"

if ($response.ldhName) {
Write-Result "Registered Domain" $response.ldhName
}

if ($response.handle) {
Write-Result "Domain Handle" $response.handle
}

}
catch {

Write-Result "RDAP Status" "FAILED"
}
}

function Test-URLHaus {

Write-Section "URLHAUS THREAT INTELLIGENCE"

try {

$body = @{
host = $Domain
}

$response = Invoke-RestMethod `
-Uri "https://urlhaus-api.abuse.ch/v1/host/" `
-Method Post `
-Body $body `
-TimeoutSec 15

if ($response.urls) {

Write-Result "Status" "FOUND"
Write-Result "Reported URLs" $response.urls.Count

foreach ($item in $response.urls | Select-Object -First 10) {

if ($item.url) {
Write-Host " -> $($item.url)"
}
}

}
else {

Write-Result "Status" "NO REPORT FOUND"
Write-Result "Reported URLs" "0"
}

}
catch {

Write-Result "Status" "REQUEST FAILED"
}
}

function Test-HIBP {

Write-Section "HIBP DOMAIN BREACH CHECK"

$apiKey = $env:HIBP_API_KEY

if ([string]::IsNullOrWhiteSpace($apiKey)) {

Write-Result "Status" "NOT CONFIGURED"
Write-Host ""
Write-Host "Set HIBP_API_KEY before running the breach check."
return
}

$headers = @{
"hibp-api-key" = $apiKey
"user-agent" = "SecurityPlatform-DomainChecker/1.0"
}

$url = "https://haveibeenpwned.com/api/v3/breacheddomain/$Domain"

try {

$response = Invoke-RestMethod `
-Uri $url `
-Headers $headers `
-Method Get `
-TimeoutSec 15

Write-Result "Status" "BREACH DATA FOUND"
Write-Result "Entries" $response.Count

Write-Host ""
Write-Host "Breach Exposure:"
Write-Host "----------------"

foreach ($entry in $response) {

$key = $entry.PSObject.Properties.Name

Write-Host " $($entry.name)"
}

}
catch {

$statusCode = $_.Exception.Response.StatusCode.value__

switch ($statusCode) {

404 {
Write-Result "Status" "NO BREACH FOUND"
}

401 {
Write-Result "Status" "INVALID API KEY"
}

403 {
Write-Result "Status" "FORBIDDEN"
}

429 {
Write-Result "Status" "RATE LIMITED"
}

default {
Write-Result "Status" "REQUEST FAILED"
Write-Result "HTTP Code" $statusCode
}
}
}
}

# ------------------------------------------------------------
# Start
# ------------------------------------------------------------

Clear-Host

Write-Host ""
Write-Host "============================================================"
Write-Host " DOMAIN SECURITY & EXPOSURE CHECKER"
Write-Host "============================================================"
Write-Host ""

Write-Result "Domain" $Domain
Write-Result "Scan Time" (Get-Date -Format "yyyy-MM-dd HH:mm:ss")

# ------------------------------------------------------------
# DNS
# ------------------------------------------------------------

Write-Section "DNS"

$dnsOK = Test-DomainDNS

# ------------------------------------------------------------
# MX
# ------------------------------------------------------------

Write-Section "MAIL / MX"

Test-MX

# ------------------------------------------------------------
# HTTPS
# ------------------------------------------------------------

Write-Section "HTTPS"

Test-HTTPS

# ------------------------------------------------------------
# Security.txt
# ------------------------------------------------------------

Write-Section "SECURITY.TXT"

Test-SecurityTxt

# ------------------------------------------------------------
# RDAP
# ------------------------------------------------------------

Write-Section "DOMAIN REGISTRATION / RDAP"

Test-RDAP

# ------------------------------------------------------------
# URLHaus
# ------------------------------------------------------------

Test-URLHaus

# ------------------------------------------------------------
# HIBP
# ------------------------------------------------------------

Test-HIBP

# ------------------------------------------------------------
# Final
# ------------------------------------------------------------

Write-Section "FINAL ASSESSMENT"

Write-Host ""
Write-Host "Domain : $Domain"

if ($dnsOK) {
Write-Host "DNS : OK"
}
else {
Write-Host "DNS : FAILED"
}

Write-Host ""
Write-Host "Note:"
Write-Host "This tool checks public/authorized data sources."
Write-Host "A 'NO BREACH FOUND' result does not prove that"
Write-Host "the domain has never experienced a data leak."
Write-Host ""

Write-Host "Scan completed."
Write-Host ""