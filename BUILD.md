# 構建說明

YT-MP3 Service 自動化構建腳本使用指南

## 可用的構建腳本

### 1. Bash 腳本 (推薦)
```bash
# 基本構建
./build.sh

# 賦予執行權限（如果需要）
chmod +x build.sh && ./build.sh
```

### 2. Windows 批處理文件
```cmd
build.bat
```

### 3. PowerShell 腳本
```powershell
# 基本構建
.\build.ps1

# 使用debug模式
.\build.ps1 -Debug

# 跳過證書生成
.\build.ps1 -NoCert

# 強制清理重建
.\build.ps1 -Clean
```

## 構建過程

腳本會自動執行以下步驟：

1. **🔍 檢查環境**
   - 驗證 Rust 工具鏈 (cargo, rustc)
   - 檢查必要的依賴

2. **🧹 清理構建**
   - 清理之前的編譯產物

3. **📁 準備目錄**
   - 創建 `bin/`, `certs/`, `downloads/` 目錄

4. **🔧 編譯工具**
   - 編譯證書生成工具 (`cert-gen`)
   - 部署到 `bin/cert-gen.exe`

5. **🔐 生成證書**
   - 自動生成SSL自簽證書（如果不存在）
   - 保存到 `certs/cert.pem` 和 `certs/key.pem`

6. **🚀 編譯服務器**
   - 編譯主服務器 (`server`)
   - 部署到 `bin/server.exe`

7. **✅ 驗證部署**
   - 檢查所有文件是否正確部署
   - 顯示構建結果和使用說明

## 構建產物

構建完成後，`bin/` 目錄包含：

- `cert-gen.exe` - SSL證書生成工具
- `server.exe` - 主服務器程序
- `yt-dlp.exe` - YouTube下載工具（需手動放置）
- `ffmpeg.exe`, `ffplay.exe`, `ffprobe.exe` - 音頻處理工具

## 使用方法

### 生成新證書
```bash
bin/cert-gen.exe
```

### 啟動服務器
```bash
# 直接啟動
bin/server.exe

# 或使用服務管理腳本
scripts/start.bat
```

### 訪問服務
- HTTP: http://127.0.0.1:3000
- HTTPS: https://127.0.0.1:3443

## 故障排除

### 權限問題
如果在Linux/Mac上遇到權限問題：
```bash
chmod +x build.sh
chmod +x bin/*
```

### Rust工具鏈問題
確保已安裝Rust：
```bash
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
```

### 證書問題
重新生成證書：
```bash
rm certs/*
bin/cert-gen.exe
```

### 端口佔用
如果端口被佔用，終止現有進程：
```bash
# Linux/Mac
pkill -f server

# Windows
taskkill /F /IM server.exe
```

## 開發模式

使用debug模式進行開發：
```powershell
.\build.ps1 -Debug
```

Debug模式特點：
- 編譯速度更快
- 包含調試符號
- 文件大小較大
- 性能較低

## 生產部署

使用release模式進行生產部署：
```bash
./build.sh  # 默認使用release模式
```

Release模式特點：
- 編譯時間較長
- 優化的機器碼
- 文件大小較小
- 性能最佳