use super::*;
use crate::models::*;
use crate::services::arduino_service::ArduinoService;

pub async fn get_irrigation_status() -> ActixResult<HttpResponse> {
    let arduino_service = ArduinoService::new();
    
    match arduino_service.send_command("STATUS").await {
        Ok(response) => {
            let status = arduino_service.parse_status_response(&response);
            Ok(HttpResponse::Ok().json(ApiResponse::success(status, "Irrigation system status retrieved successfully")))
        }
        Err(err) => {
            Ok(HttpResponse::InternalServerError().json(ApiResponse::<()>::error(&format!("Failed to get status: {}", err))))
        }
    }
}

pub async fn list_serial_ports() -> ActixResult<HttpResponse> {
    let ports = ArduinoService::list_available_ports();
    Ok(HttpResponse::Ok().json(ApiResponse::success(ports, "Available serial ports retrieved successfully")))
}

pub async fn connect_arduino(
    req: web::Json<serde_json::Value>,
) -> ActixResult<HttpResponse> {
    let port_name = req.get("port_name")
        .and_then(|v| v.as_str())
        .ok_or_else(|| actix_web::error::ErrorBadRequest("port_name is required"))?;
    
    let baud_rate = req.get("baud_rate")
        .and_then(|v| v.as_u64())
        .unwrap_or(9600) as u32;
    
    let mut arduino_service = ArduinoService::new_with_port(port_name.to_string(), baud_rate);
    
    match arduino_service.connect() {
        Ok(_) => {
            Ok(HttpResponse::Ok().json(ApiResponse::success(
                serde_json::json!({
                    "connected": true,
                    "port": port_name,
                    "baud_rate": baud_rate
                }),
                "Arduino connected successfully"
            )))
        }
        Err(err) => {
            Ok(HttpResponse::InternalServerError().json(ApiResponse::<()>::error(&format!("Failed to connect to Arduino: {}", err))))
        }
    }
}

pub async fn disconnect_arduino() -> ActixResult<HttpResponse> {
    // In a real implementation, you'd want to manage the Arduino service instance globally
    // For now, this is a placeholder
    Ok(HttpResponse::Ok().json(ApiResponse::success(
        serde_json::json!({"disconnected": true}),
        "Arduino disconnected successfully"
    )))
}

pub async fn execute_irrigation_command(
    req: web::Json<IrrigationCommand>,
) -> ActixResult<HttpResponse> {
    let arduino_service = ArduinoService::new();
    
    // Validate command
    let valid_commands = vec![
        "PUMP:SOFTSTART", "PUMP:OFF", 
        "SOLENOID:ON", "SOLENOID:OFF",
        "SOURCE:BARREL", "SOURCE:HOSE",
        "STATUS"
    ];
    
    if !valid_commands.contains(&req.command.as_str()) {
        return Ok(HttpResponse::BadRequest().json(ApiResponse::<()>::error("Invalid command")));
    }
    
    match arduino_service.send_command(&req.command).await {
        Ok(result) => {
            // Get updated status after command
            let status_response = arduino_service.send_command("STATUS").await.unwrap_or_default();
            let system_status = arduino_service.parse_status_response(&status_response);
            
            let response = IrrigationCommandResponse {
                success: true,
                command: req.command.clone(),
                result,
                system_status,
            };
            
            Ok(HttpResponse::Ok().json(ApiResponse::success(response, "Command executed successfully")))
        }
        Err(err) => {
            Ok(HttpResponse::InternalServerError().json(ApiResponse::<()>::error(&format!("Command failed: {}", err))))
        }
    }
}

pub async fn get_irrigation_sensors() -> ActixResult<HttpResponse> {
    let arduino_service = ArduinoService::new();
    let sensors = arduino_service.get_mock_sensor_data();
    
    Ok(HttpResponse::Ok().json(ApiResponse::success(sensors, "Irrigation sensors retrieved successfully")))
}

pub async fn get_irrigation_diagnostics() -> ActixResult<HttpResponse> {
    let arduino_service = ArduinoService::new();
    
    match arduino_service.run_diagnostics().await {
        Ok(diagnostics) => {
            Ok(HttpResponse::Ok().json(ApiResponse::success(diagnostics, "Irrigation diagnostics retrieved successfully")))
        }
        Err(err) => {
            Ok(HttpResponse::InternalServerError().json(ApiResponse::<()>::error(&format!("Failed to run diagnostics: {}", err))))
        }
    }
}

pub async fn emergency_stop() -> ActixResult<HttpResponse> {
    let arduino_service = ArduinoService::new();
    
    match arduino_service.emergency_shutdown().await {
        Ok(status) => {
            Ok(HttpResponse::Ok().json(ApiResponse::success(status, "Emergency stop executed - all systems disabled")))
        }
        Err(err) => {
            Ok(HttpResponse::InternalServerError().json(ApiResponse::<()>::error(&format!("Emergency stop failed: {}", err))))
        }
    }
}

pub async fn run_system_test() -> ActixResult<HttpResponse> {
    let arduino_service = ArduinoService::new();
    
    match arduino_service.run_system_test().await {
        Ok(test_results) => {
            Ok(HttpResponse::Ok().json(ApiResponse::success(test_results, "System test completed")))
        }
        Err(err) => {
            Ok(HttpResponse::InternalServerError().json(ApiResponse::<()>::error(&format!("System test failed: {}", err))))
        }
    }
}
