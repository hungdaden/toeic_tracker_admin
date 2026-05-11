# Script build TOEIC Admin Desktop (Electron) - Optimized with Auto Clean
Write-Host "--- Bat dau Quy trinh Build TOEIC Admin Desktop ---" -ForegroundColor Cyan

# 0. Don dep he thong (Deep Clean)
Write-Host "0. Dang don dep thu muc build cu..." -ForegroundColor Yellow

# Xoa cac thu muc build cu cua Flutter

# Xoa thu muc build web ben trong Electron (neu ban dat ten la web_build)
if (Test-Path "electron_app/web_build") { 
    Write-Host "   > Xoa thu muc electron_app/web_build/"
    Remove-Item -Recurse -Force "electron_app/web_build" 
}

# Xoa thu muc dist (ket qua build cu cua Electron)
if (Test-Path "electron_app/dist") { 
    Write-Host "   > Xoa thu muc electron_app/dist/"
    Remove-Item -Recurse -Force "electron_app/dist" 
}

# Xoa thu muc out (ket qua build cu cua Electron-Builder)
if (Test-Path "electron_app/out") { 
    Write-Host "   > Xoa thu muc electron_app/out/"
    Remove-Item -Recurse -Force "electron_app/out" 
}

Write-Host "   > Chay flutter clean..."
flutter clean

# 1. Build Flutter Web
Write-Host "1. Dang build Flutter Web (Release)..." -ForegroundColor Green
flutter pub get
flutter build web --release --base-href "/"

if (-not $?) {
    Write-Host "ERR: Build Flutter Web that bai! Vui long kiem tra loi ben tren." -ForegroundColor Red
    exit
}

# Fix loi man hinh trang cho Electron (Sua base href ve tuong doi)
Write-Host "   > Dang sua loi duong dan index.html..." -ForegroundColor Yellow
(Get-Content build/web/index.html) -replace '<base href="/">', '<base href="./">' | Set-Content build/web/index.html

# 2. Chuan bi thu muc Electron
Write-Host "2. Dang chuan bi thu muc Electron..." -ForegroundColor Green
if (-not (Test-Path "build/web")) {
    Write-Host "ERR: Khong tim thay thu muc build/web!" -ForegroundColor Red
    exit
}
New-Item -ItemType Directory -Force -Path "electron_app/dist"
Copy-Item -Recurse "build/web/*" "electron_app/dist/"

# Copy icon cho Electron
if (Test-Path "assets/icon.png") {
    Copy-Item "assets/icon.png" "electron_app/icon.png"
}
elseif (Test-Path "assets/icon/icon.ico") {
    Copy-Item "assets/icon/icon.ico" "electron_app/icon.png"
}

# 3. Build Electron App
Write-Host "3. Dang dong goi ung dung Desktop..." -ForegroundColor Green
cd electron_app
# Kiem tra node_modules, neu chua co thi install
if (-not (Test-Path "node_modules")) {
    Write-Host "   > Cai dat dependencies cho Electron..."
    npm install
}
npm run build

cd ..
Write-Host "--- HOAN TAT! San pham nam trong build/desktop ---" -ForegroundColor Cyan
