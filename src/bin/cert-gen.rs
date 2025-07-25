use rcgen::{BasicConstraints, Certificate, CertificateParams, DnType, KeyPair, SanType};
use std::fs;
use std::path::Path;
use time::{Duration, OffsetDateTime};

fn main() -> Result<(), Box<dyn std::error::Error>> {
    println!("🔐 正在生成自簽SSL證書...");

    // 確保certs目錄存在
    if !Path::new("certs").exists() {
        fs::create_dir("certs")?;
        println!("📁 創建了certs目錄");
    }

    // 生成證書參數
    let mut cert_params = CertificateParams::new(vec!["localhost".to_string()]);
    
    // 設置證書屬性
    cert_params.distinguished_name.push(DnType::CommonName, "localhost");
    cert_params.distinguished_name.push(DnType::OrganizationName, "YT-MP3-Service");
    cert_params.distinguished_name.push(DnType::CountryName, "TW");
    
    // 設置有效期（365天）
    let now = OffsetDateTime::now_utc();
    cert_params.not_before = now;
    cert_params.not_after = now + Duration::days(365);
    
    // 添加Subject Alternative Names
    cert_params.subject_alt_names = vec![
        SanType::DnsName("localhost".to_string()),
        SanType::IpAddress(std::net::IpAddr::V4(std::net::Ipv4Addr::new(127, 0, 0, 1))),
    ];
    
    // 設置為CA證書（用於自簽）
    cert_params.is_ca = rcgen::IsCa::Ca(BasicConstraints::Unconstrained);
    
    // 生成密鑰對
    let key_pair = KeyPair::generate(&rcgen::PKCS_ECDSA_P256_SHA256)?;
    cert_params.key_pair = Some(key_pair);
    
    // 生成證書
    let cert = Certificate::from_params(cert_params)?;
    
    // 生成PEM格式的證書和私鑰
    let cert_pem = cert.serialize_pem()?;
    let key_pem = cert.serialize_private_key_pem();
    
    // 寫入文件
    fs::write("certs/cert.pem", cert_pem)?;
    fs::write("certs/key.pem", key_pem)?;
    
    println!("✅ SSL證書生成完成！");
    println!("📄 證書文件: certs/cert.pem");
    println!("🔑 私鑰文件: certs/key.pem");
    println!("⏰ 有效期: 365天");
    println!("🌐 支持域名: localhost, 127.0.0.1");
    
    // 驗證生成的證書
    println!("\n🔍 驗證證書...");
    let cert_content = fs::read_to_string("certs/cert.pem")?;
    let key_content = fs::read_to_string("certs/key.pem")?;
    
    if cert_content.contains("-----BEGIN CERTIFICATE-----") && 
       key_content.contains("-----BEGIN PRIVATE KEY-----") {
        println!("✅ 證書格式驗證通過");
    } else {
        println!("❌ 證書格式驗證失敗");
        return Err("證書格式不正確".into());
    }
    
    println!("\n🚀 現在可以啟動HTTPS伺服器了！");
    
    Ok(())
}