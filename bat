$ErrorActionPreference = "SilentlyContinue"

# 1. Hapus file lama jika ada dan buat yang baru
$xmlPath = Join-Path $env:TEMP "battery_iqbal.xml"
if (Test-Path $xmlPath) { Remove-Item $xmlPath -Force }

powercfg /batteryreport /xml /output $xmlPath | Out-Null
Start-Sleep -Seconds 2

if (!(Test-Path $xmlPath)) {
    Write-Host "File XML gagal dibuat oleh Windows." -ForegroundColor Red
    return
}

# 2. BACA SEBAGAI TEKS BIASA (Bypass masalah XML Namespace)
$xmlText = Get-Content $xmlPath -Raw

# 3. EKSTRAK DATA MENGGUNAKAN REGEX (Sangat akurat & kebal error)
$designCapacity = 0
$fullCapacity = 0
$cycleCount = "N/A"
$name = "Baterai Laptop"

if ($xmlText -match "<DesignCapacity>(\d+)</DesignCapacity>") { $designCapacity = [int]$matches[1] }
if ($xmlText -match "<FullChargeCapacity>(\d+)</FullChargeCapacity>") { $fullCapacity = [int]$matches[1] }
if ($xmlText -match "<CycleCount>([^<]+)</CycleCount>") { $cycleCount = $matches[1] }
if ($xmlText -match "<Id>([^<]+)</Id>") { $name = $matches[1] }

if ($designCapacity -eq 0 -or $fullCapacity -eq 0) {
    Write-Host "Data kapasitas tidak terdeteksi oleh sensor baterai Windows." -ForegroundColor Red
    return
}

# 4. Kalkulasi Health
$healthPercent = [math]::Round((($fullCapacity / $designCapacity) * 100), 1)

$healthColor = "#22c55e" # Hijau
if ($healthPercent -lt 80) { $healthColor = "#eab308" } # Kuning
if ($healthPercent -lt 60) { $healthColor = "#ef4444" } # Merah

# 5. Merakit UI HTML 
$html = @"
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Battery Health - Iqbal Dwiansyah</title>
    <style>
        :root { --bg: #0f172a; --card: #1e293b; --text: #f8fafc; --accent: #3b82f6; }
        body { font-family: 'Segoe UI', system-ui, sans-serif; background-color: var(--bg); color: var(--text); display: flex; justify-content: center; align-items: center; min-height: 100vh; margin: 0; }
        .container { background-color: var(--card); padding: 2.5rem; border-radius: 20px; box-shadow: 0 20px 25px -5px rgba(0, 0, 0, 0.5); width: 90%; max-width: 450px; text-align: center; }
        h1 { font-size: 1.5rem; margin-bottom: 0.2rem; color: var(--text); }
        p.subtitle { color: #94a3b8; font-size: 0.9rem; margin-bottom: 2rem; }
        .health-circle { position: relative; width: 160px; height: 160px; margin: 0 auto 2.5rem; border-radius: 50%; background: conic-gradient($healthColor ${healthPercent}%, #334155 ${healthPercent}%); display: flex; justify-content: center; align-items: center; box-shadow: 0 0 20px rgba(0,0,0,0.2); }
        .health-inner { width: 140px; height: 140px; background-color: var(--card); border-radius: 50%; display: flex; flex-direction: column; justify-content: center; align-items: center; }
        .health-value { font-size: 2.5rem; font-weight: bold; color: $healthColor; line-height: 1; }
        .health-label { font-size: 0.85rem; color: #94a3b8; margin-top: 0.5rem; text-transform: uppercase; letter-spacing: 1px; }
        .stats-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 1rem; text-align: left; }
        .stat-box { background: #0f172a; padding: 1.2rem; border-radius: 12px; border: 1px solid #334155; }
        .stat-label { font-size: 0.75rem; color: #94a3b8; text-transform: uppercase; letter-spacing: 0.05em; margin-bottom: 0.3rem; }
        .stat-value { font-size: 1.1rem; font-weight: 600; color: #e2e8f0; }
        .footer { margin-top: 2.5rem; font-size: 0.8rem; color: #64748b; }
        .highlight { color: var(--accent); }
    </style>
</head>
<body>
    <div class="container">
        <h1>Battery Health <span class="highlight">Report</span></h1>
        <p class="subtitle">Developed by Iqbal Dwiansyah</p>
        
        <div class="health-circle">
            <div class="health-inner">
                <span class="health-value">${healthPercent}%</span>
                <span class="health-label">Health</span>
            </div>
        </div>

        <div class="stats-grid">
            <div class="stat-box">
                <div class="stat-label">Design Capacity</div>
                <div class="stat-value">${designCapacity} mWh</div>
            </div>
            <div class="stat-box">
                <div class="stat-label">Full Charge</div>
                <div class="stat-value">${fullCapacity} mWh</div>
            </div>
            <div class="stat-box">
                <div class="stat-label">Cycle Count</div>
                <div class="stat-value">${cycleCount}</div>
            </div>
            <div class="stat-box">
                <div class="stat-label">Battery ID</div>
                <div class="stat-value">${name}</div>
            </div>
        </div>
        
        <div class="footer">
            Di-generate otomatis pada $(Get-Date -Format "dd MMMM yyyy HH:mm")
        </div>
    </div>
</body>
</html>
"@

# 6. Buka HTML & Bersihkan
$outPath = Join-Path $env:TEMP "BatteryHealth_Iqbal.html"
$html | Out-File -FilePath $outPath -Encoding utf8
Write-Host "Membuka Battery Health Report..." -ForegroundColor Cyan
Invoke-Item $outPath
Remove-Item $xmlPath -ErrorAction SilentlyContinue
