use crate::{AppError, AppResult, JwtConfig};
use chrono::{Duration, Utc};
use jsonwebtoken::{decode, encode, Algorithm, DecodingKey, EncodingKey, Header, Validation};
use serde::{Deserialize, Serialize};
use uuid::Uuid;

#[derive(Debug, Serialize, Deserialize)]
pub struct Claims {
    pub sub: String, // User ID
    pub email: String,
    pub roles: Vec<String>,
    pub iat: i64, // Issued at
    pub exp: i64, // Expiry
}

#[derive(Clone)]
pub struct JwtService {
    encoding_key: EncodingKey,
    decoding_key: DecodingKey,
    config: JwtConfig,
}

impl JwtService {
    pub fn new(config: JwtConfig) -> Self {
        let encoding_key = EncodingKey::from_secret(config.secret.as_bytes());
        let decoding_key = DecodingKey::from_secret(config.secret.as_bytes());

        Self {
            encoding_key,
            decoding_key,
            config,
        }
    }

    pub fn generate_token(
        &self,
        user_id: &Uuid,
        email: &str,
        roles: Vec<String>,
    ) -> AppResult<String> {
        let now = Utc::now();
        let expires_at = now + Duration::hours(self.config.expiration_hours);

        let claims = Claims {
            sub: user_id.to_string(),
            email: email.to_string(),
            roles,
            iat: now.timestamp(),
            exp: expires_at.timestamp(),
        };

        encode(&Header::default(), &claims, &self.encoding_key)
            .map_err(|e| AppError::Authentication(format!("Failed to generate token: {}", e)))
    }

    pub fn generate_refresh_token(
        &self,
        user_id: &Uuid,
        email: &str,
        roles: Vec<String>,
    ) -> AppResult<String> {
        let now = Utc::now();
        let expires_at = now + Duration::days(self.config.refresh_expiration_days);

        let claims = Claims {
            sub: user_id.to_string(),
            email: email.to_string(),
            roles,
            iat: now.timestamp(),
            exp: expires_at.timestamp(),
        };

        encode(&Header::default(), &claims, &self.encoding_key)
            .map_err(|e| AppError::Authentication(format!("Failed to generate refresh token: {}", e)))
    }

    pub fn verify_token(&self, token: &str) -> AppResult<Claims> {
        decode::<Claims>(token, &self.decoding_key, &Validation::new(Algorithm::HS256))
            .map(|token_data| token_data.claims)
            .map_err(|e| AppError::Authentication(format!("Invalid token: {}", e)))
    }

    pub fn extract_user_id(&self, token: &str) -> AppResult<Uuid> {
        let claims = self.verify_token(token)?;
        Uuid::parse_str(&claims.sub)
            .map_err(|e| AppError::Authentication(format!("Invalid user ID in token: {}", e)))
    }
}

#[derive(Debug, Serialize, Deserialize)]
pub enum UserRole {
    Admin,
    Farmer,
    Viewer,
    Technician,
}

impl UserRole {
    pub fn to_string(&self) -> String {
        match self {
            UserRole::Admin => "admin".to_string(),
            UserRole::Farmer => "farmer".to_string(),
            UserRole::Viewer => "viewer".to_string(),
            UserRole::Technician => "technician".to_string(),
        }
    }

    pub fn from_string(role: &str) -> AppResult<Self> {
        match role.to_lowercase().as_str() {
            "admin" => Ok(UserRole::Admin),
            "farmer" => Ok(UserRole::Farmer),
            "viewer" => Ok(UserRole::Viewer),
            "technician" => Ok(UserRole::Technician),
            _ => Err(AppError::Validation(format!("Invalid role: {}", role))),
        }
    }

    pub fn can_access_resource(&self, resource: &str, action: &str) -> bool {
        match self {
            UserRole::Admin => true, // Admin can access everything
            UserRole::Farmer => {
                // Farmers can access their own data and perform farm operations
                matches!(
                    (resource, action),
                    ("plants", _) | ("sensors", _) | ("irrigation", _) | ("weather", "read")
                )
            }
            UserRole::Technician => {
                // Technicians can manage sensors and equipment
                matches!(
                    (resource, action),
                    ("sensors", _) | ("equipment", _) | ("alerts", "read")
                )
            }
            UserRole::Viewer => {
                // Viewers can only read data
                action == "read"
            }
        }
    }
}

pub fn hash_password(password: &str) -> AppResult<String> {
    bcrypt::hash(password, bcrypt::DEFAULT_COST)
        .map_err(|e| AppError::Internal(format!("Failed to hash password: {}", e)))
}

pub fn verify_password(password: &str, hash: &str) -> AppResult<bool> {
    bcrypt::verify(password, hash)
        .map_err(|e| AppError::Internal(format!("Failed to verify password: {}", e)))
}
