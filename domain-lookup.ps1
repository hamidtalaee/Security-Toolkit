# ============================================================
# DOMAIN LOOKUP
# DNS + RDAP + DOMAIN INFORMATION
# ============================================================

Clear-Host

Write-Host "============================================================" -ForegroundColor DarkGray
Write-Host " DOMAIN LOOKUP" -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor DarkGray
Write-Host ""

$Domain = Read-Host "Enter Domain"

$Domain = $Domain.Trim().ToLower()

# Remove protocol
$Domain = $Domain -replace '^https?://', ''

# Remove path
$Domain = $Domain.Split('/')[0]

if ([string]::IsNullOrWhiteSpace($Domain)) {

Write-Host ""
Write-Host "[ERROR] Domain cannot be empty." -ForegroundColor Red
Read-Host "Press ENTER"
exit
}

Write-Host ""
Write-Host "[*] Target : $Domain" -ForegroundColor Cyan
Write-Host ""

# ============================================================
# FUNCTION - SECTION
# ============================================================

function Show-Section {
param(
[string]$Title
)

Write-Host ""
Write-Host "============================================================" -ForegroundColor DarkGray
Write-Host " $Title" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor DarkGray
}

# ============================================================
# BASIC DOMAIN
# ============================================================

Show-Section "DOMAIN INFORMATION"

Write-Host "Domain : $Domain"

try {

$DomainParts = $Domain.Split('.')

if ($DomainParts.Count -ge 2) {

$TLD = "." + $DomainParts[-1]

Write-Host "TLD : $TLD"
}

}
catch {}

# ============================================================
# DNS A RECORD
# ============================================================

Show-Section "A RECORD / IPv4"

try {

$ARecords = Resolve-DnsName `
-Name $Domain `
-Type A `
-ErrorAction Stop

$ARecords |
Where-Object {$_.Type -eq "A"} |
ForEach-Object {

Write-Host "IPv4 : $($_.IPAddress)" -ForegroundColor Green
}

}
catch {

Write-Host "No A record found." -ForegroundColor Yellow
}

# ============================================================
# DNS AAAA RECORD
# ============================================================

Show-Section "AAAA RECORD / IPv6"

try {

$AAAARecords = Resolve-DnsName `
-Name $Domain `
-Type AAAA `
-ErrorAction Stop

$AAAARecords |
Where-Object {$_.Type -eq "AAAA"} |
ForEach-Object {

Write-Host "IPv6 : $($_.IPAddress)"
}

}
catch {

Write-Host "No AAAA record found." -ForegroundColor Yellow
}

# ============================================================
# CNAME
# ============================================================

Show-Section "CNAME"

try {

$CNAME = Resolve-DnsName `
-Name $Domain `
-Type CNAME `
-ErrorAction Stop

$CNAME |
Where-Object {$_.Type -eq "CNAME"} |
ForEach-Object {

Write-Host "CNAME : $($_.NameHost)"
}

}
catch {

Write-Host "No CNAME record found." -ForegroundColor Yellow
}

# ============================================================
# MX
# ============================================================

Show-Section "MX RECORDS / MAIL SERVERS"

try {

$MXRecords = Resolve-DnsName `
-Name $Domain `
-Type MX `
-ErrorAction Stop

$MXRecords |
Where-Object {$_.Type -eq "MX"} |
ForEach-Object {

Write-Host "Mail Server : $($_.NameExchange)"
Write-Host "Priority : $($_.Preference)"
Write-Host ""
}

}
catch {

Write-Host "No MX record found." -ForegroundColor Yellow
}

# ============================================================
# NS
# ============================================================

Show-Section "NS RECORDS / NAME SERVERS"

try {

$NSRecords = Resolve-DnsName `
-Name $Domain `
-Type NS `
-ErrorAction Stop

$NSRecords |
Where-Object {$_.Type -eq "NS"} |
ForEach-Object {

Write-Host "Name Server : $($_.NameHost)"
}

}
catch {

Write-Host "No NS record found." -ForegroundColor Yellow
}

# ============================================================
# TXT
# ============================================================

Show-Section "TXT RECORDS"

try {

$TXTRecords = Resolve-DnsName `
-Name $Domain `
-Type TXT `
-ErrorAction Stop

$TXTRecords |
Where-Object {$_.Type -eq "TXT"} |
ForEach-Object {

Write-Host "TXT : $($_.Strings -join '')"
}

}
catch {

Write-Host "No TXT record found." -ForegroundColor Yellow
}

# ============================================================
# SOA
# ============================================================

Show-Section "SOA RECORD"

try {

$SOA = Resolve-DnsName `
-Name $Domain `
-Type SOA `
-ErrorAction Stop

$SOA |
Where-Object {$_.Type -eq "SOA"} |
ForEach-Object {

Write-Host "Primary Server : $($_.PrimaryServer)"
Write-Host "Responsible Mailbox : $($_.ResponsibleMailbox)"
Write-Host "Serial Number : $($_.SerialNumber)"
Write-Host "Refresh : $($_.Refresh)"
Write-Host "Retry : $($_.Retry)"
Write-Host "Expire : $($_.Expire)"
Write-Host "Minimum TTL : $($_.MinimumTTL)"
}

}
catch {

Write-Host "No SOA record found." -ForegroundColor Yellow
}

# ============================================================
# HTTPS TEST
# ============================================================

Show-Section "HTTPS / WEB SERVER"

try {

$HTTPS = Invoke-WebRequest `
-Uri "https://$Domain" `
-Method Head `
-TimeoutSec 10 `
-UseBasicParsing `
-ErrorAction Stop

Write-Host "HTTPS Status : $($HTTPS.StatusCode)"
Write-Host "Server : $($HTTPS.Headers['Server'])"
Write-Host "Content-Type : $($HTTPS.Headers['Content-Type'])"

}
catch {

Write-Host "HTTPS : Connection failed / blocked" -ForegroundColor Yellow
}

# ============================================================
# HTTP TEST
# ============================================================

try {

$HTTP = Invoke-WebRequest `
-Uri "http://$Domain" `
-Method Head `
-TimeoutSec 10 `
-UseBasicParsing `
-ErrorAction Stop

Write-Host "HTTP Status : $($HTTP.StatusCode)"
Write-Host "HTTP Server : $($HTTP.Headers['Server'])"

}
catch {

Write-Host "HTTP : Connection failed / blocked" -ForegroundColor Yellow
}

# ============================================================
# RDAP
# ============================================================

Show-Section "RDAP / DOMAIN REGISTRATION"

try {

$RDAPURL = "https://rdap.org/domain/$Domain"

$RDAPResponse = Invoke-RestMethod `
-Uri $RDAPURL `
-Method GET `
-TimeoutSec 15 `
-ErrorAction Stop

Write-Host "RDAP Status : Available" -ForegroundColor Green

if ($RDAPResponse.ldhName) {
Write-Host "Registered Domain : $($RDAPResponse.ldhName)"
}

if ($RDAPResponse.status) {

Write-Host "Domain Status : $($RDAPResponse.status -join ', ')"
}

if ($RDAPResponse.events) {

foreach ($Event in $RDAPResponse.events) {

Write-Host "$($Event.eventAction) : $($Event.eventDate)"
}
}

if ($RDAPResponse.nameservers) {

Write-Host ""
Write-Host "RDAP Name Servers:"

foreach ($NS in $RDAPResponse.nameservers) {

Write-Host " - $($NS.ldhName)"
}
}

}
catch {

Write-Host "RDAP : Information unavailable" -ForegroundColor Yellow
}

# ============================================================
# SECURITY TXT
# ============================================================

Show-Section "SECURITY.TXT"

try {

$SecurityTXT = Invoke-WebRequest `
-Uri "https://$Domain/.well-known/security.txt" `
-Method GET `
-TimeoutSec 10 `
-UseBasicParsing `
-ErrorAction Stop

Write-Host "security.txt : FOUND" -ForegroundColor Green
Write-Host ""

Write-Host $SecurityTXT.Content

}
catch {

Write-Host "security.txt : NOT FOUND" -ForegroundColor Yellow
}

# ============================================================
# SUMMARY
# ============================================================

Show-Section "LOOKUP FINISHED"

Write-Host "Target : $Domain"
Write-Host "Completed : $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"

Write-Host ""
Write-Host "============================================================" -ForegroundColor DarkGray
Write-Host " FINISHED" -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor DarkGray
Write-Host ""

Read-Host "Press ENTER to return to menu"