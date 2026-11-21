$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $projectRoot

if (-not (Get-Command uv -ErrorAction SilentlyContinue)) {
    throw "No se encontró uv. Instálalo desde https://docs.astral.sh/uv/getting-started/installation/"
}

if (-not (Test-Path ".env")) {
    Copy-Item ".env.example" ".env"
}

$panelListener = Get-NetTCPConnection -LocalPort 9000 -State Listen -ErrorAction SilentlyContinue |
    Select-Object -First 1
if ($panelListener) {
    $authStatus = & curl.exe --silent --show-error --fail --max-time 2 "http://127.0.0.1:9000/api/auth/status"
    $curlExitCode = $LASTEXITCODE
    if ($curlExitCode -eq 0 -and $authStatus -match '"setup_required"\s*:\s*(true|false)') {
        Write-Host "CCTV NOC ya esta activo en http://127.0.0.1:9000/panel"
        exit 0
    }
    throw "El puerto 9000 ya esta ocupado y no responde como CCTV NOC. Cierra el proceso que lo usa antes de iniciar."
}

$extras = @("--extra", "video")
$visionConfig = if (Test-Path ".env") {
    Get-Content ".env" | Where-Object { $_ -match '^\s*CCTV_VISION\s*=\s*1(\s|$|#)' } | Select-Object -First 1
}
if ($env:CCTV_VISION -eq "1" -or $visionConfig) {
    $extras += @("--extra", "vision")
}
$postgresConfig = Get-Content ".env" | Where-Object { $_ -match '^\s*DATABASE_URL\s*=\s*postgres(ql)?://' } | Select-Object -First 1
if ($env:CCTV_POSTGRES -eq "1" -or $postgresConfig) {
    $extras += @("--extra", "postgres")
}

$syncArguments = @("sync", "--python", "3.12") + $extras
& uv @syncArguments
if ($LASTEXITCODE -ne 0) {
    throw "No se pudieron instalar las dependencias locales. Revisa el error anterior de uv."
}

$hostAddress = if ($env:CCTV_HOST) { $env:CCTV_HOST } else { "127.0.0.1" }
$runArguments = @(
    "run", "--python", "3.12"
) + $extras + @(
    "python", "-m", "uvicorn", "api:app",
    "--host", $hostAddress,
    "--port", "9000",
    "--app-dir", "backend"
)
& uv @runArguments
if ($LASTEXITCODE -ne 0) {
    throw "CCTV NOC se detuvo con error. Revisa el error anterior de uvicorn."
}
