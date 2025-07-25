use empower_plant_shared::{AppError, AppResult, DbPool, User};
use sqlx::Row;
use uuid::Uuid;
use tracing::{error, instrument};

pub struct UserRepository {
    pool: DbPool,
}

impl UserRepository {
    pub fn new(pool: DbPool) -> Self {
        Self { pool }
    }

    #[instrument(skip(self))]
    pub async fn create(
        &self,
        email: String,
        password_hash: String,
        first_name: String,
        last_name: String,
        roles: Vec<String>,
    ) -> AppResult<User> {
        let id = Uuid::new_v4().to_string();
        let role = roles.first().unwrap_or(&"user".to_string()).clone();
        
        // Insert the user
        sqlx::query!(
            r#"
            INSERT INTO users (id, email, password_hash, first_name, last_name, role)
            VALUES (?, ?, ?, ?, ?, ?)
            "#,
            id,
            email,
            password_hash,
            first_name,
            last_name,
            role
        )
        .execute(&self.pool)
        .await
        .map_err(|e| {
            error!("Failed to create user: {}", e);
            AppError::Database(e)
        })?;

        // Fetch the created user
        let user = sqlx::query_as!(
            User,
            r#"
            SELECT id, email, password_hash, first_name, last_name, 
                   role, is_active, created_at, updated_at
            FROM users 
            WHERE id = ?
            "#,
            id
        )
        .fetch_one(&self.pool)
        .await
        .map_err(|e| {
            error!("Failed to fetch created user: {}", e);
            AppError::Database(e)
        })?;

        Ok(user)
    }

    #[instrument(skip(self))]
    pub async fn find_by_email(&self, email: &str) -> AppResult<Option<User>> {
        let user = sqlx::query_as!(
            User,
            r#"
            SELECT id, email, password_hash, first_name, last_name, 
                   role as "role: String", is_active, created_at, updated_at
            FROM users 
            WHERE email = ?
            "#,
            email
        )
        .fetch_optional(&self.pool)
        .await
        .map_err(|e| {
            error!("Failed to find user by email: {}", e);
            AppError::Database(e)
        })?;

        Ok(user)
    }

    #[instrument(skip(self))]
    pub async fn find_by_id(&self, user_id: &Uuid) -> AppResult<Option<User>> {
        let user = sqlx::query_as!(
            User,
            r#"
            SELECT id, email, password_hash, first_name, last_name, 
                   role as "role: String", is_active, created_at, updated_at
            FROM users 
            WHERE id = ?
            "#,
            user_id.to_string()
        )
        .fetch_optional(&self.pool)
        .await
        .map_err(|e| {
            error!("Failed to find user by ID: {}", e);
            AppError::Database(e)
        })?;

        Ok(user)
    }

    #[instrument(skip(self))]
    pub async fn find_all(&self, page: i32, per_page: i32) -> AppResult<Vec<User>> {
        let offset = (page - 1) * per_page;
        
        let users = sqlx::query_as!(
            User,
            r#"
            SELECT id, email, password_hash, first_name, last_name, 
                   role as "role: String", is_active, created_at, updated_at
            FROM users 
            WHERE is_active = true
            ORDER BY created_at DESC
            LIMIT ? OFFSET ?
            "#,
            per_page,
            offset
        )
        .fetch_all(&self.pool)
        .await
        .map_err(|e| {
            error!("Failed to find users: {}", e);
            AppError::Database(e)
        })?;

        Ok(users)
    }

    #[instrument(skip(self))]
    pub async fn update(&self, user_id: &Uuid, updates: serde_json::Value) -> AppResult<User> {
        // This is a simplified update - in a real implementation, you'd want to
        // validate and apply specific fields from the updates JSON
        let user = sqlx::query_as!(
            User,
            r#"
            SELECT id, email, password_hash, first_name, last_name, 
                   role as "role: String", is_active, created_at, updated_at
            FROM users 
            WHERE id = ?
            "#,
            user_id.to_string()
        )
        .fetch_one(&self.pool)
        .await
        .map_err(|e| {
            error!("Failed to find user for update: {}", e);
            AppError::Database(e)
        })?;

        // For now, just return the existing user
        // In a real implementation, you'd apply the updates
        Ok(user)
    }

    #[instrument(skip(self))]
    pub async fn deactivate(&self, user_id: &Uuid) -> AppResult<()> {
        sqlx::query!(
            "UPDATE users SET is_active = false WHERE id = ?",
            user_id.to_string()
        )
        .execute(&self.pool)
        .await
        .map_err(|e| {
            error!("Failed to deactivate user: {}", e);
            AppError::Database(e)
        })?;

        Ok(())
    }
}
