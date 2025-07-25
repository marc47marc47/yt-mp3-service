# YT-MP3 Service

🎵 高效能 YouTube 轉 MP3 轉換服務，使用 Rust 和 Axum 構建

![YT-MP3 Service Interface](yt-mp3-service.png)

## 主要功能

### 🚀 核心功能
- **快速轉換**: 使用 yt-dlp 和 FFmpeg 進行高性能 YouTube 轉 MP3 轉換
- **縮圖支援**: 自動下載並顯示影片縮圖
- **多格式支援**: 支援 MP3、M4A 等多種音頻格式
- **批量下載**: 支援播放清單批量轉換

### 🌐 Web 介面
- **直觀操作**: 簡潔易用的網頁介面
- **即時進度**: 即時顯示轉換進度和狀態
- **下載管理**: 完成後直接下載音頻檔案

### 🔒 安全與效能
- **HTTPS 支援**: 內建 TLS 支援，自動生成 SSL 證書
- **本地運行**: 完全在本地運行，保護隱私
- **自包含**: 包含所有依賴，無需額外安裝

## 安裝方法

### 方法 1: 從原始碼構建 (推薦)

#### 環境需求
- **Windows 10/11** (64位元)
- **Rust 工具鏈** (最新穩定版)
- **網路連線** (用於下載依賴工具)

#### 安裝步驟

1. **安裝 Rust**
   ```cmd
   # 下載並執行 Rust 安裝程式
   # 訪問 https://rustup.rs/ 下載 rustup-init.exe
   rustup-init.exe
   
   # 重新開啟 Command Prompt 驗證安裝
   cargo --version
   rustc --version
   ```

2. **下載專案**
   ```cmd
   git clone <repository-url>
   cd yt-mp3-service
   ```

3. **構建專案**
   ```cmd
   # 建構需要git 及bash shell, 請先安裝windows git, 並將其加入path
   # 下載git 安裝程式: https://github.com/git-for-windows/git/releases/download/v2.50.1.windows.1/Git-2.50.1-64-bit.exe

   # 使用構建腳本 (推薦)
   build.bat
   
   # 或者手動構建
   cargo build --release
   ```

4. **驗證安裝**
   ```cmd
   # 檢查生成的檔案
   dir bin\
   # 應該看到: server.exe, cert-gen.exe
   ```

### 方法 2: 預編譯版本

1. **下載發布包**
   - 從 Releases 頁面下載最新的 Windows 版本
   - 檔案名稱: `yt-mp3-service-windows-x64.zip`

2. **解壓縮**
   ```cmd
   # 解壓到任意目錄
   # 例如: C:\yt-mp3-service\
   ```

3. **執行初始化**
   ```cmd
   cd C:\yt-mp3-service
   install.bat
   ```

## 啟動服務

### 快速啟動

```cmd
# 方法 1: 使用服務管理腳本 (推薦)
scripts\start.bat

# 方法 2: 直接執行
bin\server.exe
```

### 完整服務管理

```cmd
# 啟動服務
scripts\start.bat

# 檢查服務狀態
scripts\status.bat

# 停止服務
scripts\stop.bat
```

### 服務驗證

啟動後在瀏覽器中訪問：
- **HTTP**: http://127.0.0.1:3000
- **HTTPS**: https://127.0.0.1:3443

## 停止服務

### 正常停止

```cmd
# 使用停止腳本 (推薦)
scripts\stop.bat

# 查看停止狀態
scripts\status.bat
```

### 強制停止

```cmd
# 如果正常停止失敗，使用強制停止
taskkill /F /IM server.exe

# 清理殘留進程
tasklist | findstr server
```

## 使用方法

### Web 介面操作

1. **開啟瀏覽器** 訪問 http://127.0.0.1:3000

2. **貼上 YouTube 網址**
   - 支援單一影片: `https://www.youtube.com/watch?v=VIDEO_ID`
   - 支援播放清單: `https://www.youtube.com/playlist?list=PLAYLIST_ID`

3. **開始轉換**
   - 點擊「開始轉碼」按鈕
   - 等待轉換完成

4. **下載檔案**
   - 轉換完成後自動顯示下載連結
   - 點擊下載 MP3 檔案

### 服務管理

```cmd
# 檢視服務狀態
scripts\status.bat

# 檢視運行日誌
type server.log

# 重啟服務
scripts\stop.bat && scripts\start.bat
```

### 進階配置

#### 修改服務埠
```cmd
# 編輯配置 (如果需要)
# 默認埠: HTTP=3000, HTTPS=3443
```

#### SSL 證書管理
```cmd
# 重新生成 SSL 證書
bin\cert-gen.exe

# 檢查證書
dir certs\
```

## 故障排除

### 常見問題

#### 服務無法啟動
```cmd
# 檢查埠佔用
netstat -an | findstr ":3000"
netstat -an | findstr ":3443"

# 檢查防火牆設定
# Windows Defender 防火牆 > 允許應用程式通過防火牆
```

#### 下載失敗
```cmd
# 檢查 yt-dlp 是否存在
dir bin\yt-dlp.exe

# 更新 yt-dlp (如果需要)
# 從 https://github.com/yt-dlp/yt-dlp/releases 下載最新版本
```

#### 音頻處理問題
```cmd
# 檢查 FFmpeg (可選)
# 下載 FFmpeg 並解壓到 bin\ 目錄
```

### 日誌檢查

```cmd
# 檢視運行日誌
type server.log

# 檢視最新日誌
powershell "Get-Content server.log -Tail 50"
```

## 技術規格

### 系統需求
- **作業系統**: Windows 10/11 (64位元)
- **記憶體**: 最少 256MB RAM
- **儲存空間**: 100MB 可用空間
- **網路**: 需要網際網路連線

### 支援格式
- **輸入**: YouTube 影片網址、播放清單
- **輸出**: MP3 (128kbps-320kbps)、M4A

### 技術架構
- **後端**: Rust + Axum Web 框架
- **下載引擎**: yt-dlp
- **音頻處理**: FFmpeg (可選)
- **SSL/TLS**: 自簽名證書 + Rustls

## 開發資訊

如需開發相關資訊，請參閱 [DEVELOP.md](DEVELOP.md) 開發指南。

## 授權

本專案為開源軟體，具體授權條款請查看 LICENSE 文件。

---

**注意**: 請遵守 YouTube 服務條款，僅用於個人合法用途。
