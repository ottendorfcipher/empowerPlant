use super::*;
use crate::models::*;

pub async fn get_sensors(__pool: web::Data<MySqlPool>) -> ActixResult<HttpResponse> {
    let sensors = vec![
        Sensor {
            id: Uuid::new_v4(),
            name: "Temperature Sensor".to_string(),
            sensor_type: "temperature".to_string(),
            location: "Garden Bed 1".to_string(),
            status: "active".to_string(),
        }
    ];

    Ok(HttpResponse::Ok().json(ApiResponse::success(sensors, "Sensors retrieved successfully")))
}

pub async fn create_sensor(
    req: web::Json<CreateSensorRequest>,
    __pool: web::Data<MySqlPool>,
) -> ActixResult<HttpResponse> {
    let sensor = Sensor {
        id: Uuid::new_v4(),
        name: req.name.clone(),
        sensor_type: req.sensor_type.clone(),
        location: req.location.clone(),
        status: "active".to_string(),
    };

    Ok(HttpResponse::Created().json(ApiResponse::success(sensor, "Sensor created successfully")))
}

pub async fn get_sensor_readings(
    path: web::Path<Uuid>,
    __pool: web::Data<MySqlPool>,
) -> ActixResult<HttpResponse> {
    let sensor_id = path.into_inner();
    
    let readings = vec![
        SensorReading {
            id: Uuid::new_v4(),
            sensor_id,
            value: 22.5,
            unit: "°C".to_string(),
            timestamp: Utc::now(),
        }
    ];

    Ok(HttpResponse::Ok().json(ApiResponse::success(readings, "Sensor readings retrieved successfully")))
}

pub async fn add_sensor_reading(
    path: web::Path<Uuid>,
    req: web::Json<SensorReadingRequest>,
    __pool: web::Data<MySqlPool>,
) -> ActixResult<HttpResponse> {
    let sensor_id = path.into_inner();
    
    let reading = SensorReading {
        id: Uuid::new_v4(),
        sensor_id,
        value: req.value,
        unit: req.unit.clone(),
        timestamp: Utc::now(),
    };

    Ok(HttpResponse::Created().json(ApiResponse::success(reading, "Sensor reading added successfully")))
}
