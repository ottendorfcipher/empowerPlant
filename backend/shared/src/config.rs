use config::{Config, ConfigError, Environment, File};
use serde::Deserialize;
use std::env;

#[derive(Debug, Deserialize, Clone)]
pub struct DatabaseConfig {
    pub url: String,
    pub max_connections: u32,
    pub min_connections: u32,
    pub connect_timeout: u64,
    pub idle_timeout: u64,
}

#[derive(Debug, Deserialize, Clone)]
pub struct KafkaConfig {
    pub bootstrap_servers: String,
    pub group_id: String,
    pub enable_auto_commit: bool,
    pub session_timeout_ms: u32,
    pub security_protocol: Option<String>,
    pub sasl_mechanism: Option<String>,
    pub sasl_username: Option<String>,
    pub sasl_password: Option<String>,
}

#[derive(Debug, Deserialize, Clone)]
pub struct RedisConfig {
    pub url: String,
    pub max_connections: u32,
    pub connection_timeout: u64,
}

#[derive(Debug, Deserialize, Clone)]
pub struct JwtConfig {
    pub secret: String,
    pub expiration_hours: i64,
    pub refresh_expiration_days: i64,
}

#[derive(Debug, Deserialize, Clone)]
pub struct ServerConfig {
    pub host: String,
    pub port: u16,
    pub workers: Option<usize>,
    pub cors_origins: Vec<String>,
}

#[derive(Debug, Deserialize, Clone)]
pub struct LoggingConfig {
    pub level: String,
    pub json_format: bool,
}

#[derive(Debug, Deserialize, Clone)]
pub struct AppConfig {
    pub server: ServerConfig,
    pub database: DatabaseConfig,
    pub kafka: KafkaConfig,
    pub redis: RedisConfig,
    pub jwt: JwtConfig,
    pub logging: LoggingConfig,
    pub environment: String,
}

impl AppConfig {
    pub fn from_env() -> Result<Self, ConfigError> {
        let environment = env::var("APP_ENVIRONMENT").unwrap_or_else(|_| "development".to_string());
        
        let config = Config::builder()
            .add_source(File::with_name("config/default").required(false))
            .add_source(File::with_name(&format!("config/{}", environment)).required(false))
            .add_source(Environment::with_prefix("APP").separator("_"));

        // Build and deserialize configuration
        config.build()?.try_deserialize()
    }

    pub fn is_production(&self) -> bool {
        self.environment == "production"
    }

    pub fn is_development(&self) -> bool {
        self.environment == "development"
    }
}
