<#
.SYNOPSIS
    Build XMRig (0% dev fee) on Windows with Visual Studio 2022.

.DESCRIPTION
    Downloads and builds dependencies (OpenSSL, libuv, hwloc), then builds XMRig.
    Requires: Visual Studio 2022, CMake, Git.

.USAGE
    Open "x64 Native Tools Command Prompt for VS 2022" or run from PowerShell:
    .\build_windows.ps1
#>

$ErrorActionPreference = "Stop"
$SCRIPT_DIR = Split-Path -Parent $MyInvocation.MyCommand.Path
$DEPS_DIR = Join-Path $SCRIPT_DIR "deps"
$BUILD_DIR = Join-Path $SCRIPT_DIR "build-win"
$RELEASE_DIR = Join-Path $SCRIPT_DIR "release-win"

Write-Host "=== XMRig Custom Windows Build (0% dev fee) ===" -ForegroundColor Green
Write-Host ""

# Find Visual Studio
$vsWhere = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe"
if (Test-Path $vsWhere) {
    $vsPath = & $vsWhere -latest -products * -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath
    if ($vsPath) {
        Write-Host "[INFO] Found Visual Studio at: $vsPath"
    }
}

# Find cmake
$cmake = "cmake"
if (-not (Get-Command cmake -ErrorAction SilentlyContinue)) {
    $cmake = "C:\Program Files\CMake\bin\cmake.exe"
}

Write-Host "[1/5] Creating directories..."
New-Item -ItemType Directory -Force -Path $DEPS_DIR | Out-Null
New-Item -ItemType Directory -Force -Path "$DEPS_DIR\include" | Out-Null
New-Item -ItemType Directory -Force -Path "$DEPS_DIR\lib" | Out-Null
New-Item -ItemType Directory -Force -Path $BUILD_DIR | Out-Null
New-Item -ItemType Directory -Force -Path $RELEASE_DIR | Out-Null

# === Build libuv ===
Write-Host "[2/5] Building libuv..." -ForegroundColor Cyan
$UV_VERSION = "1.51.0"
$UV_DIR = Join-Path $BUILD_DIR "libuv-v$UV_VERSION"

if (-not (Test-Path "$DEPS_DIR\lib\uv.lib") -and -not (Test-Path "$DEPS_DIR\lib\uv_a.lib")) {
    Push-Location $BUILD_DIR

    if (-not (Test-Path "libuv-v$UV_VERSION.tar.gz")) {
        Write-Host "  Downloading libuv $UV_VERSION..."
        Invoke-WebRequest -Uri "https://dist.libuv.org/dist/v$UV_VERSION/libuv-v$UV_VERSION.tar.gz" -OutFile "libuv-v$UV_VERSION.tar.gz"
    }

    if (-not (Test-Path $UV_DIR)) {
        tar -xzf "libuv-v$UV_VERSION.tar.gz"
    }

    $uvBuildDir = Join-Path $UV_DIR "build"
    New-Item -ItemType Directory -Force -Path $uvBuildDir | Out-Null
    Push-Location $uvBuildDir

    & $cmake .. -G "Visual Studio 17 2022" -A x64 `
        -DBUILD_TESTING=OFF `
        -DLIBUV_BUILD_SHARED=OFF
    & $cmake --build . --config Release

    Pop-Location

    # Copy outputs
    Copy-Item "$UV_DIR\include\*.h" "$DEPS_DIR\include\" -Force
    Copy-Item "$UV_DIR\include\uv" "$DEPS_DIR\include\uv" -Recurse -Force -ErrorAction SilentlyContinue

    $uvLib = Get-ChildItem "$uvBuildDir\Release" -Filter "*.lib" -Recurse | Select-Object -First 1
    if ($uvLib) {
        Copy-Item $uvLib.FullName "$DEPS_DIR\lib\uv_a.lib" -Force
        Copy-Item $uvLib.FullName "$DEPS_DIR\lib\libuv.a" -Force
    }

    Pop-Location
} else {
    Write-Host "  libuv already built, skipping."
}

# === Build OpenSSL ===
Write-Host "[3/5] Building OpenSSL..." -ForegroundColor Cyan
$OPENSSL_VERSION = "3.0.16"

if (-not (Test-Path "$DEPS_DIR\lib\libssl.lib") -and -not (Test-Path "$DEPS_DIR\lib\libssl_static.lib")) {
    # Try to find pre-built OpenSSL first
    $openSSLPaths = @(
        "C:\Program Files\OpenSSL-Win64",
        "C:\Program Files\OpenSSL",
        "C:\OpenSSL-Win64",
        "${env:VCPKG_ROOT}\installed\x64-windows-static"
    )

    $foundOpenSSL = $false
    foreach ($p in $openSSLPaths) {
        if ((Test-Path "$p\lib\libssl.lib") -or (Test-Path "$p\lib\libssl_static.lib")) {
            Write-Host "  Found pre-installed OpenSSL at: $p"
            Copy-Item "$p\include\openssl" "$DEPS_DIR\include\openssl" -Recurse -Force -ErrorAction SilentlyContinue
            Get-ChildItem "$p\lib" -Filter "lib*.lib" | ForEach-Object {
                Copy-Item $_.FullName "$DEPS_DIR\lib\" -Force
            }
            $foundOpenSSL = $true
            break
        }
    }

    if (-not $foundOpenSSL) {
        Write-Host "  No pre-built OpenSSL found."
        Write-Host "  OpenSSL is complex to build on Windows. Options:" -ForegroundColor Yellow
        Write-Host "    1. Install via vcpkg: vcpkg install openssl:x64-windows-static" -ForegroundColor Yellow
        Write-Host "    2. Download pre-built from: https://slproweb.com/products/Win32OpenSSL.html" -ForegroundColor Yellow
        Write-Host "    3. Install via chocolatey: choco install openssl" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "  After installing, set OPENSSL_ROOT_DIR and re-run this script." -ForegroundColor Yellow
        Write-Host "  Or build without TLS: add -DWITH_TLS=OFF to cmake flags." -ForegroundColor Yellow

        # For now, try vcpkg if available
        if (Get-Command vcpkg -ErrorAction SilentlyContinue) {
            Write-Host "  Attempting vcpkg install..."
            vcpkg install openssl:x64-windows-static
            $vcpkgRoot = & vcpkg env "echo %VCPKG_ROOT%" 2>$null
        }
    }
} else {
    Write-Host "  OpenSSL already available, skipping."
}

# === Build hwloc (optional) ===
Write-Host "[4/5] Checking hwloc..." -ForegroundColor Cyan
$WITH_HWLOC = "OFF"
if (Test-Path "$DEPS_DIR\lib\libhwloc.a") {
    $WITH_HWLOC = "ON"
    Write-Host "  hwloc found."
} else {
    Write-Host "  hwloc not found, building without hwloc (optional)."
    Write-Host "  For better NUMA support, install hwloc manually." -ForegroundColor Yellow
}

# === Build XMRig ===
Write-Host "[5/5] Building XMRig..." -ForegroundColor Cyan
$xmrigBuildDir = Join-Path $BUILD_DIR "xmrig"
New-Item -ItemType Directory -Force -Path $xmrigBuildDir | Out-Null
Push-Location $xmrigBuildDir

$cmakeArgs = @(
    $SCRIPT_DIR,
    "-G", "Visual Studio 17 2022",
    "-A", "x64",
    "-DCMAKE_BUILD_TYPE=Release",
    "-DWITH_OPENCL=OFF",
    "-DWITH_CUDA=OFF",
    "-DWITH_HWLOC=$WITH_HWLOC",
    "-DXMRIG_DEPS=$DEPS_DIR"
)

if (Test-Path "$DEPS_DIR\lib\libssl.lib") {
    $cmakeArgs += "-DOPENSSL_ROOT_DIR=$DEPS_DIR"
} elseif (Test-Path "$DEPS_DIR\lib\libssl_static.lib") {
    $cmakeArgs += "-DOPENSSL_ROOT_DIR=$DEPS_DIR"
} else {
    Write-Host "  WARNING: Building without TLS (no OpenSSL found)" -ForegroundColor Yellow
    $cmakeArgs += "-DWITH_TLS=OFF"
}

& $cmake @cmakeArgs
& $cmake --build . --config Release

Pop-Location

# Copy binary
$xmrigExe = Get-ChildItem $xmrigBuildDir -Filter "xmrig.exe" -Recurse | Select-Object -First 1
if ($xmrigExe) {
    Copy-Item $xmrigExe.FullName "$RELEASE_DIR\xmrig.exe" -Force
    Write-Host ""
    Write-Host "=== Build complete! ===" -ForegroundColor Green
    Write-Host "Binary: release-win\xmrig.exe"
    Write-Host "Donate level: 0%"
} else {
    Write-Host "ERROR: xmrig.exe not found after build!" -ForegroundColor Red
    Write-Host "Check build output above for errors."
}
