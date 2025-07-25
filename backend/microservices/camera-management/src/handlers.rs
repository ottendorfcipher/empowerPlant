use axum::{
    extract::{Path, Query, State},
    http::StatusCode,
    response::Json,
};
use chrono::Utc;
use serde::{Deserialize, Serialize};
use sqlx::MySqlPool;
use uuid::Uuid;
use validator::Validate;

use empowerplant_shared::{
    models::{
        ApiResponse, Camera, CreateCameraRequest, CameraStreamResponse, 
        CameraControlRequest
    },
    error::AppError,
};

use crate::service::CameraService;

pub async fn create_camera(
    State(pool): State<MySqlPool>,
    Json(request): Json<CreateCameraRequest>,
) -> Result<Json<ApiResponse<Camera>>, AppError> {
    request.validate()?;
    
    let service = CameraService::new(&pool);
    let camera = service.create_camera(request).await?;
    
    Ok(Json(ApiResponse::success(camera)))
}

pub async fn list_cameras(
    State(pool): State<MySqlPool>,
    Query(params): Query<ListCamerasQuery>,
) -> Result<Json<ApiResponse<Vec<Camera>>>, AppError> {
    let service = CameraService::new(&pool);
    let cameras = service.list_cameras(params.user_id).await?;
    
    Ok(Json(ApiResponse::success(cameras)))
}

pub async fn get_camera(
    State(pool): State<MySqlPool>,
    Path(camera_id): Path<Uuid>,
) -> Result<Json<ApiResponse<Camera>>, AppError> {
    let service = CameraService::new(&pool);
    let camera = service.get_camera(camera_id).await?;
    
    Ok(Json(ApiResponse::success(camera)))
}

pub async fn update_camera(
    State(pool): State<MySqlPool>,
    Path(camera_id): Path<Uuid>,
    Json(request): Json<UpdateCameraRequest>,
) -> Result<Json<ApiResponse<Camera>>, AppError> {
    let service = CameraService::new(&pool);
    let camera = service.update_camera(camera_id, request).await?;
    
    Ok(Json(ApiResponse::success(camera)))
}

pub async fn delete_camera(
    State(pool): State<MySqlPool>,
    Path(camera_id): Path<Uuid>,
) -> Result<StatusCode, AppError> {
    let service = CameraService::new(&pool);
    service.delete_camera(camera_id).await?;
    
    Ok(StatusCode::NO_CONTENT)
}

pub async fn update_camera_status(
    State(pool): State<MySqlPool>,
    Path(camera_id): Path<Uuid>,
    Json(request): Json<UpdateStatusRequest>,
) -> Result<Json<ApiResponse<Camera>>, AppError> {
    let service = CameraService::new(&pool);
    let camera = service.update_status(camera_id, request.status).await?;
    
    Ok(Json(ApiResponse::success(camera)))
}

pub async fn get_stream(
    State(pool): State<MySqlPool>,
    Path(camera_id): Path<Uuid>,
) -> Result<Json<ApiResponse<CameraStreamResponse>>, AppError> {
    let service = CameraService::new(&pool);
    let stream_info = service.get_stream_info(camera_id).await?;
    
    Ok(Json(ApiResponse::success(stream_info)))
}

pub async fn start_stream(
    State(pool): State<MySqlPool>,
    Path(camera_id): Path<Uuid>,
    Json(request): Json<StartStreamRequest>,
) -> Result<Json<ApiResponse<CameraStreamResponse>>, AppError> {
    let service = CameraService::new(&pool);
    let stream_info = service.start_stream(camera_id, request.user_id).await?;
    
    Ok(Json(ApiResponse::success(stream_info)))
}

pub async fn stop_stream(
    State(pool): State<MySqlPool>,
    Path(camera_id): Path<Uuid>,
) -> Result<StatusCode, AppError> {
    let service = CameraService::new(&pool);
    service.stop_stream(camera_id).await?;
    
    Ok(StatusCode::NO_CONTENT)
}

pub async fn camera_control(
    State(pool): State<MySqlPool>,
    Path(camera_id): Path<Uuid>,
    Json(request): Json<CameraControlRequest>,
) -> Result<Json<ApiResponse<String>>, AppError> {
    let service = CameraService::new(&pool);
    let result = service.execute_control_command(camera_id, request).await?;
    
    Ok(Json(ApiResponse::success(result)))
}

pub async fn take_snapshot(
    State(pool): State<MySqlPool>,
    Path(camera_id): Path<Uuid>,
    Json(request): Json<SnapshotRequest>,
) -> Result<Json<ApiResponse<SnapshotResponse>>, AppError> {
    let service = CameraService::new(&pool);
    let snapshot = service.take_snapshot(camera_id, request.user_id).await?;
    
    Ok(Json(ApiResponse::success(snapshot)))
}

pub async fn start_recording(
    State(pool): State<MySqlPool>,
    Path(camera_id): Path<Uuid>,
    Json(request): Json<RecordingRequest>,
) -> Result<Json<ApiResponse<RecordingResponse>>, AppError> {
    let service = CameraService::new(&pool);
    let recording = service.start_recording(camera_id, request).await?;
    
    Ok(Json(ApiResponse::success(recording)))
}

pub async fn stop_recording(
    State(pool): State<MySqlPool>,
    Path((camera_id, recording_id)): Path<(Uuid, Uuid)>,
) -> Result<StatusCode, AppError> {
    let service = CameraService::new(&pool);
    service.stop_recording(camera_id, recording_id).await?;
    
    Ok(StatusCode::NO_CONTENT)
}

pub async fn test_connection(
    State(pool): State<MySqlPool>,
    Path(camera_id): Path<Uuid>,
) -> Result<Json<ApiResponse<ConnectionTestResult>>, AppError> {
    let service = CameraService::new(&pool);
    let result = service.test_connection(camera_id).await?;
    
    Ok(Json(ApiResponse::success(result)))
}

pub async fn health_check() -> Json<ApiResponse<String>> {
    Json(ApiResponse::success("Camera Management Service is running".to_string()))
}

// Request/Response DTOs
#[derive(Debug, Deserialize)]
pub struct ListCamerasQuery {
    pub user_id: Option<Uuid>,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct UpdateCameraRequest {
    pub name: Option<String>,
    pub location: Option<String>,
    pub wifi_network: Option<String>,
    pub resolution: Option<String>,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct UpdateStatusRequest {
    pub status: String,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct StartStreamRequest {
    pub user_id: Uuid,
    pub resolution: Option<String>,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct SnapshotRequest {
    pub user_id: Uuid,
    pub description: Option<String>,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct SnapshotResponse {
    pub id: Uuid,
    pub image_url: String,
    pub taken_at: chrono::DateTime<Utc>,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct RecordingRequest {
    pub user_id: Uuid,
    pub duration_seconds: Option<i32>,
    pub quality: Option<String>,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct RecordingResponse {
    pub id: Uuid,
    pub status: String,
    pub estimated_duration: Option<i32>,
    pub started_at: chrono::DateTime<Utc>,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct ConnectionTestResult {
    pub success: bool,
    pub latency_ms: Option<i32>,
    pub signal_strength: Option<String>,
    pub error_message: Option<String>,
    pub tested_at: chrono::DateTime<Utc>,
}
