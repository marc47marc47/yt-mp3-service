use rcgen::{BasicConstraints, Certificate, CertificateParams, DnType, KeyPair, SanType};
use std::fs;
use std::path::Path;
use time::{Duration, OffsetDateTime};

fn main() -> Result<(), Box<dyn std::error::Error>> {
    println!("🔐 Generating self-signed SSL certificate...");

    // Ensure certs directory exists
    if !Path::new("certs").exists() {
        fs::create_dir("certs")?;
        println!("📁 Created certs directory");
    }

    // Generate certificate parameters
    let mut cert_params = CertificateParams::new(vec!["localhost".to_string()]);
    
    // Set certificate properties
    cert_params.distinguished_name.push(DnType::CommonName, "localhost");
    cert_params.distinguished_name.push(DnType::OrganizationName, "YT-MP3-Service");
    cert_params.distinguished_name.push(DnType::CountryName, "TW");
    
    // Set validity period (365 days)
    let now = OffsetDateTime::now_utc();
    cert_params.not_before = now;
    cert_params.not_after = now + Duration::days(365);
    
    // Add Subject Alternative Names
    cert_params.subject_alt_names = vec![
        SanType::DnsName("localhost".to_string()),
        SanType::IpAddress(std::net::IpAddr::V4(std::net::Ipv4Addr::new(127, 0, 0, 1))),
    ];
    
    // Set as CA certificate (for self-signing)
    cert_params.is_ca = rcgen::IsCa::Ca(BasicConstraints::Unconstrained);
    
    // Generate key pair
    let key_pair = KeyPair::generate(&rcgen::PKCS_ECDSA_P256_SHA256)?;
    cert_params.key_pair = Some(key_pair);
    
    // Generate certificate
    let cert = Certificate::from_params(cert_params)?;
    
    // Generate PEM format certificate and private key
    let cert_pem = cert.serialize_pem()?;
    let key_pem = cert.serialize_private_key_pem();
    
    // Write to files
    fs::write("certs/cert.pem", cert_pem)?;
    fs::write("certs/key.pem", key_pem)?;
    
    println!("✅ SSL certificate generated successfully!");
    println!("📄 Certificate file: certs/cert.pem");
    println!("🔑 Private key file: certs/key.pem");
    println!("⏰ Validity period: 365 days");
    println!("🌐 Supported domains: localhost, 127.0.0.1");
    
    // Verify the generated certificate
    println!("\n🔍 Verifying certificate...");
    let cert_content = fs::read_to_string("certs/cert.pem")?;
    let key_content = fs::read_to_string("certs/key.pem")?;
    
    if cert_content.contains("-----BEGIN CERTIFICATE-----") && 
       key_content.contains("-----BEGIN PRIVATE KEY-----") {
        println!("✅ Certificate format verification passed");
    } else {
        println!("❌ Certificate format verification failed");
        return Err("Certificate format is incorrect".into());
    }
    
    println!("\n🚀 Now you can start the HTTPS server!");
    
    Ok(())
}