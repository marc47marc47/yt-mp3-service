# 服務管理說明

YT-MP3 Service 服務管理腳本使用指南

## 可用的服務管理腳本

### 1. 統一管理腳本 (推薦)

#### Bash 版本
```bash
# 查看狀態和幫助
scripts/service.sh

# 啟動服務
scripts/service.sh start

# 停止服務
scripts/service.sh stop

# 重啟服務
scripts/service.sh restart

# 查看詳細狀態
scripts/service.sh status --detailed

# 查看日志
scripts/service.sh logs

# 持續查看日志
scripts/service.sh logs --follow

# 構建項目
scripts/service.sh build

# 清理臨時文件
scripts/service.sh clean
```

#### Windows 批處理版本
```cmd
# 查看狀態和幫助
scripts\service.bat

# 啟動服務
scripts\service.bat start

# 停止服務
scripts\service.bat stop

# 重啟服務
scripts\service.bat restart

# 查看狀態
scripts\service.bat status

# 查看日志
scripts\service.bat logs

# 構建項目
scripts\service.bat build
```

### 2. 單獨功能腳本

#### 啟動服務
```bash
scripts/start.sh
```

#### 停止服務
```bash
# 基本停止
scripts/stop.sh

# 強制停止
scripts/stop.sh --force

# 停止並清理
scripts/stop.sh --clean
```

#### 狀態檢查
```bash
# 基本狀態
scripts/status.sh

# 詳細狀態
scripts/status.sh --detailed

# 監控模式
scripts/status.sh --watch
```

## 服務狀態說明

### 🟢 服務運行正常
- 進程正在運行
- 端口正常監聽
- HTTP/HTTPS 響應正常

### 🟡 服務運行但異常
- 進程運行但端口異常
- 端口正常但響應異常

### 🔴 服務未運行
- 進程未運行
- 端口未監聽

## 服務端口

- **HTTP**: `http://127.0.0.1:3000`
- **HTTPS**: `https://127.0.0.1:3443`

## 日志文件

- **位置**: `server.log`
- **查看**: `tail -f server.log` 或 `scripts/service.sh logs --follow`

## 進程管理

### PID 文件
- **位置**: `server.pid`
- **包含**: 服務器進程ID

### 進程查看
```bash
# 查看服務進程
ps aux | grep server

# 查看端口佔用
netstat -tulnp | grep -E ":(3000|3443)"
```

## 常見問題排除

### 1. 端口被佔用
```bash
# 查找佔用進程
netstat -tulnp | grep :3000
lsof -i :3000

# 終止佔用進程
scripts/service.sh stop --force
```

### 2. 服務啟動失敗
```bash
# 查看詳細狀態
scripts/service.sh status --detailed

# 查看日志
scripts/service.sh logs

# 檢查必要文件
ls -la bin/
ls -la certs/
```

### 3. 證書問題
```bash
# 重新生成證書
rm certs/*
bin/cert-gen.exe

# 或使用服務腳本
scripts/service.sh clean
scripts/service.sh build
```

### 4. 權限問題 (Linux/Mac)
```bash
# 賦予執行權限
chmod +x *.sh
chmod +x bin/*
```

## 服務管理最佳實踐

### 1. 定期檢查服務狀態
```bash
# 設置定時任務檢查服務
crontab -e
# 添加: */5 * * * * /path/to/service.sh status > /dev/null || /path/to/service.sh start
```

### 2. 日志輪轉
```bash
# 定期清理日志
if [ -f server.log ] && [ $(stat -f%z server.log) -gt 10485760 ]; then
    mv server.log server.log.old
    scripts/service.sh restart
fi
```

### 3. 監控服務
```bash
# 監控模式
scripts/service.sh status --watch
```

### 4. 自動重啟
```bash
# 檢查並自動重啟腳本
#!/bin/bash
if ! scripts/service.sh status > /dev/null; then
    echo "$(date): Service down, restarting..."
    scripts/service.sh start
fi
```

## 開發模式

### 開發時的服務管理
```bash
# 開發時快速重啟
scripts/service.sh restart

# 查看實時日志
scripts/service.sh logs --follow

# 查看詳細狀態
scripts/service.sh status --detailed
```

### 調試模式
```bash
# 前台運行 (不使用腳本)
bin/server.exe

# 查看詳細日志
RUST_LOG=debug bin/server.exe
```

## 生產環境

### 系統服務 (systemd)
```ini
# /etc/systemd/system/yt-mp3.service
[Unit]
Description=YT-MP3 Service
After=network.target

[Service]
Type=simple
User=your-user
WorkingDirectory=/path/to/yt-mp3-service
ExecStart=/path/to/yt-mp3-service/bin/server
ExecStop=/path/to/yt-mp3-service/service.sh stop
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
```

### 反向代理 (nginx)
```nginx
server {
    listen 80;
    server_name your-domain.com;
    
    location / {
        proxy_pass http://127.0.0.1:3000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

## 安全考慮

### 1. 防火墻設置
```bash
# 僅允許本地訪問
ufw allow from 127.0.0.1 to any port 3000
ufw allow from 127.0.0.1 to any port 3443
```

### 2. SSL證書
```bash
# 使用有效的SSL證書替換自簽證書
cp your-cert.pem certs/cert.pem
cp your-key.pem certs/key.pem
scripts/service.sh restart
```

### 3. 運行用戶
```bash
# 創建專用用戶
sudo useradd -r -s /bin/false yt-mp3
sudo chown -R yt-mp3:yt-mp3 /path/to/yt-mp3-service
```