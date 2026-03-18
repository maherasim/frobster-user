# Clean Flutter & Android build caches to free disk space (Windows)
# Run from project root: powershell -ExecutionPolicy Bypass -File clean_build_caches.ps1

Write-Host "=== 1. Flutter clean (project) ===" -ForegroundColor Cyan
flutter clean

Write-Host "`n=== 2. Gradle cache (often 10-20+ GB) ===" -ForegroundColor Cyan
$gradleHome = "$env:USERPROFILE\.gradle"
if (Test-Path "$gradleHome\caches") {
    $sizeBefore = (Get-ChildItem "$gradleHome\caches" -Recurse -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum / 1GB
    Write-Host "Gradle caches size: $([math]::Round($sizeBefore, 2)) GB"
    Remove-Item -Path "$gradleHome\caches\*" -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host "Gradle caches cleared."
} else { Write-Host "No Gradle caches folder found." }

Write-Host "`n=== 3. Flutter pub cache (optional - run 'flutter pub get' after) ===" -ForegroundColor Cyan
flutter pub cache clean

Write-Host "`n=== 4. Android build folders in this project ===" -ForegroundColor Cyan
$androidBuild = "android\build", "android\app\build", "android\.gradle"
foreach ($dir in $androidBuild) {
    if (Test-Path $dir) {
        Remove-Item -Path $dir -Recurse -Force -ErrorAction SilentlyContinue
        Write-Host "Removed $dir"
    }
}

Write-Host "`n=== 5. Dart tool & build in this project ===" -ForegroundColor Cyan
$dartDirs = ".dart_tool", "build"
foreach ($dir in $dartDirs) {
    if (Test-Path $dir) {
        Remove-Item -Path $dir -Recurse -Force -ErrorAction SilentlyContinue
        Write-Host "Removed $dir"
    }
}

Write-Host "`n=== 6. Windows Temp (optional) ===" -ForegroundColor Cyan
Remove-Item -Path "$env:TEMP\*" -Recurse -Force -ErrorAction SilentlyContinue
Write-Host "Temp cleared."

Write-Host "`n=== Done. Run 'flutter pub get' then rebuild. ===" -ForegroundColor Green
