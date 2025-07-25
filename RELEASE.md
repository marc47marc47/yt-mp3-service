# Release 打包說明

YT-MP3 Service Release 打包和分發指南

## 創建Release包

### 使用Bash腳本
```bash
# 創建release包
./build.sh --release

# 清理後創建release包
./build.sh --clean --release

# 查看幫助
./build.sh --help
```


## Release包結構

創建的release包包含以下結構：

```
yt-mp3-service_YYYYMMDD_HHMMSS/
├── bin/                    # 可執行文件
│   ├── server.exe         # 主服務器程序
│   ├── cert-gen.exe       # SSL證書生成工具
│   ├── yt-dlp.exe         # YouTube下載工具
│   ├── ffmpeg.exe         # 音頻處理工具
│   ├── ffplay.exe         # 音頻播放工具
│   └── ffprobe.exe        # 音頻信息工具
├── certs/                 # SSL證書目錄
│   ├── cert.pem          # SSL證書
│   └── key.pem           # SSL私鑰
├── downloads/             # 下載文件目錄
├── scripts/               # 管理腳本
│   ├── service.sh        # 統一服務管理腳本
│   ├── start.sh          # 啟動腳本
│   ├── stop.sh           # 停止腳本
│   ├── status.sh         # 狀態檢查腳本
│   └── build.sh          # 構建腳本
├── docs/                  # 文檔目錄
│   ├── BUILD.md          # 構建說明
│   ├── SERVICE.md        # 服務管理說明
│   └── Cargo.toml        # 項目配置
├── install.sh             # 安裝腳本
└── PACKAGE_INFO.txt       # 包信息文件
```

## 分發格式

release包會自動創建以下格式：

- **tar.gz**: `yt-mp3-service_YYYYMMDD_HHMMSS.tar.gz`
- **zip**: `yt-mp3-service_YYYYMMDD_HHMMSS.zip`

## 安裝流程

### 方法1: 使用安裝腳本 (推薦)

```bash
# 解壓包
tar -xzf yt-mp3-service_YYYYMMDD_HHMMSS.tar.gz
cd yt-mp3-service_YYYYMMDD_HHMMSS

# 或解壓 zip 包
unzip yt-mp3-service_YYYYMMDD_HHMMSS.zip
cd yt-mp3-service_YYYYMMDD_HHMMSS

# 運行安裝腳本
./install.sh
```

### 方法2: 手動安裝

```bash
# 創建安裝目錄
mkdir ~/yt-mp3-service
cd ~/yt-mp3-service

# 複製解壓的文件
cp -r /path/to/extracted/package/* .

# 設置執行權限 (Linux/macOS)
chmod +x bin/*
chmod +x scripts/*.sh

# 創建管理腳本鏈接
ln -sf scripts/service.sh service
```

## 使用Release包

### 啟動服務
```bash
# 進入安裝目錄
cd ~/yt-mp3-service

# 啟動服務
./service start

# 或使用腳本目錄
./scripts/service.sh start
```

### 管理服務
```bash
# 查看狀態
./service status

# 停止服務
./service stop

# 重啟服務
./service restart

# 查看日志
./service logs
```

### 訪問服務
- HTTP: http://127.0.0.1:3000
- HTTPS: https://127.0.0.1:3443

## 系統要求

### 最低要求
- **內存**: 256MB RAM
- **磁盤**: 100MB 可用空間
- **網絡**: 互聯網連接 (下載YouTube內容)

### 支持的操作系統
- Windows 10/11
- Ubuntu 18.04+
- CentOS 7+
- macOS 10.14+
- 其他支持Rust的Linux發行版

## 自定義配置

### SSL證書
```bash
# 重新生成證書
./bin/cert-gen.exe

# 或使用自己的證書
cp your-cert.pem certs/cert.pem
cp your-key.pem certs/key.pem
```

### 端口配置
默認端口：
- HTTP: 3000
- HTTPS: 3443

如需修改端口，需要重新編譯源代碼。

## 故障排除

### 安裝問題
```bash
# 檢查文件權限
ls -la bin/
chmod +x bin/*

# 檢查依賴
./bin/server.exe --help
```

### 運行問題
```bash
# 查看詳細狀態
./service status --detailed

# 查看日志
./service logs --follow

# 檢查端口
netstat -tulnp | grep -E ":(3000|3443)"
```

### 權限問題
```bash
# Linux/macOS設置權限
chmod +x bin/*
chmod +x scripts/*.sh

# 檢查SSL證書權限
ls -la certs/
```

## 卸載

### 自動卸載
```bash
# 停止服務
./service stop

# 刪除安裝目錄
rm -rf ~/yt-mp3-service
```

### 清理系統服務 (如果配置了)
```bash
# systemd (Linux)
sudo systemctl stop yt-mp3
sudo systemctl disable yt-mp3
sudo rm /etc/systemd/system/yt-mp3.service

# launchd (macOS)
sudo launchctl unload /Library/LaunchDaemons/com.yt-mp3.plist
sudo rm /Library/LaunchDaemons/com.yt-mp3.plist
```

## 更新

### 更新到新版本
```bash
# 停止當前服務
./service stop

# 備份配置 (如果有自定義)
cp certs/cert.pem ../backup/
cp certs/key.pem ../backup/

# 安裝新版本
# (按照新版本的安裝步驟)

# 恢復自定義配置
cp ../backup/cert.pem certs/
cp ../backup/key.pem certs/

# 啟動新版本
./service start
```

## 生產環境部署

### 系統服務配置

#### systemd (Linux)
```ini
# /etc/systemd/system/yt-mp3.service
[Unit]
Description=YT-MP3 Service
After=network.target

[Service]
Type=simple
User=yt-mp3
WorkingDirectory=/opt/yt-mp3-service
ExecStart=/opt/yt-mp3-service/bin/server
ExecStop=/opt/yt-mp3-service/service stop
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
```

#### 反向代理 (nginx)
```nginx
server {
    listen 80;
    server_name your-domain.com;
    
    location / {
        proxy_pass http://127.0.0.1:3000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

### 安全考慮
1. 使用專用用戶運行服務
2. 配置防火墻規則
3. 使用有效的SSL證書
4. 定期更新依賴
5. 監控系統資源

## 技術支持

如遇到問題，請：
1. 查看 `docs/` 目錄中的文檔
2. 檢查 `PACKAGE_INFO.txt` 中的版本信息
3. 使用 `./service status --detailed` 查看詳細狀態
4. 查看服務日志 `./service logs`