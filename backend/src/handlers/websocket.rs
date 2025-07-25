use actix_web::{web, HttpRequest, HttpResponse, Result as ActixResult};
use actix_ws::{Message, Session};
use futures_util::StreamExt;
use serde_json;
use std::time::Duration;
use tokio::time::interval;
use tracing;

use crate::services::arduino_service::ArduinoService;

pub async fn irrigation_websocket(
    req: HttpRequest,
    stream: web::Payload,
) -> ActixResult<HttpResponse> {
    let (response, session, stream) = actix_ws::handle(&req, stream)?;
    
    // Spawn the WebSocket handler
    actix_web::rt::spawn(handle_irrigation_websocket(session, stream));
    
    Ok(response)
}

async fn handle_irrigation_websocket(
    mut session: Session,
    mut stream: actix_ws::MessageStream,
) {
    tracing::info!("New irrigation WebSocket connection established");
    
    // Create an interval for periodic status updates
    let mut status_interval = interval(Duration::from_secs(5));
    
    // Arduino service instance
    let arduino_service = ArduinoService::new();
    
    loop {
        tokio::select! {
            // Handle incoming WebSocket messages
            Some(msg) = stream.next() => {
                match msg {
                    Ok(Message::Text(text)) => {
                        if let Err(e) = handle_client_message(&mut session, &arduino_service, &text.to_string()).await {
                            tracing::error!("Error handling client message: {}", e);
                            break;
                        }
                    }
                    Ok(Message::Close(_)) => {
                        tracing::info!("WebSocket connection closed by client");
                        break;
                    }
                    Err(e) => {
                        tracing::error!("WebSocket error: {}", e);
                        break;
                    }
                    _ => {}
                }
            }
            
            // Send periodic status updates
            _ = status_interval.tick() => {
                if let Err(e) = send_status_update(&mut session, &arduino_service).await {
                    tracing::error!("Error sending status update: {}", e);
                    break;
                }
            }
        }
    }
    
    tracing::info!("Irrigation WebSocket connection terminated");
}

async fn handle_client_message(
    session: &mut Session,
    arduino_service: &ArduinoService,
    message: &str,
) -> Result<(), Box<dyn std::error::Error>> {
    let request: serde_json::Value = serde_json::from_str(message)?;
    
    match request.get("type").and_then(|v| v.as_str()) {
        Some("get_status") => {
            send_status_update(session, arduino_service).await?;
        }
        Some("execute_command") => {
            if let Some(command) = request.get("command").and_then(|v| v.as_str()) {
                handle_command_execution(session, arduino_service, command).await?;
            }
        }
        Some("get_diagnostics") => {
            send_diagnostics_update(session, arduino_service).await?;
        }
        Some("get_sensors") => {
            send_sensors_update(session, arduino_service).await?;
        }
        _ => {
            let error_response = serde_json::json!({
                "type": "error",
                "message": "Unknown message type"
            });
            session.text(error_response.to_string()).await?;
        }
    }
    
    Ok(())
}

async fn send_status_update(
    session: &mut Session,
    arduino_service: &ArduinoService,
) -> Result<(), Box<dyn std::error::Error>> {
    match arduino_service.send_command("STATUS").await {
        Ok(response) => {
            let status = arduino_service.parse_status_response(&response);
            let message = serde_json::json!({
                "type": "status_update",
                "data": status,
                "timestamp": chrono::Utc::now()
            });
            session.text(message.to_string()).await?;
        }
        Err(e) => {
            let error_message = serde_json::json!({
                "type": "error",
                "message": format!("Failed to get status: {}", e),
                "timestamp": chrono::Utc::now()
            });
            session.text(error_message.to_string()).await?;
        }
    }
    Ok(())
}

async fn handle_command_execution(
    session: &mut Session,
    arduino_service: &ArduinoService,
    command: &str,
) -> Result<(), Box<dyn std::error::Error>> {
    // Validate command
    let valid_commands = vec![
        "PUMP:SOFTSTART", "PUMP:OFF", 
        "SOLENOID:ON", "SOLENOID:OFF",
        "SOURCE:BARREL", "SOURCE:HOSE",
        "STATUS"
    ];
    
    if !valid_commands.contains(&command) {
        let error_response = serde_json::json!({
            "type": "error",
            "message": "Invalid command"
        });
        session.text(error_response.to_string()).await?;
        return Ok(());
    }
    
    match arduino_service.send_command(command).await {
        Ok(result) => {
            // Get updated status after command
            let status_response = arduino_service.send_command("STATUS").await.unwrap_or_default();
            let system_status = arduino_service.parse_status_response(&status_response);
            
            let response = serde_json::json!({
                "type": "command_result",
                "command": command,
                "result": result,
                "system_status": system_status,
                "timestamp": chrono::Utc::now()
            });
            session.text(response.to_string()).await?;
        }
        Err(e) => {
            let error_response = serde_json::json!({
                "type": "error",
                "message": format!("Command failed: {}", e),
                "timestamp": chrono::Utc::now()
            });
            session.text(error_response.to_string()).await?;
        }
    }
    
    Ok(())
}

async fn send_diagnostics_update(
    session: &mut Session,
    arduino_service: &ArduinoService,
) -> Result<(), Box<dyn std::error::Error>> {
    match arduino_service.run_diagnostics().await {
        Ok(diagnostics) => {
            let message = serde_json::json!({
                "type": "diagnostics_update",
                "data": diagnostics,
                "timestamp": chrono::Utc::now()
            });
            session.text(message.to_string()).await?;
        }
        Err(e) => {
            let error_message = serde_json::json!({
                "type": "error",
                "message": format!("Failed to get diagnostics: {}", e),
                "timestamp": chrono::Utc::now()
            });
            session.text(error_message.to_string()).await?;
        }
    }
    Ok(())
}

async fn send_sensors_update(
    session: &mut Session,
    arduino_service: &ArduinoService,
) -> Result<(), Box<dyn std::error::Error>> {
    let sensors = arduino_service.get_mock_sensor_data();
    let message = serde_json::json!({
        "type": "sensors_update",
        "data": sensors,
        "timestamp": chrono::Utc::now()
    });
    session.text(message.to_string()).await?;
    Ok(())
}
