# Script Final (Mejorado) para ejecutar LogCoC de forma totalmente invisible

$PROJECT_ROOT = Get-Location
Write-Host "🚀 Iniciando LogCoC en segundo plano (sin ventanas)..." -ForegroundColor Cyan

# 1. Limpiar puertos previos
$ports = 8000, 5050
foreach ($port in $ports) {
    $proc = Get-NetTCPConnection -LocalPort $port -ErrorAction SilentlyContinue
    if ($proc) {
        Stop-Process -Id $proc.OwningProcess -Force -ErrorAction SilentlyContinue
        Write-Host "Puerto $port liberado." -ForegroundColor Gray
    }
}

# 2. Iniciar el Backend (Invisible + Enlace a 0.0.0.0)
Write-Host "[1/2] Backend arrancando en 0.0.0.0:8000..." -ForegroundColor Green
Start-Process python -ArgumentList "-u -m uvicorn main:app --host 0.0.0.0 --port 8000" -WorkingDirectory "backend" -WindowStyle Hidden

# 3. Iniciar el Frontend (Servidor de Producción SPA en Python)
Write-Host "[2/2] Frontend arrancando en 0.0.0.0:5050..." -ForegroundColor Green
Start-Process python -ArgumentList "-u spa_server.py" -WorkingDirectory "frontend" -WindowStyle Hidden

# 4. Esperar y verificar que los servicios estén activos
Write-Host "⏳ Esperando a que los servicios inicien (máximo 45 segundos)..." -ForegroundColor Yellow
$backendReady = $false
$frontendReady = $false

for ($i = 1; $i -le 45; $i++) {
    Start-Sleep -Seconds 1
    if (-not $backendReady) {
        $check = Get-NetTCPConnection -LocalPort 8000 -ErrorAction SilentlyContinue
        if ($check) { $backendReady = $true }
    }
    if (-not $frontendReady) {
        $check = Get-NetTCPConnection -LocalPort 5050 -ErrorAction SilentlyContinue
        if ($check) { $frontendReady = $true }
    }
    if ($backendReady -and $frontendReady) {
        break
    }
}

Write-Host "-------------------------------------------"
if ($backendReady -and $frontendReady) {
    Write-Host "✅ ¡Listo! Ambos servicios están corriendo y activos." -ForegroundColor Green
} else {
    Write-Host "⚠️ Advertencia: Algunos servicios tardaron demasiado en responder." -ForegroundColor Red
    if (-not $backendReady) { Write-Host " - Backend (puerto 8000) no responde. Revisa backend_log.txt" -ForegroundColor Red }
    if (-not $frontendReady) { Write-Host " - Frontend (puerto 5050) no responde. Revisa frontend_log.txt" -ForegroundColor Red }
}

Write-Host "🔗 Frontend: http://localhost:5050"
Write-Host "🔗 Backend:  http://localhost:8000/docs"
Write-Host ""
Write-Host "Para detenerlos, usa: Get-Process python, dart | Stop-Process"
Write-Host "Los logs se están guardando en:"
Write-Host " - $PROJECT_ROOT\backend_log.txt"
Write-Host " - $PROJECT_ROOT\frontend_log.txt"
Write-Host "-------------------------------------------"

