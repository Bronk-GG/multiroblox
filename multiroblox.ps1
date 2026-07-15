# --- Dynamische Konfiguration ---
$ProcessName = "RobloxPlayerBeta" 

# Ermittelt automatisch das Verzeichnis, in dem dieses Skript liegt
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$HandleToolPath = Join-Path $ScriptDir "handle.exe"

# Der Event-Name (wir suchen nach dem Teil-String am Ende, da sich die Session-ID (\Sessions\1\ oder \Sessions\2\) ändern kann)
$TargetHandleName = "ROBLOX_singletonEvent"
# --------------------------------

Write-Host "Searching for $ProcessName..." -ForegroundColor Cyan

# Überprüfen, ob handle.exe im selben Ordner existiert
if (-not (Test-Path $HandleToolPath)) {
    Write-Host "FEHLER: 'handle.exe' wurde nicht im Ordner gefunden!" -ForegroundColor Red
    Write-Host "Pfad gesucht: $HandleToolPath" -ForegroundColor Yellow
    exit
}

# Get-Process kann mehrere Prozesse zurückgeben, daher verarbeiten wir sie als Array
$Processes = Get-Process -Name $ProcessName -ErrorAction SilentlyContinue

if (-not $Processes) {
    Write-Host "Process '$ProcessName' is not running. Launch it first!" -ForegroundColor Yellow
    exit
}

$HandleClosed = $false

# Wir maskieren den Suchnamen für die Regex-Sicherheit
$EscapedTargetHandleName = [Regex]::Escape($TargetHandleName)

# Loop durch jeden laufenden Prozess dieses Namens
foreach ($Process in $Processes) {
    $PIDVal = $Process.Id
    Write-Host "Checking process with PID: $PIDVal..." -ForegroundColor Gray

    # Suche mit Sysinternals Handle nach dem spezifischen Handle
    $HandleOutput = & $HandleToolPath -p $PIDVal -a $TargetHandleName 2>$null

    # Loop durch jede Zeile der handle.exe Ausgabe
    foreach ($Line in $HandleOutput) {
        # Matcht die Hex-ID und prüft, ob unser TargetHandleName in der Zeile vorkommt
        if ($Line -match "\s+(?<hex>[0-9A-Fa-f]+):\s+.*$EscapedTargetHandleName") {
            $HexHandle = $Matches['hex']
            Write-Host "Found Handle ID: 0x$HexHandle in PID $PIDVal" -ForegroundColor Green
            
            # Schließe das Handle
            & $HandleToolPath -c $HexHandle -p $PIDVal -y | Out-Null
            
            Write-Host "Handle successfully closed! You can now launch another instance." -ForegroundColor Green
            $HandleClosed = $true
            break # Loop für diesen Prozess beenden, wenn gefunden
        }
    }
}

if (-not $HandleClosed) {
    Write-Host "Could not find an active handle containing '$TargetHandleName'." -ForegroundColor Red
}