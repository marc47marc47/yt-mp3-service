# YT-MP3 Service 開發指南

一個使用 Rust 和 Axum 構建的高性能 YouTube 轉 MP3 服務的完整開發文檔。

## 目錄

- [快速開始](#快速開始)
- [項目架構](#項目架構)
- [開發環境設置](#開發環境設置)
- [構建系統](#構建系統)
- [服務管理](#服務管理)
- [開發工作流程](#開發工作流程)
- [測試與調試](#測試與調試)
- [代碼風格與規範](#代碼風格與規範)
- [部署指南](#部署指南)
- [問題排除](#問題排除)
- [貢獻指南](#貢獻指南)

## 快速開始

### 開發環境要求

- **Rust**: 最新穩定版本 (1.70+)
- **Cargo**: Rust 包管理器
- **FFmpeg**: 音頻處理工具 (可選)
- **網絡連接**: 下載 yt-dlp 和處理 YouTube 內容

### 快速設置

```bash
# 1. 克隆項目
git clone <repository-url>
cd yt-mp3-service

# 2. 檢查 Rust 環境
cargo --version
rustc --version

# 3. 構建項目
./build.sh

# 4. 啟動服務
scripts/service.sh start

# 5. 訪問服務
# HTTP: http://127.0.0.1:3000
# HTTPS: https://127.0.0.1:3443
```

## 項目架構

### 目錄結構

```
yt-mp3-service/
├── src/                        # 源代碼
│   ├── main.rs                # 主服務器應用
│   └── bin/                   # 二進制工具
│       └── cert-gen.rs        # SSL 證書生成工具
├── bin/                       # 編譯產物和工具
│   ├── server(.exe)           # 主服務器程序
│   ├── cert-gen(.exe)         # 證書生成工具
│   ├── yt-dlp(.exe)          # YouTube 下載工具
│   └── ffmpeg/               # 音頻處理工具
├── certs/                    # SSL 證書
│   ├── cert.pem              # 公鑰證書
│   └── key.pem               # 私鑰
├── downloads/                # 下載文件存儲
├── scripts/                  # 服務管理腳本
│   ├── service.sh           # 統一服務管理腳本
│   ├── start.sh/start.bat   # 啟動腳本
│   ├── stop.sh/stop.bat     # 停止腳本
│   └── status.sh/status.bat # 狀態檢查腳本
├── docs/                     # 文檔目錄
│   ├── BUILD.md              # 構建說明
│   ├── SERVICE.md            # 服務管理說明
│   └── DEVELOP.md            # 開發指南 (本文件)
├── build.sh                  # 主構建腳本
├── Cargo.toml               # Rust 項目配置
└── README.md                # 項目說明
```

### 核心組件

#### 1. Web 服務器 (`src/main.rs`)
- 基於 Axum 框架
- 支持 HTTP/HTTPS 雙協議
- 異步處理請求
- 任務狀態管理

#### 2. SSL 證書生成器 (`src/bin/cert-gen.rs`)
- 自動生成自簽名證書
- 支持 RSA 和 ECDSA 算法
- 證書有效期管理

#### 3. 服務管理系統
- 跨平台服務控制
- 進程監控和重啟
- 日志管理
- 狀態檢查

### 技術棧

#### Rust 依賴

```toml
# Web 框架
axum = "0.7"                    # 現代異步 Web 框架
axum-server = "0.6"             # HTTPS 服務器支持

# 異步運行時
tokio = { version = "1.0", features = ["full"] }

# 中間件和工具
tower = "0.4"                   # 服務抽象層
tower-http = "0.5"              # HTTP 中間件

# 序列化
serde = { version = "1.0", features = ["derive"] }
serde_json = "1.0"

# 其他工具
uuid = "1.0"                    # UUID 生成
rustls = "0.21"                 # TLS 實現
rcgen = "0.11"                  # 證書生成
time = "0.3"                    # 時間處理
```

#### 外部工具

- **yt-dlp**: YouTube 內容下載
- **FFmpeg**: 音頻格式轉換和處理

## 開發環境設置

### 1. Rust 工具鏈安裝

```bash
# 安裝 Rust
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh

# 重新加載環境
source $HOME/.cargo/env

# 驗證安裝
cargo --version
rustc --version
```

### 2. 開發工具

```bash
# 代碼格式化
cargo install rustfmt

# 代碼檢查
cargo install clippy

# 文檔生成
cargo doc --open
```

### 3. IDE 配置推薦

#### VS Code
```json
{
  "rust-analyzer.checkOnSave.command": "clippy",
  "rust-analyzer.cargo.buildScripts.enable": true,
  "rust-analyzer.procMacro.enable": true
}
```

#### IntelliJ IDEA
- 安裝 Rust 插件
- 啟用 Cargo 項目自動導入

## 構建系統

### 構建腳本概覽

項目提供多種構建方式以適應不同平台和需求：

```bash
# Bash 腳本 (推薦)
./build.sh

# Windows 批處理
build.bat

# PowerShell 腳本
./build.ps1
```

### 構建過程詳解

#### 1. 環境檢查
```bash
# 檢查 Rust 工具鏈
cargo --version >/dev/null 2>&1 || {
    echo "錯誤: 未找到 Rust 工具鏈"
    exit 1
}
```

#### 2. 目錄準備
```bash
# 創建必要目錄
mkdir -p bin certs downloads
```

#### 3. 編譯階段
```bash
# 編譯證書生成工具
cargo build --bin cert-gen --release

# 編譯主服務器
cargo build --bin server --release
```

#### 4. 部署階段
```bash
# 複製二進制文件
cp target/release/cert-gen bin/
cp target/release/server bin/

# 生成SSL證書 (如果不存在)
[ ! -f certs/cert.pem ] && bin/cert-gen
```

### 構建選項

#### Debug 模式
```bash
# 快速構建，包含調試信息
cargo build

# 或使用腳本
./build.ps1 -Debug
```

#### Release 模式
```bash
# 優化構建，生產環境使用
cargo build --release

# 默認模式
./build.sh
```

#### 清理構建
```bash
# 清理並重新構建
cargo clean
./build.sh --clean
```

## 服務管理

### 統一管理接口

使用 `scripts/service.sh` 腳本進行完整的服務生命週期管理：

```bash
# 查看幫助和狀態
scripts/service.sh

# 啟動服務
scripts/service.sh start

# 停止服務
scripts/service.sh stop

# 重啟服務
scripts/service.sh restart

# 查看狀態
scripts/service.sh status

# 查看日志
scripts/service.sh logs

# 實時日志
scripts/service.sh logs --follow
```

### 服務狀態監控

#### 狀態指示器
- 🟢 **正常運行**: 進程活躍，端口響應
- 🟡 **異常運行**: 進程存在但服務異常
- 🔴 **未運行**: 服務完全停止

#### 監控命令
```bash
# 基本狀態檢查
scripts/service.sh status

# 詳細狀態信息
scripts/service.sh status --detailed

# 持續監控
scripts/service.sh status --watch
```

### 日志管理

#### 日志位置
- **主日志**: `server.log`
- **PID 文件**: `server.pid`

#### 日志查看
```bash
# 查看最近的日志
tail -f server.log

# 使用服務腳本
scripts/service.sh logs --follow
```

## 開發工作流程

### 1. 功能開發流程

```bash
# 1. 創建功能分支
git checkout -b feature/new-feature

# 2. 進行開發
# 編輯代碼...

# 3. 測試構建
./build.sh

# 4. 啟動測試
scripts/service.sh restart

# 5. 功能測試
# 訪問 http://127.0.0.1:3000

# 6. 代碼格式化
cargo fmt

# 7. 代碼檢查
cargo clippy

# 8. 提交更改
git add .
git commit -m "feat: add new feature"

# 9. 合併到主分支
git checkout main
git merge feature/new-feature
```

### 2. 熱重載開發

```bash
# 安裝 cargo-watch (僅需一次)
cargo install cargo-watch

# 自動重新編譯和重啟
cargo watch -x "build --release" -s "scripts/service.sh restart"
```

### 3. 調試流程

#### 開發調試
```bash
# 前台運行以查看實時輸出
bin/server

# 調試模式
RUST_LOG=debug bin/server
```

#### 生產調試
```bash
# 查看詳細狀態
scripts/service.sh status --detailed

# 查看日志
scripts/service.sh logs --follow

# 檢查進程
ps aux | grep server
```

## 測試與調試

### 單元測試

```bash
# 運行所有測試
cargo test

# 運行特定測試
cargo test test_name

# 詳細測試輸出
cargo test -- --nocapture
```

### 集成測試

#### API 測試
```bash
# 測試基本連接
curl http://127.0.0.1:3000/

# 測試下載功能
curl -X POST http://127.0.0.1:3000/download \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "url=https://www.youtube.com/watch?v=VIDEO_ID"

# 測試狀態查詢
curl http://127.0.0.1:3000/status/TASK_ID
```

#### 性能測試
```bash
# 使用 wrk 進行負載測試
wrk -t12 -c400 -d30s --timeout 10s http://127.0.0.1:3000/

# 使用 ab 進行基準測試
ab -n 1000 -c 10 http://127.0.0.1:3000/
```

### 調試工具

#### 內存分析
```bash
# 使用 valgrind (Linux)
valgrind --tool=memcheck ./bin/server

# 使用 heaptrack (Linux)
heaptrack ./bin/server
```

#### 性能分析
```bash
# 使用 perf (Linux)
perf record ./bin/server
perf report

# 使用 cargo flamegraph
cargo install flamegraph
cargo flamegraph --bin server
```

## 代碼風格與規範

### 格式化標準

```bash
# 自動格式化所有代碼
cargo fmt

# 檢查格式化
cargo fmt -- --check
```

### 代碼檢查

```bash
# 運行 Clippy 檢查
cargo clippy

# 嚴格模式
cargo clippy -- -D warnings
```

### 命名規範

#### 文件和目錄
- 使用 `snake_case` 命名文件
- 目錄名使用小寫，用連字符分隔

#### Rust 代碼
```rust
// 結構體使用 PascalCase
struct TaskStatus;

// 函數和變量使用 snake_case
fn process_download() {}
let task_id = generate_id();

// 常量使用 SCREAMING_SNAKE_CASE
const MAX_DOWNLOAD_SIZE: usize = 1024;

// 類型別名使用 PascalCase
type TaskMap = Arc<Mutex<HashMap<String, TaskStatus>>>;
```

### 文檔規範

#### 函數文檔
```rust
/// 處理 YouTube 視頻下載請求
/// 
/// # Arguments
/// 
/// * `url` - YouTube 視頻 URL
/// * `task_id` - 任務唯一標識符
/// 
/// # Returns
/// 
/// 返回 `Result<String, Error>` 包含下載文件路徑或錯誤信息
/// 
/// # Examples
/// 
/// ```
/// let result = process_download("https://youtube.com/watch?v=123", "task-123");
/// ```
fn process_download(url: &str, task_id: &str) -> Result<String, Error> {
    // 實現...
}
```

## 部署指南

### 開發環境部署

```bash
# 1. 構建項目
./build.sh

# 2. 啟動服務
scripts/service.sh start

# 3. 驗證部署
curl http://127.0.0.1:3000/
```

### 生產環境部署

#### 系統服務配置

##### systemd (Linux)
```ini
# /etc/systemd/system/yt-mp3.service
[Unit]
Description=YT-MP3 Service
After=network.target

[Service]
Type=simple
User=yt-mp3
Group=yt-mp3
WorkingDirectory=/opt/yt-mp3-service
ExecStart=/opt/yt-mp3-service/bin/server
ExecStop=/opt/yt-mp3-service/scripts/service.sh stop
Restart=always
RestartSec=5
StandardOutput=append:/var/log/yt-mp3/access.log
StandardError=append:/var/log/yt-mp3/error.log

[Install]
WantedBy=multi-user.target
```

```bash
# 啟用服務
sudo systemctl enable yt-mp3
sudo systemctl start yt-mp3
sudo systemctl status yt-mp3
```

##### Windows Service
```bash
# 使用 NSSM 註冊 Windows 服務
nssm install "YT-MP3 Service" "C:\path\to\yt-mp3-service\bin\yt-mp3.exe"
nssm set "YT-MP3 Service" AppDirectory "C:\path\to\yt-mp3-service"
nssm start "YT-MP3 Service"
```

#### 反向代理配置

##### Nginx
```nginx
server {
    listen 80;
    server_name your-domain.com;
    
    # 重定向到 HTTPS
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name your-domain.com;
    
    ssl_certificate /path/to/cert.pem;
    ssl_certificate_key /path/to/key.pem;
    
    location / {
        proxy_pass http://127.0.0.1:3000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # 支持大文件上傳
        client_max_body_size 100M;
        proxy_request_buffering off;
    }
}
```

##### Apache
```apache
<VirtualHost *:443>
    ServerName your-domain.com
    
    SSLEngine on
    SSLCertificateFile /path/to/cert.pem
    SSLCertificateKeyFile /path/to/key.pem
    
    ProxyPreserveHost On
    ProxyPass / http://127.0.0.1:3000/
    ProxyPassReverse / http://127.0.0.1:3000/
</VirtualHost>
```

### 容器化部署

#### Dockerfile
```dockerfile
FROM rust:1.70 as builder

WORKDIR /app
COPY Cargo.toml Cargo.lock ./
COPY src ./src

RUN cargo build --release

FROM debian:bookworm-slim

RUN apt-get update && apt-get install -y \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY --from=builder /app/target/release/server ./bin/server
COPY --from=builder /app/target/release/cert-gen ./bin/cert-gen

RUN mkdir -p certs downloads

EXPOSE 3000 3443

CMD ["./bin/server"]
```

#### Docker Compose
```yaml
version: '3.8'

services:
  yt-mp3:
    build: .
    ports:
      - "3000:3000"
      - "3443:3443"
    volumes:
      - ./downloads:/app/downloads
      - ./certs:/app/certs
    restart: unless-stopped
    environment:
      - RUST_LOG=info
```

## 問題排除

### 常見問題

#### 1. 構建失敗

**問題**: `cargo build` 失敗
```bash
# 解決方案
# 1. 更新 Rust 工具鏈
rustup update

# 2. 清理並重新構建
cargo clean
cargo build

# 3. 檢查依賴
cargo check
```

**問題**: 鏈接器錯誤
```bash
# Linux 解決方案
sudo apt-get install build-essential

# macOS 解決方案
xcode-select --install
```

#### 2. 服務啟動問題

**問題**: 端口被佔用
```bash
# 查找佔用進程
netstat -tulnp | grep -E ":(3000|3443)"
lsof -i :3000

# 終止進程
scripts/service.sh stop --force
pkill -f server
```

**問題**: 證書問題
```bash
# 重新生成證書
rm certs/*
bin/cert-gen

# 檢查證書有效性
openssl x509 -in certs/cert.pem -text -noout
```

#### 3. 下載功能問題

**問題**: yt-dlp 不存在或過期
```bash
# 下載最新版本
curl -L https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp -o bin/yt-dlp
chmod +x bin/yt-dlp

# Windows
curl -L https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp.exe -o bin/yt-dlp.exe
```

**問題**: FFmpeg 相關錯誤
```bash
# Linux
sudo apt-get install ffmpeg

# macOS
brew install ffmpeg

# Windows - 下載 FFmpeg 並解壓到 bin/ 目錄
```

### 調試技巧

#### 啟用詳細日志
```bash
# 設置日志級別
export RUST_LOG=debug
./bin/server

# 或者直接運行
RUST_LOG=trace ./bin/server
```

#### 網絡調試
```bash
# 檢查服務可達性
curl -v http://127.0.0.1:3000/
curl -k -v https://127.0.0.1:3443/

# 檢查 SSL 證書
openssl s_client -connect 127.0.0.1:3443 -servername localhost
```

#### 系統資源監控
```bash
# 監控進程
top -p $(pgrep server)

# 監控網絡連接
ss -tulnp | grep server

# 檢查磁盤使用
du -sh downloads/
```

## 貢獻指南

### 代碼貢獻流程

1. **Fork 項目**
   ```bash
   git clone https://github.com/your-username/yt-mp3-service.git
   cd yt-mp3-service
   ```

2. **創建功能分支**
   ```bash
   git checkout -b feature/amazing-feature
   ```

3. **開發和測試**
   ```bash
   # 開發代碼
   # 運行測試
   cargo test
   
   # 格式化代碼
   cargo fmt
   
   # 代碼檢查
   cargo clippy
   ```

4. **提交更改**
   ```bash
   git add .
   git commit -m "feat: add amazing feature"
   ```

5. **推送和創建 PR**
   ```bash
   git push origin feature/amazing-feature
   # 在 GitHub 上創建 Pull Request
   ```

### 提交信息規範

使用 [Conventional Commits](https://conventionalcommits.org/) 格式：

```
type(scope): description

body

footer
```

#### 類型 (type)
- `feat`: 新功能
- `fix`: 錯誤修復
- `docs`: 文檔更新
- `style`: 代碼格式化
- `refactor`: 代碼重構
- `test`: 測試相關
- `chore`: 構建過程或輔助工具的變動

#### 示例
```
feat(api): add thumbnail download endpoint

Add new endpoint /thumbnail/{task_id} to download video thumbnails.
The endpoint supports both JPEG and WebP formats.

Closes #123
```

### 代碼審查標準

#### 必須檢查項目
- [ ] 代碼符合項目風格規範
- [ ] 包含適當的錯誤處理
- [ ] 添加或更新了相關測試
- [ ] 更新了相關文檔
- [ ] 通過所有現有測試
- [ ] 沒有引入安全漏洞

#### 推薦檢查項目
- [ ] 性能影響評估
- [ ] 內存使用優化
- [ ] 日志記錄適當
- [ ] 向後兼容性

### 問題報告

提交問題時請包含：

1. **環境信息**
   - 操作系統和版本
   - Rust 版本
   - 項目版本

2. **問題描述**
   - 期望行為
   - 實際行為
   - 重現步驟

3. **相關日志**
   ```bash
   # 收集相關信息
   rustc --version
   cargo --version
   scripts/service.sh status --detailed
   tail -50 server.log
   ```

### 文檔貢獻

#### 文檔類型
- **API 文檔**: 代碼中的 Rustdoc 註釋
- **用戶指南**: README.md 和相關 .md 文件
- **開發文檔**: 本文件 (DEVELOP.md)
- **構建文檔**: BUILD.md
- **服務文檔**: SERVICE.md

#### 文檔標準
- 使用清晰、簡潔的語言
- 提供實際可運行的示例
- 保持更新和準確性
- 支持多語言（中英文）

---

## 聯繫和支持

- **問題報告**: 使用 GitHub Issues
- **功能請求**: 使用 GitHub Discussions
- **安全問題**: 請發送郵件至維護者

感謝您對 YT-MP3 Service 的貢獻！🎵