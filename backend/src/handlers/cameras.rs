use super::*;
use crate::models::*;

pub async fn get_cameras(pool: web::Data<MySqlPool>) -> ActixResult<HttpResponse> {
    let cameras = vec![
        Camera {
            id: Uuid::new_v4(),
            name: "Garden Overview".to_string(),
            location: "North Garden".to_string(),
            status: "active".to_string(),
            stream_url: Some("rtmp://camera-stream.empowerplant.com/garden1".to_string()),
        }
    ];

    Ok(HttpResponse::Ok().json(ApiResponse::success(cameras, "Cameras retrieved successfully")))
}

pub async fn setup_camera(
    req: web::Json<CameraSetupRequest>,
    pool: web::Data<MySqlPool>,
) -> ActixResult<HttpResponse> {
    let camera = Camera {
        id: Uuid::new_v4(),
        name: req.camera_name.clone(),
        location: req.location.clone(),
        status: "connected".to_string(),
        stream_url: Some(format!("rtmp://camera-stream.empowerplant.com/{}", Uuid::new_v4())),
    };

    Ok(HttpResponse::Created().json(ApiResponse::success(camera, "Camera setup completed successfully")))
}

pub async fn get_camera_stream(
    path: web::Path<Uuid>,
    pool: web::Data<MySqlPool>,
) -> ActixResult<HttpResponse> {
    let camera_id = path.into_inner();
    
    let stream_info = CameraStream {
        camera_id,
        stream_url: format!("rtmp://camera-stream.empowerplant.com/{}", camera_id),
        status: "streaming".to_string(),
        resolution: "1080p".to_string(),
        fps: 30,
    };

    Ok(HttpResponse::Ok().json(ApiResponse::success(stream_info, "Live stream available")))
}
