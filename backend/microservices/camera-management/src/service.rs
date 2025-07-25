use chrono::Utc;
use sqlx::MySqlPool;
use uuid::Uuid;

use empowerplant_shared::{
    models::{
        Camera, CreateCameraRequest, CameraStreamResponse, CameraControlRequest
    },
    error::AppError,
    events::{
        Event, CameraRegisteredEvent, CameraStatusChangedEvent, CameraStreamStartedEvent,
        CameraRecordingStartedEvent, CameraSnapshotTakenEvent, create_event_metadata,
        CAMERA_EVENTS_TOPIC
    },
    kafka::KafkaProducer,
};

use crate::handlers::{
    UpdateCameraRequest, SnapshotResponse, RecordingRequest, RecordingResponse,
    ConnectionTestResult
};

pub struct CameraService<'a> {
    pool: &'a MySqlPool,
}

impl<'a> CameraService<'a> {
    pub fn new(pool: &'a MySqlPool) -> Self {
        Self { pool }
    }

    pub async fn create_camera(&self, request: CreateCameraRequest) -> Result<Camera, AppError> {
        let camera_id = Uuid::new_v4();
        let user_id = Uuid::new_v4(); // TODO: Extract from JWT token
        let now = Utc::now();

        let camera = sqlx::query_as!(
            Camera,
            r#"
            INSERT INTO cameras (id, name, location, camera_type, wifi_network, status, user_id, created_at, updated_at)
            VALUES (?, ?, ?, ?, ?, 'setup_required', ?, ?, ?)
            "#,
            camera_id.to_string(),
            request.name,
            request.location,
            request.camera_type.unwrap_or_else(|| "generic".to_string()),
            request.wifi_network,
            user_id.to_string(),
            now,
            now
        )
        .execute(self.pool)
        .await?;

        // Publish event
        let event = Event::CameraRegistered(CameraRegisteredEvent {
            metadata: create_event_metadata("camera-management", None),
            camera_id,
            name: request.name.clone(),
            location: request.location.clone(),
            camera_type: request.camera_type.unwrap_or_else(|| "generic".to_string()),
            user_id,
        });

        let kafka_producer = KafkaProducer::new().await?;
        kafka_producer.publish_event(CAMERA_EVENTS_TOPIC, &event).await?;

        // Return created camera
        self.get_camera(camera_id).await
    }

    pub async fn list_cameras(&self, user_id: Option<Uuid>) -> Result<Vec<Camera>, AppError> {
        let cameras = if let Some(user_id) = user_id {
            sqlx::query_as!(
                Camera,
                "SELECT * FROM cameras WHERE user_id = ? ORDER BY created_at DESC",
                user_id.to_string()
            )
            .fetch_all(self.pool)
            .await?
        } else {
            sqlx::query_as!(Camera, "SELECT * FROM cameras ORDER BY created_at DESC")
                .fetch_all(self.pool)
                .await?
        };

        Ok(cameras)
    }

    pub async fn get_camera(&self, camera_id: Uuid) -> Result<Camera, AppError> {
        let camera = sqlx::query_as!(
            Camera,
            "SELECT * FROM cameras WHERE id = ?",
            camera_id.to_string()
        )
        .fetch_optional(self.pool)
        .await?
        .ok_or(AppError::NotFound("Camera not found".to_string()))?;

        Ok(camera)
    }

    pub async fn update_camera(
        &self,
        camera_id: Uuid,
        request: UpdateCameraRequest,
    ) -> Result<Camera, AppError> {
        let mut query = "UPDATE cameras SET updated_at = ?".to_string();
        let mut params: Vec<String> = vec![Utc::now().to_string()];

        if let Some(name) = request.name {
            query.push_str(", name = ?");
            params.push(name);
        }
        if let Some(location) = request.location {
            query.push_str(", location = ?");
            params.push(location);
        }
        if let Some(wifi_network) = request.wifi_network {
            query.push_str(", wifi_network = ?");
            params.push(wifi_network);
        }
        if let Some(resolution) = request.resolution {
            query.push_str(", resolution = ?");
            params.push(resolution);
        }

        query.push_str(" WHERE id = ?");
        params.push(camera_id.to_string());

        sqlx::query(&query)
            .bind(&params[0])
            .execute(self.pool)
            .await?;

        self.get_camera(camera_id).await
    }

    pub async fn delete_camera(&self, camera_id: Uuid) -> Result<(), AppError> {
        let result = sqlx::query!("DELETE FROM cameras WHERE id = ?", camera_id.to_string())
            .execute(self.pool)
            .await?;

        if result.rows_affected() == 0 {
            return Err(AppError::NotFound("Camera not found".to_string()));
        }

        Ok(())
    }

    pub async fn update_status(&self, camera_id: Uuid, status: String) -> Result<Camera, AppError> {
        let old_camera = self.get_camera(camera_id).await?;

        sqlx::query!(
            "UPDATE cameras SET status = ?, updated_at = ? WHERE id = ?",
            status,
            Utc::now(),
            camera_id.to_string()
        )
        .execute(self.pool)
        .await?;

        // Publish status change event
        let event = Event::CameraStatusChanged(CameraStatusChangedEvent {
            metadata: create_event_metadata("camera-management", None),
            camera_id,
            old_status: old_camera.status,
            new_status: status,
            reason: None,
        });

        let kafka_producer = KafkaProducer::new().await?;
        kafka_producer.publish_event(CAMERA_EVENTS_TOPIC, &event).await?;

        self.get_camera(camera_id).await
    }

    pub async fn get_stream_info(&self, camera_id: Uuid) -> Result<CameraStreamResponse, AppError> {
        let camera = self.get_camera(camera_id).await?;

        Ok(CameraStreamResponse {
            stream_url: camera.stream_url.unwrap_or_else(|| {
                format!("rtsp://camera-{}.local:554/stream", camera_id)
            }),
            status: camera.status,
            resolution: camera.resolution.unwrap_or_else(|| "1080p".to_string()),
            frame_rate: 30,
        })
    }

    pub async fn start_stream(&self, camera_id: Uuid, user_id: Uuid) -> Result<CameraStreamResponse, AppError> {
        let camera = self.get_camera(camera_id).await?;
        
        if camera.status != "active" {
            return Err(AppError::BadRequest("Camera is not active".to_string()));
        }

        let stream_url = format!("rtsp://camera-{}.local:554/stream", camera_id);
        let resolution = camera.resolution.unwrap_or_else(|| "1080p".to_string());

        // Update camera with stream URL
        sqlx::query!(
            "UPDATE cameras SET stream_url = ?, updated_at = ? WHERE id = ?",
            stream_url,
            Utc::now(),
            camera_id.to_string()
        )
        .execute(self.pool)
        .await?;

        // Publish stream started event
        let event = Event::CameraStreamStarted(CameraStreamStartedEvent {
            metadata: create_event_metadata("camera-management", None),
            camera_id,
            stream_url: stream_url.clone(),
            resolution: resolution.clone(),
            started_by: user_id,
        });

        let kafka_producer = KafkaProducer::new().await?;
        kafka_producer.publish_event(CAMERA_EVENTS_TOPIC, &event).await?;

        Ok(CameraStreamResponse {
            stream_url,
            status: "streaming".to_string(),
            resolution,
            frame_rate: 30,
        })
    }

    pub async fn stop_stream(&self, camera_id: Uuid) -> Result<(), AppError> {
        sqlx::query!(
            "UPDATE cameras SET stream_url = NULL, updated_at = ? WHERE id = ?",
            Utc::now(),
            camera_id.to_string()
        )
        .execute(self.pool)
        .await?;

        Ok(())
    }

    pub async fn execute_control_command(
        &self,
        camera_id: Uuid,
        request: CameraControlRequest,
    ) -> Result<String, AppError> {
        let _camera = self.get_camera(camera_id).await?;

        // Simulate camera control commands
        match request.action.as_str() {
            "record" => Ok("Recording started".to_string()),
            "snapshot" => Ok("Snapshot taken".to_string()),
            "audio_toggle" => Ok("Audio toggled".to_string()),
            _ => Err(AppError::BadRequest("Unknown camera action".to_string())),
        }
    }

    pub async fn take_snapshot(&self, camera_id: Uuid, user_id: Uuid) -> Result<SnapshotResponse, AppError> {
        let _camera = self.get_camera(camera_id).await?;
        let snapshot_id = Uuid::new_v4();
        let now = Utc::now();

        // Simulate snapshot capture
        let image_url = format!("https://storage.empowerplant.com/snapshots/{}.jpg", snapshot_id);

        // Publish snapshot event
        let event = Event::CameraSnapshotTaken(CameraSnapshotTakenEvent {
            metadata: create_event_metadata("camera-management", None),
            camera_id,
            snapshot_id,
            image_url: image_url.clone(),
            taken_by: user_id,
        });

        let kafka_producer = KafkaProducer::new().await?;
        kafka_producer.publish_event(CAMERA_EVENTS_TOPIC, &event).await?;

        Ok(SnapshotResponse {
            id: snapshot_id,
            image_url,
            taken_at: now,
        })
    }

    pub async fn start_recording(
        &self,
        camera_id: Uuid,
        request: RecordingRequest,
    ) -> Result<RecordingResponse, AppError> {
        let _camera = self.get_camera(camera_id).await?;
        let recording_id = Uuid::new_v4();
        let now = Utc::now();

        // Publish recording started event
        let event = Event::CameraRecordingStarted(CameraRecordingStartedEvent {
            metadata: create_event_metadata("camera-management", None),
            camera_id,
            recording_id,
            duration_seconds: request.duration_seconds,
            started_by: request.user_id,
        });

        let kafka_producer = KafkaProducer::new().await?;
        kafka_producer.publish_event(CAMERA_EVENTS_TOPIC, &event).await?;

        Ok(RecordingResponse {
            id: recording_id,
            status: "recording".to_string(),
            estimated_duration: request.duration_seconds,
            started_at: now,
        })
    }

    pub async fn stop_recording(&self, camera_id: Uuid, recording_id: Uuid) -> Result<(), AppError> {
        let _camera = self.get_camera(camera_id).await?;
        // Simulate stopping recording
        Ok(())
    }

    pub async fn test_connection(&self, camera_id: Uuid) -> Result<ConnectionTestResult, AppError> {
        let camera = self.get_camera(camera_id).await?;
        let now = Utc::now();

        // Simulate connection test
        tokio::time::sleep(tokio::time::Duration::from_millis(500)).await;

        let success = camera.status == "active";
        let result = ConnectionTestResult {
            success,
            latency_ms: if success { Some(25) } else { None },
            signal_strength: if success { Some("Strong".to_string()) } else { None },
            error_message: if !success {
                Some("Camera is not in active state".to_string())
            } else {
                None
            },
            tested_at: now,
        };

        Ok(result)
    }
}
