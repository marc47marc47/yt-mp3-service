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

// Task status enum
#[derive(Debug, Clone)]
enum TaskStatus {
    Processing,
    Completed(String, Option<String>), // Store audio file path and thumbnail file path
    Failed(String),    // Store error message
}

// Global task status management
type TaskMap = Arc<Mutex<HashMap<String, TaskStatus>>>;

// Form data structure
#[derive(Deserialize)]
struct ConvertForm {
    youtube_url: String,
}

#[tokio::main]
async fn main() {
    // Create download directory
    let download_dir = "downloads";
    if !std::path::Path::new(download_dir).exists() {
        fs::create_dir_all(download_dir).expect("Failed to create download directory");
    }

    // Initialize task status management
    let tasks: TaskMap = Arc::new(Mutex::new(HashMap::new()));

    // Setup routes
    let app = Router::new()
        .route("/", get(index_page))
        .route("/convert", post(convert_youtube))
        .route("/status/:task_id", get(check_status))
        .route("/download/:filename", get(download_file))
        .route("/thumbnail/:filename", get(serve_thumbnail))
        .nest_service("/static", ServeDir::new("static"))
        .with_state(tasks);

    // Configure TLS
    let config = RustlsConfig::from_pem_file(
        PathBuf::from("certs/cert.pem"),
        PathBuf::from("certs/key.pem"),
    )
    .await
    .expect("Failed to load SSL certificate");
    
    println!("🚀 HTTPS server started at https://127.0.0.1:3443");
    println!("🌐 HTTP server started at http://127.0.0.1:3000");
    
    // Start both HTTP and HTTPS servers
    let app_clone = app.clone();
    tokio::spawn(async move {
        // HTTP server
        let listener = tokio::net::TcpListener::bind("127.0.0.1:3000")
            .await
            .expect("Unable to bind to port 3000");
        axum::serve(listener, app_clone)
            .await
            .expect("Failed to start HTTP server");
    });
    
    // HTTPS server
    axum_server::bind_rustls("127.0.0.1:3443".parse().unwrap(), config)
        .serve(app.into_make_service())
        .await
        .expect("Failed to start HTTPS server");
}

// Home page
async fn index_page() -> Html<&'static str> {
    Html(r#"
    <!DOCTYPE html>
    <html lang="en">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>YouTube to MP3 Converter</title>
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
                    <label for="youtube_url">YouTube URL:</label>
                    <input 
                        type="url" 
                        id="youtube_url" 
                        name="youtube_url" 
                        placeholder="Please enter YouTube video URL..."
                        required
                    >
                </div>
                <button type="submit" class="convert-btn" id="convertBtn">
                    Start Conversion
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
                
                // Disable button and show processing status
                convertBtn.disabled = true;
                convertBtn.innerHTML = '<div class="spinner"></div>Processing...';
                
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
                        statusDiv.innerHTML = '<div class="spinner"></div>Converting, please wait...';
                        
                        // Start polling status
                        statusInterval = setInterval(checkStatus, 2000);
                    } else {
                        throw new Error(result.error || 'Conversion failed');
                    }
                } catch (error) {
                    statusDiv.style.display = 'block';
                    statusDiv.className = 'status-failed';
                    statusDiv.innerHTML = `❌ Error: ${error.message}`;
                    
                    convertBtn.disabled = false;
                    convertBtn.innerHTML = 'Start Conversion';
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
                                         alt="Video thumbnail" 
                                         style="max-width: 200px; max-height: 150px; border-radius: 8px; box-shadow: 0 2px 8px rgba(0,0,0,0.1);">
                                </div>
                            `;
                        }
                        
                        statusDiv.innerHTML = `
                            ✅ Conversion completed!
                            ${thumbnailHtml}
                            <a href="/download/${result.filename}" class="download-link" download>
                                📥 Download MP3
                            </a>
                        `;
                        
                        convertBtn.disabled = false;
                        convertBtn.innerHTML = 'Start Conversion';
                        currentTaskId = null;
                    } else if (result.status === 'failed') {
                        clearInterval(statusInterval);
                        statusDiv.className = 'status-failed';
                        statusDiv.innerHTML = `❌ Conversion failed: ${result.error}`;
                        
                        convertBtn.disabled = false;
                        convertBtn.innerHTML = 'Start Conversion';
                        currentTaskId = null;
                    }
                } catch (error) {
                    console.error('Error occurred while checking status:', error);
                }
            }
        </script>
    </body>
    </html>
    "#)
}

// Conversion processing
async fn convert_youtube(
    axum::extract::State(tasks): axum::extract::State<TaskMap>,
    Form(form): Form<ConvertForm>,
) -> Result<axum::response::Json<serde_json::Value>, StatusCode> {
    // Validate YouTube URL
    if !form.youtube_url.contains("youtube.com") && !form.youtube_url.contains("youtu.be") {
        return Ok(axum::response::Json(serde_json::json!({
            "error": "Please provide a valid YouTube URL"
        })));
    }
    
    // Generate unique task ID
    let task_id = Uuid::new_v4().to_string();
    
    // Mark task as processing
    {
        let mut tasks_lock = tasks.lock().unwrap();
        tasks_lock.insert(task_id.clone(), TaskStatus::Processing);
    }
    
    // Execute conversion asynchronously
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

// Actually perform conversion
async fn perform_conversion(url: &str) -> Result<(String, Option<String>), String> {
    let timestamp = SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .unwrap()
        .as_secs();
    
    // Use timestamp to create unique output template, avoiding filename conflicts
    let output_template = format!("downloads/%(title).100s_{}.%(ext)s", timestamp);
    
    // Execute yt-dlp command to download audio and thumbnail
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
                // Find the latest created mp3 and thumbnail files
                match find_latest_downloaded_files(timestamp) {
                    Some((audio_filename, thumbnail_filename)) => {
                        Ok((audio_filename, thumbnail_filename))
                    }
                    None => {
                        Err("Conversion completed but downloaded files not found".to_string())
                    }
                }
            } else {
                let error_msg = String::from_utf8_lossy(&result.stderr);
                Err(format!("yt-dlp execution failed: {}", error_msg))
            }
        }
        Err(e) => Err(format!("Cannot execute bin/yt-dlp.exe: {}. Please ensure yt-dlp.exe is in the bin/ directory", e)),
    }
}

// Find the latest downloaded files
fn find_latest_downloaded_files(since_timestamp: u64) -> Option<(String, Option<String>)> {
    use std::fs;
    use std::time::UNIX_EPOCH;
    
    let downloads_dir = std::path::Path::new("downloads");
    if !downloads_dir.exists() {
        return None;
    }
    
    let mut latest_audio_file = None;
    let mut latest_audio_time = 0u64;
    let mut latest_thumbnail_file = None;
    let mut latest_thumbnail_time = 0u64;
    
    if let Ok(entries) = fs::read_dir(downloads_dir) {
        for entry in entries {
            if let Ok(entry) = entry {
                let path = entry.path();
                if let Ok(metadata) = entry.metadata() {
                    if let Ok(modified) = metadata.modified() {
                        if let Ok(duration) = modified.duration_since(UNIX_EPOCH) {
                            let file_timestamp = duration.as_secs();
                            // Check files created or modified after conversion started
                            if file_timestamp >= since_timestamp {
                                if let Some(filename) = path.file_name() {
                                    let filename_str = filename.to_string_lossy().to_string();
                                    
                                    // Find the latest audio file
                                    if filename_str.ends_with(".mp3") && file_timestamp > latest_audio_time {
                                        latest_audio_file = Some(filename_str.clone());
                                        latest_audio_time = file_timestamp;
                                    } 
                                    // Find the latest thumbnail file
                                    else if (filename_str.ends_with(".jpg") || 
                                              filename_str.ends_with(".jpeg") || 
                                              filename_str.ends_with(".png") || 
                                              filename_str.ends_with(".webp")) && 
                                              file_timestamp > latest_thumbnail_time {
                                        latest_thumbnail_file = Some(filename_str.clone());
                                        latest_thumbnail_time = file_timestamp;
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    // If no new audio file is found, try to find any mp3 file in downloads directory
    // This handles cases where files are overwritten but timestamps are not updated
    if latest_audio_file.is_none() {
        if let Ok(entries) = fs::read_dir(downloads_dir) {
            for entry in entries {
                if let Ok(entry) = entry {
                    let path = entry.path();
                    if let Some(filename) = path.file_name() {
                        let filename_str = filename.to_string_lossy().to_string();
                        if filename_str.ends_with(".mp3") {
                            // Verify the file actually exists and is readable
                            if path.exists() && fs::metadata(&path).is_ok() {
                                latest_audio_file = Some(filename_str);
                                break;
                            }
                        }
                    }
                }
            }
        }
    }
    
    if let Some(audio) = latest_audio_file {
        Some((audio, latest_thumbnail_file))
    } else {
        None
    }
}

// Extract title from yt-dlp's JSON output
fn extract_title_from_json(json_str: &str) -> Option<String> {
    // Simple JSON parsing to get title field
    if let Ok(json_value) = serde_json::from_str::<serde_json::Value>(json_str) {
        if let Some(title) = json_value.get("title") {
            if let Some(title_str) = title.as_str() {
                return Some(title_str.to_string());
            }
        }
    }
    None
}

// Clean filename, remove unsafe characters
fn sanitize_filename(title: &str) -> String {
    let mut sanitized = title.to_string();
    
    // Remove or replace unsafe characters
    let unsafe_chars = ['/', '\\', ':', '*', '?', '"', '<', '>', '|'];
    for char in unsafe_chars {
        sanitized = sanitized.replace(char, "_");
    }
    
    // Remove extra spaces and replace with underscores
    sanitized = sanitized.trim().replace(' ', "_");
    
    // Limit length to avoid filename being too long
    if sanitized.len() > 100 {
        sanitized.truncate(100);
    }
    
    // If empty after cleaning, use default name
    if sanitized.is_empty() {
        sanitized = format!("YouTube_Audio_{}", 
            SystemTime::now()
                .duration_since(UNIX_EPOCH)
                .unwrap()
                .as_secs());
    }
    
    sanitized
}

// Find thumbnail file
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

// Check task status
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
                "error": "Task not found"
            }))
        }
    }
}

// File download
async fn download_file(Path(filename): Path<String>) -> impl IntoResponse {
    let file_path = PathBuf::from("downloads").join(&filename);
    
    // Security check: ensure file is within downloads directory
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

// Thumbnail service
async fn serve_thumbnail(Path(filename): Path<String>) -> impl IntoResponse {
    let file_path = PathBuf::from("downloads").join(&filename);
    
    // Security check: ensure file is within downloads directory
    if !file_path.starts_with("downloads") {
        return Err(StatusCode::FORBIDDEN);
    }
    
    match fs::read(&file_path) {
        Ok(contents) => {
            // Determine content type based on file extension
            let content_type = match file_path.extension().and_then(|ext| ext.to_str()) {
                Some("jpg") | Some("jpeg") => "image/jpeg",
                Some("png") => "image/png", 
                Some("webp") => "image/webp",
                _ => "image/jpeg", // Default
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
