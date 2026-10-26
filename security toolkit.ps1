# ============================================================
# SECURITY IOC-LOOKUP TOOLKIT - MAIN MENU
# ============================================================

Clear-Host

# ============================================================
# SCRIPT CONFIGURATION
# ============================================================
# اسم فایل اسکریپت‌ها را اینجا وارد کن

$Tools = @(
@{
Name = "Abuse IP"
Script = "ip-abuse.ps1"
},
@{
Name = "Domain Espose"
Script = "domain-leak.ps1"
},
@{
Name = "Domain Lookup"
Script = "domain-lookup.ps1"
},
@{
Name = "Hash Abuse"
Script = "hash-check.ps1"
}
)

# ============================================================
# MAIN MENU
# ============================================================

while ($true) {

Clear-Host

Write-Host "============================================================" -ForegroundColor DarkGray
Write-Host " SECURITY TOOLKIT (IOC-LOOKUP)" -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor DarkGray
Write-Host ""

for ($i = 0; $i -lt $Tools.Count; $i++) {

$Number = $i + 1

Write-Host ("[{0}] {1}" -f $Number, $Tools[$i].Name) -ForegroundColor Cyan
}

Write-Host ""
Write-Host "[0] Exit" -ForegroundColor Yellow

Write-Host ""
$Choice = Read-Host "Select Option"

# ========================================================
# EXIT
# ========================================================

if ($Choice -eq "0") {
Clear-Host
Write-Host "Exiting..." -ForegroundColor Green
break
}

# ========================================================
# CHECK NUMBER
# ========================================================

$Index = 0

if (-not [int]::TryParse($Choice, [ref]$Index)) {

Write-Host ""
Write-Host "Invalid option." -ForegroundColor Red
Start-Sleep -Seconds 1
continue
}

$Index = $Index - 1

if ($Index -lt 0 -or $Index -ge $Tools.Count) {

Write-Host ""
Write-Host "Invalid option." -ForegroundColor Red
Start-Sleep -Seconds 1
continue
}

# ========================================================
# SELECTED TOOL
# ========================================================

$SelectedTool = $Tools[$Index]
$ScriptPath = Join-Path $PSScriptRoot $SelectedTool.Script

Clear-Host

Write-Host "============================================================" -ForegroundColor DarkGray
Write-Host " Running: $($SelectedTool.Name)" -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor DarkGray
Write-Host ""

# ========================================================
# CHECK SCRIPT
# ========================================================

if (-not (Test-Path $ScriptPath)) {

Write-Host "[ERROR] Script not found:" -ForegroundColor Red
Write-Host $ScriptPath -ForegroundColor Yellow

Write-Host ""
Read-Host "Press ENTER to return to menu"

continue
}

# ========================================================
# RUN SCRIPT
# ========================================================

try {

& $ScriptPath

}
catch {

Write-Host ""
Write-Host "============================================================" -ForegroundColor Red
Write-Host " SCRIPT ERROR" -ForegroundColor Red
Write-Host "============================================================" -ForegroundColor Red
Write-Host ""

Write-Host $_.Exception.Message -ForegroundColor Red
}

Write-Host ""
Write-Host "============================================================" -ForegroundColor DarkGray
Read-Host "Press ENTER to return to menu"
}