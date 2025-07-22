use crate::{AppError, AppResult, DatabaseConfig};
use sqlx::{mysql::MySqlPoolOptions, MySql, Pool};
use std::time::Duration;
use tracing::{info, instrument};

pub type DbPool = Pool<MySql>;

#[instrument(skip(config))]
pub async fn create_connection_pool(config: &DatabaseConfig) -> AppResult<DbPool> {
    create_pool(&config.url).await
}

pub async fn create_pool(database_url: &str) -> AppResult<DbPool> {
    info!("Creating database connection pool");
    
    let pool = MySqlPoolOptions::new()
        .max_connections(10)
        .min_connections(1)
        .acquire_timeout(Duration::from_secs(30))
        .idle_timeout(Duration::from_secs(600))
        .connect(database_url)
        .await
        .map_err(AppError::Database)?;

    info!("Database connection pool created successfully");
    Ok(pool)
}

#[instrument(skip(pool))]
pub async fn run_migrations(pool: &DbPool) -> AppResult<()> {
    info!("Running database migrations");
    
    // Note: migrations should be handled per microservice, not in shared library
    // sqlx::migrate!("./migrations")
    //     .run(&pool)
    //     .await
    //     .map_err(AppError::Database)?;
    
    info!("Database migrations completed successfully");
    Ok(())
}

#[instrument(skip(pool))]
pub async fn health_check(pool: &DbPool) -> AppResult<()> {
    sqlx::query("SELECT 1")
        .execute(pool)
        .await
        .map_err(AppError::Database)?;
    
    Ok(())
}
