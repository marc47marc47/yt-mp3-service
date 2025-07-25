use axum::{
    extract::{Form, Path},
    http::{header, StatusCode},
    response::{Html, IntoResponse},
    routing::{get, post},
    Router,
};
use axum_server::tls_rustls::RustlsConfig;
use serde::Deserialize;
use std::{
    collections::HashMap,
    fs,
    path::PathBuf,
    process::Command,
    sync::{Arc, Mutex},
    time::{SystemTime, UNIX_EPOCH},
};
use tower_http::services::ServeDir;
use uuid::Uuid;

// 任務狀態枚舉
#[derive(Debug, Clone)]
enum TaskStatus {
    Processing,
    Completed(String, Option<String>), // 儲存音頻檔案路徑和縮圖檔案路徑
    Failed(String),    // 儲存錯誤訊息
}

// 全域任務狀態管理
type TaskMap = Arc<Mutex<HashMap<String, TaskStatus>>>;

// 表單資料結構
#[derive(Deserialize)]
struct ConvertForm {
    youtube_url: String,
}

#[tokio::main]
async fn main() {
    // 創建下載目錄
    let download_dir = "downloads";
    if !std::path::Path::new(download_dir).exists() {
        fs::create_dir_all(download_dir).expect("無法創建下載目錄");
    }

    // 初始化任務狀態管理
    let tasks: TaskMap = Arc::new(Mutex::new(HashMap::new()));

    // 設置路由
    let app = Router::new()
        .route("/", get(index_page))
        .route("/convert", post(convert_youtube))
        .route("/status/:task_id", get(check_status))
        .route("/download/:filename", get(download_file))
        .route("/thumbnail/:filename", get(serve_thumbnail))
        .nest_service("/static", ServeDir::new("static"))
        .with_state(tasks);

    // 配置TLS
    let config = RustlsConfig::from_pem_file(
        PathBuf::from("certs/cert.pem"),
        PathBuf::from("certs/key.pem"),
    )
    .await
    .expect("無法載入SSL證書");
    
    println!("🚀 HTTPS伺服器已啟動在 https://127.0.0.1:3443");
    println!("🌐 HTTP伺服器已啟動在 http://127.0.0.1:3000");
    
    // 同時啟動HTTP和HTTPS伺服器
    let app_clone = app.clone();
    tokio::spawn(async move {
        // HTTP伺服器
        let listener = tokio::net::TcpListener::bind("127.0.0.1:3000")
            .await
            .expect("無法綁定到端口 3000");
        axum::serve(listener, app_clone)
            .await
            .expect("HTTP伺服器啟動失敗");
    });
    
    // HTTPS伺服器
    axum_server::bind_rustls("127.0.0.1:3443".parse().unwrap(), config)
        .serve(app.into_make_service())
        .await
        .expect("HTTPS伺服器啟動失敗");
}

// 首頁
async fn index_page() -> Html<&'static str> {
    Html(r#"
    <!DOCTYPE html>
    <html lang="zh-TW">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>YouTube to MP3 轉碼器</title>
        <style>
            * {
                margin: 0;
                padding: 0;
                box-sizing: border-box;
            }
            
            body {
                font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
                background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                min-height: 100vh;
                display: flex;
                align-items: center;
                justify-content: center;
            }
            
            .container {
                background: white;
                padding: 2rem;
                border-radius: 15px;
                box-shadow: 0 20px 40px rgba(0,0,0,0.1);
                max-width: 500px;
                width: 90%;
            }
            
            h1 {
                text-align: center;
                color: #333;
                margin-bottom: 2rem;
                font-size: 2rem;
            }
            
            .form-group {
                margin-bottom: 1.5rem;
            }
            
            label {
                display: block;
                margin-bottom: 0.5rem;
                color: #555;
                font-weight: 500;
            }
            
            input[type="url"] {
                width: 100%;
                padding: 12px;
                border: 2px solid #ddd;
                border-radius: 8px;
                font-size: 16px;
                transition: border-color 0.3s;
            }
            
            input[type="url"]:focus {
                outline: none;
                border-color: #667eea;
            }
            
            .convert-btn {
                width: 100%;
                padding: 12px;
                background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                color: white;
                border: none;
                border-radius: 8px;
                font-size: 16px;
                font-weight: 600;
                cursor: pointer;
                transition: transform 0.2s;
            }
            
            .convert-btn:hover {
                transform: translateY(-2px);
            }
            
            .convert-btn:disabled {
                opacity: 0.6;
                cursor: not-allowed;
                transform: none;
            }
            
            #status {
                margin-top: 1.5rem;
                padding: 1rem;
                border-radius: 8px;
                display: none;
            }
            
            .status-processing {
                background-color: #fff3cd;
                border: 1px solid #ffeaa7;
                color: #856404;
            }
            
            .status-completed {
                background-color: #d4edda;
                border: 1px solid #c3e6cb;
                color: #155724;
            }
            
            .status-failed {
                background-color: #f8d7da;
                border: 1px solid #f5c6cb;
                color: #721c24;
            }
            
            .download-link {
                display: inline-block;
                margin-top: 10px;
                padding: 8px 16px;
                background-color: #28a745;
                color: white;
                text-decoration: none;
                border-radius: 5px;
                font-weight: 500;
            }
            
            .download-link:hover {
                background-color: #218838;
            }
            
            .spinner {
                border: 2px solid #f3f3f3;
                border-top: 2px solid #667eea;
                border-radius: 50%;
                width: 20px;
                height: 20px;
                animation: spin 1s linear infinite;
                display: inline-block;
                margin-right: 10px;
            }
            
            @keyframes spin {
                0% { transform: rotate(0deg); }
                100% { transform: rotate(360deg); }
            }
        </style>
    </head>
    <body>
        <div class="container">
            <h1>🎵 YouTube to MP3</h1>
            <form id="convertForm">
                <div class="form-group">
                    <label for="youtube_url">YouTube 網址:</label>
                    <input 
                        type="url" 
                        id="youtube_url" 
                        name="youtube_url" 
                        placeholder="請輸入 YouTube 影片網址..."
                        required
                    >
                </div>
                <button type="submit" class="convert-btn" id="convertBtn">
                    開始轉碼
                </button>
            </form>
            
            <div id="status"></div>
        </div>
        
        <script>
            let currentTaskId = null;
            let statusInterval = null;
            
            document.getElementById('convertForm').addEventListener('submit', async (e) => {
                e.preventDefault();
                
                const formData = new FormData(e.target);
                const convertBtn = document.getElementById('convertBtn');
                const statusDiv = document.getElementById('status');
                
                // 禁用按鈕並顯示處理中狀態
                convertBtn.disabled = true;
                convertBtn.innerHTML = '<div class="spinner"></div>處理中...';
                
                try {
                    const response = await fetch('/convert', {
                        method: 'POST',
                        headers: {
                            'Content-Type': 'application/x-www-form-urlencoded',
                        },
                        body: new URLSearchParams(formData)
                    });
                    
                    const result = await response.json();
                    
                    if (response.ok) {
                        currentTaskId = result.task_id;
                        statusDiv.style.display = 'block';
                        statusDiv.className = 'status-processing';
                        statusDiv.innerHTML = '<div class="spinner"></div>正在轉碼中，請稍候...';
                        
                        // 開始輪詢狀態
                        statusInterval = setInterval(checkStatus, 2000);
                    } else {
                        throw new Error(result.error || '轉碼失敗');
                    }
                } catch (error) {
                    statusDiv.style.display = 'block';
                    statusDiv.className = 'status-failed';
                    statusDiv.innerHTML = `❌ 錯誤: ${error.message}`;
                    
                    convertBtn.disabled = false;
                    convertBtn.innerHTML = '開始轉碼';
                }
            });
            
            async function checkStatus() {
                if (!currentTaskId) return;
                
                try {
                    const response = await fetch(`/status/${currentTaskId}`);
                    const result = await response.json();
                    const statusDiv = document.getElementById('status');
                    const convertBtn = document.getElementById('convertBtn');
                    
                    if (result.status === 'completed') {
                        clearInterval(statusInterval);
                        statusDiv.className = 'status-completed';
                        
                        let thumbnailHtml = '';
                        if (result.thumbnail) {
                            thumbnailHtml = `
                                <div style="margin: 10px 0;">
                                    <img src="/thumbnail/${result.thumbnail}" 
                                         alt="影片縮圖" 
                                         style="max-width: 200px; max-height: 150px; border-radius: 8px; box-shadow: 0 2px 8px rgba(0,0,0,0.1);">
                                </div>
                            `;
                        }
                        
                        statusDiv.innerHTML = `
                            ✅ 轉碼完成！
                            ${thumbnailHtml}
                            <a href="/download/${result.filename}" class="download-link" download>
                                📥 下載 MP3
                            </a>
                        `;
                        
                        convertBtn.disabled = false;
                        convertBtn.innerHTML = '開始轉碼';
                        currentTaskId = null;
                    } else if (result.status === 'failed') {
                        clearInterval(statusInterval);
                        statusDiv.className = 'status-failed';
                        statusDiv.innerHTML = `❌ 轉碼失敗: ${result.error}`;
                        
                        convertBtn.disabled = false;
                        convertBtn.innerHTML = '開始轉碼';
                        currentTaskId = null;
                    }
                } catch (error) {
                    console.error('檢查狀態時發生錯誤:', error);
                }
            }
        </script>
    </body>
    </html>
    "#)
}

// 轉碼處理
async fn convert_youtube(
    axum::extract::State(tasks): axum::extract::State<TaskMap>,
    Form(form): Form<ConvertForm>,
) -> Result<axum::response::Json<serde_json::Value>, StatusCode> {
    // 驗證 YouTube URL
    if !form.youtube_url.contains("youtube.com") && !form.youtube_url.contains("youtu.be") {
        return Ok(axum::response::Json(serde_json::json!({
            "error": "請提供有效的 YouTube 網址"
        })));
    }
    
    // 生成唯一任務 ID
    let task_id = Uuid::new_v4().to_string();
    
    // 將任務標記為處理中
    {
        let mut tasks_lock = tasks.lock().unwrap();
        tasks_lock.insert(task_id.clone(), TaskStatus::Processing);
    }
    
    // 異步執行轉碼
    let tasks_clone = tasks.clone();
    let task_id_clone = task_id.clone();
    let url = form.youtube_url.clone();
    
    tokio::spawn(async move {
        let result = perform_conversion(&url).await;
        
        let mut tasks_lock = tasks_clone.lock().unwrap();
        match result {
            Ok((audio_filename, thumbnail_filename)) => {
                tasks_lock.insert(task_id_clone, TaskStatus::Completed(audio_filename, thumbnail_filename));
            }
            Err(error) => {
                tasks_lock.insert(task_id_clone, TaskStatus::Failed(error));
            }
        }
    });
    
    Ok(axum::response::Json(serde_json::json!({
        "task_id": task_id,
        "status": "processing"
    })))
}

// 實際執行轉碼
async fn perform_conversion(url: &str) -> Result<(String, Option<String>), String> {
    let timestamp = SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .unwrap()
        .as_secs();
    
    // 使用yt-dlp的輸出模板來直接使用視頻標題作為文件名
    // 這樣可以避免編碼問題，讓yt-dlp自己處理文件名
    let output_template = format!("downloads/%(title).100s.%(ext)s");
    
    // 執行 yt-dlp 命令下載音頻和縮圖
    let output = Command::new("bin/yt-dlp.exe")
        .args([
            "--extract-audio",
            "--audio-format", "mp3",
            "--audio-quality", "192K",
            "--write-thumbnail",
            "--output", &output_template,
            url,
        ])
        .output();
    
    match output {
        Ok(result) => {
            if result.status.success() {
                // 查找最新創建的mp3和縮圖文件
                match find_latest_downloaded_files(timestamp) {
                    Some((audio_filename, thumbnail_filename)) => {
                        Ok((audio_filename, thumbnail_filename))
                    }
                    None => {
                        Err("轉碼完成但找不到下載的檔案".to_string())
                    }
                }
            } else {
                let error_msg = String::from_utf8_lossy(&result.stderr);
                Err(format!("yt-dlp 執行失敗: {}", error_msg))
            }
        }
        Err(e) => Err(format!("無法執行 bin/yt-dlp.exe: {}。請確保 yt-dlp.exe 在 bin/ 目錄中", e)),
    }
}

// 查找最新下載的文件
fn find_latest_downloaded_files(since_timestamp: u64) -> Option<(String, Option<String>)> {
    use std::fs;
    use std::time::UNIX_EPOCH;
    
    let downloads_dir = std::path::Path::new("downloads");
    if !downloads_dir.exists() {
        return None;
    }
    
    let mut audio_file = None;
    let mut thumbnail_file = None;
    
    if let Ok(entries) = fs::read_dir(downloads_dir) {
        for entry in entries {
            if let Ok(entry) = entry {
                let path = entry.path();
                if let Ok(metadata) = entry.metadata() {
                    if let Ok(modified) = metadata.modified() {
                        if let Ok(duration) = modified.duration_since(UNIX_EPOCH) {
                            // 只檢查在轉換開始後創建的文件
                            if duration.as_secs() >= since_timestamp {
                                if let Some(filename) = path.file_name() {
                                    let filename_str = filename.to_string_lossy().to_string();
                                    
                                    if filename_str.ends_with(".mp3") && audio_file.is_none() {
                                        audio_file = Some(filename_str.clone());
                                    } else if (filename_str.ends_with(".jpg") || 
                                              filename_str.ends_with(".jpeg") || 
                                              filename_str.ends_with(".png") || 
                                              filename_str.ends_with(".webp")) && 
                                              thumbnail_file.is_none() {
                                        thumbnail_file = Some(filename_str.clone());
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    if let Some(audio) = audio_file {
        Some((audio, thumbnail_file))
    } else {
        None
    }
}

// 從yt-dlp的JSON輸出中提取標題
fn extract_title_from_json(json_str: &str) -> Option<String> {
    // 簡單的JSON解析來獲取title字段
    if let Ok(json_value) = serde_json::from_str::<serde_json::Value>(json_str) {
        if let Some(title) = json_value.get("title") {
            if let Some(title_str) = title.as_str() {
                return Some(title_str.to_string());
            }
        }
    }
    None
}

// 清理檔案名稱，移除不安全的字符
fn sanitize_filename(title: &str) -> String {
    let mut sanitized = title.to_string();
    
    // 移除或替換不安全的字符
    let unsafe_chars = ['/', '\\', ':', '*', '?', '"', '<', '>', '|'];
    for char in unsafe_chars {
        sanitized = sanitized.replace(char, "_");
    }
    
    // 移除多餘的空格並替換為下劃線
    sanitized = sanitized.trim().replace(' ', "_");
    
    // 限制長度以避免檔案名過長
    if sanitized.len() > 100 {
        sanitized.truncate(100);
    }
    
    // 如果清理後為空，使用預設名稱
    if sanitized.is_empty() {
        sanitized = format!("YouTube_Audio_{}", 
            SystemTime::now()
                .duration_since(UNIX_EPOCH)
                .unwrap()
                .as_secs());
    }
    
    sanitized
}

// 查找縮圖文件
fn find_thumbnail_file(base_filename: &str) -> Option<String> {
    let extensions = ["jpg", "jpeg", "png", "webp"];
    for ext in &extensions {
        let thumbnail_filename = format!("{}.{}", base_filename, ext);
        let thumbnail_path = format!("downloads/{}", thumbnail_filename);
        if std::path::Path::new(&thumbnail_path).exists() {
            return Some(thumbnail_filename);
        }
    }
    None
}

// 檢查任務狀態
async fn check_status(
    axum::extract::State(tasks): axum::extract::State<TaskMap>,
    Path(task_id): Path<String>,
) -> axum::response::Json<serde_json::Value> {
    let tasks_lock = tasks.lock().unwrap();
    
    match tasks_lock.get(&task_id) {
        Some(TaskStatus::Processing) => {
            axum::response::Json(serde_json::json!({
                "status": "processing"
            }))
        }
        Some(TaskStatus::Completed(audio_filename, thumbnail_filename)) => {
            let mut response = serde_json::json!({
                "status": "completed",
                "filename": audio_filename
            });
            
            if let Some(thumb_file) = thumbnail_filename {
                response["thumbnail"] = serde_json::Value::String(thumb_file.clone());
            }
            
            axum::response::Json(response)
        }
        Some(TaskStatus::Failed(error)) => {
            axum::response::Json(serde_json::json!({
                "status": "failed",
                "error": error
            }))
        }
        None => {
            axum::response::Json(serde_json::json!({
                "status": "not_found",
                "error": "找不到該任務"
            }))
        }
    }
}

// 檔案下載
async fn download_file(Path(filename): Path<String>) -> impl IntoResponse {
    let file_path = PathBuf::from("downloads").join(&filename);
    
    // 安全性檢查：確保檔案在 downloads 目錄內
    if !file_path.starts_with("downloads") {
        return Err(StatusCode::FORBIDDEN);
    }
    
    match fs::read(&file_path) {
        Ok(contents) => {
            let headers = [
                (header::CONTENT_TYPE, "audio/mpeg".to_string()),
                (header::CONTENT_DISPOSITION, format!("attachment; filename=\"{}\"", filename)),
            ];
            
            Ok((headers, contents))
        }
        Err(_) => Err(StatusCode::NOT_FOUND),
    }
}

// 縮圖服務
async fn serve_thumbnail(Path(filename): Path<String>) -> impl IntoResponse {
    let file_path = PathBuf::from("downloads").join(&filename);
    
    // 安全性檢查：確保檔案在 downloads 目錄內
    if !file_path.starts_with("downloads") {
        return Err(StatusCode::FORBIDDEN);
    }
    
    match fs::read(&file_path) {
        Ok(contents) => {
            // 根據文件擴展名確定內容類型
            let content_type = match file_path.extension().and_then(|ext| ext.to_str()) {
                Some("jpg") | Some("jpeg") => "image/jpeg",
                Some("png") => "image/png", 
                Some("webp") => "image/webp",
                _ => "image/jpeg", // 默認
            };
            
            let headers = [
                (header::CONTENT_TYPE, content_type.to_string()),
                (header::CACHE_CONTROL, "public, max-age=3600".to_string()),
            ];
            
            Ok((headers, contents))
        }
        Err(_) => Err(StatusCode::NOT_FOUND),
    }
}
