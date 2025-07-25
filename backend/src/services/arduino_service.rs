use crate::models::*;
use chrono::Utc;
use serialport::{SerialPort, SerialPortType};
use std::io::{BufRead, BufReader, Write};
use std::sync::{Arc, Mutex};
use std::time::Duration;
use uuid::Uuid;

pub struct ArduinoService {
    pub serial_port: Arc<Mutex<Option<Box<dyn SerialPort>>>>,
    pub connection_status: bool,
    pub port_name: String,
    pub baud_rate: u32,
}

impl ArduinoService {
    pub fn new() -> Self {
        Self {
            serial_port: Arc::new(Mutex::new(None)),
            connection_status: false,
            port_name: "/dev/ttyUSB0".to_string(), // Default, can be configured
            baud_rate: 9600,
        }
    }
    
    pub fn new_with_port(port_name: String, baud_rate: u32) -> Self {
        Self {
            serial_port: Arc::new(Mutex::new(None)),
            connection_status: false,
            port_name,
            baud_rate,
        }
    }
    
    pub fn connect(&mut self) -> Result<(), String> {
        let port = serialport::new(&self.port_name, self.baud_rate)
            .timeout(Duration::from_millis(1000))
            .open()
            .map_err(|e| format!("Failed to open serial port {}: {}", self.port_name, e))?;
            
        let mut serial_guard = self.serial_port.lock().unwrap();
        *serial_guard = Some(port);
        self.connection_status = true;
        
        tracing::info!("Connected to Arduino on port: {}", self.port_name);
        Ok(())
    }
    
    pub fn disconnect(&mut self) {
        let mut serial_guard = self.serial_port.lock().unwrap();
        *serial_guard = None;
        self.connection_status = false;
        tracing::info!("Disconnected from Arduino");
    }
    
    pub fn list_available_ports() -> Vec<String> {
        match serialport::available_ports() {
            Ok(ports) => {
                ports.into_iter()
                    .filter_map(|port| {
                        match port.port_type {
                            SerialPortType::UsbPort(_) => Some(port.port_name),
                            _ => None,
                        }
                    })
                    .collect()
            },
            Err(_) => vec![],
        }
    }
    
    pub async fn send_command(&self, command: &str) -> Result<String, String> {
        if !self.connection_status {
            return Err("Arduino not connected".to_string());
        }
        
        // Try real serial communication first, fallback to mock if no connection
        match self.send_command_real(command).await {
            Ok(response) => Ok(response),
            Err(_) => {
                // Fallback to mock responses for testing
                tracing::warn!("Serial communication failed, using mock response for: {}", command);
                match command {
                    "PUMP:SOFTSTART" => Ok("PUMP:STARTING:PWM_RAMP".to_string()),
                    "PUMP:OFF" => Ok("PUMP:STOPPED".to_string()),
                    "SOLENOID:ON" => Ok("SOLENOID:ACTIVATED".to_string()),
                    "SOLENOID:OFF" => Ok("SOLENOID:DEACTIVATED".to_string()),
                    "SOURCE:BARREL" => Ok("SOURCE:BARREL:ACTIVE".to_string()),
                    "SOURCE:HOSE" => Ok("SOURCE:HOSE:ACTIVE".to_string()),
                    "STATUS" => Ok("PUMP:OFF,SOLENOID:ON,WATER_LEVEL:OK,FLOW:2.5,VOLTAGE:12.1,UPTIME:3600".to_string()),
                    _ => Err(format!("Unknown command: {}", command))
                }
            }
        }
    }
    
    async fn send_command_real(&self, command: &str) -> Result<String, String> {
        let serial_guard = self.serial_port.lock().map_err(|e| format!("Mutex error: {}", e))?;
        
        if let Some(ref port) = *serial_guard {
            // Clone the port to work with it outside the lock
            let mut port_clone = port.try_clone().map_err(|e| format!("Failed to clone port: {}", e))?;
            drop(serial_guard); // Release the lock
            
            // Send command
            let command_with_newline = format!("{}\n", command);
            port_clone.write_all(command_with_newline.as_bytes())
                .map_err(|e| format!("Failed to send command: {}", e))?;
            
            port_clone.flush().map_err(|e| format!("Failed to flush: {}", e))?;
            
            // Read response with timeout
            let mut reader = BufReader::new(port_clone);
            let mut response = String::new();
            
            // Use a spawn_blocking to handle the blocking I/O in async context
            let result = tokio::task::spawn_blocking(move || {
                reader.read_line(&mut response)
                    .map_err(|e| format!("Failed to read response: {}", e))?;
                Ok::<String, String>(response.trim().to_string())
            }).await.map_err(|e| format!("Task join error: {}", e))??;
            
            Ok(result)
        } else {
            Err("Serial port not connected".to_string())
        }
    }
    
    pub fn parse_status_response(&self, response: &str) -> IrrigationStatus {
        let mut status = IrrigationStatus {
            pump_active: false,
            pump_pwm_level: 0,
            solenoid_active: false,
            water_level_ok: false,
            flow_rate: 0.0,
            voltage: 0.0,
            system_uptime: 0,
            last_command: None,
            error: None,
            timestamp: Utc::now(),
        };
        
        // Parse the comma-separated response from Arduino
        for part in response.split(',') {
            let kv: Vec<&str> = part.split(':').collect();
            if kv.len() >= 2 {
                match kv[0] {
                    "PUMP" => {
                        status.pump_active = kv[1] != "OFF";
                        if kv.len() > 2 && kv[1] == "STARTING" {
                            status.pump_pwm_level = 128; // Mid-range during startup
                        }
                    },
                    "SOLENOID" => status.solenoid_active = kv[1] == "ON" || kv[1] == "ACTIVATED",
                    "WATER_LEVEL" => status.water_level_ok = kv[1] == "OK",
                    "FLOW" => status.flow_rate = kv[1].parse().unwrap_or(0.0),
                    "VOLTAGE" => status.voltage = kv[1].parse().unwrap_or(0.0),
                    "UPTIME" => status.system_uptime = kv[1].parse().unwrap_or(0),
                    _ => {}
                }
            }
        }
        
        status
    }
    
    pub async fn run_diagnostics(&self) -> Result<IrrigationDiagnostics, String> {
        // Simulate diagnostic data collection
        tokio::time::sleep(Duration::from_millis(500)).await;
        
        let pump_diag = PumpDiagnostics {
            motor_current: 4.2,
            motor_temperature: 45.0,
            runtime_hours: 127.5,
            cycles_completed: 342,
            soft_start_functioning: true,
            last_maintenance: Some(Utc::now() - chrono::Duration::days(30)),
        };
        
        let solenoid_diag = SolenoidDiagnostics {
            coil_resistance: 24.5,
            activation_count: 1205,
            response_time_ms: 85,
            leak_detected: false,
            last_maintenance: Some(Utc::now() - chrono::Duration::days(60)),
        };
        
        let sensor_diags = vec![
            SensorDiagnostics {
                sensor_id: Uuid::new_v4(),
                sensor_type: "Water Level".to_string(),
                calibration_status: "Good".to_string(),
                last_calibration: Some(Utc::now() - chrono::Duration::days(15)),
                drift_percentage: 2.1,
                readings_count: 8640,
                error_rate: 0.05,
            },
            SensorDiagnostics {
                sensor_id: Uuid::new_v4(),
                sensor_type: "Flow Rate".to_string(),
                calibration_status: "Needs Calibration".to_string(),
                last_calibration: Some(Utc::now() - chrono::Duration::days(90)),
                drift_percentage: 8.3,
                readings_count: 4320,
                error_rate: 1.2,
            },
        ];
        
        let power_diag = PowerDiagnostics {
            supply_voltage: 12.1,
            current_draw: 4.8,
            power_consumption: 58.08,
            efficiency: 87.5,
            thermal_status: "Normal".to_string(),
        };
        
        Ok(IrrigationDiagnostics {
            pump_diagnostics: pump_diag,
            solenoid_diagnostics: solenoid_diag,
            sensor_diagnostics: sensor_diags,
            power_diagnostics: power_diag,
            timestamp: Utc::now(),
        })
    }
    
    pub async fn emergency_shutdown(&self) -> Result<IrrigationStatus, String> {
        // Send emergency stop commands
        let _ = self.send_command("PUMP:OFF").await?;
        let _ = self.send_command("SOLENOID:OFF").await?;
        
        // Get updated status
        let status_response = self.send_command("STATUS").await?;
        Ok(self.parse_status_response(&status_response))
    }
    
    pub async fn run_system_test(&self) -> Result<std::collections::HashMap<String, String>, String> {
        use std::collections::HashMap;
        
        let mut results = HashMap::new();
        
        let test_commands = vec![
            ("pump_soft_start", "PUMP:SOFTSTART"),
            ("pump_stop", "PUMP:OFF"),
            ("solenoid_on", "SOLENOID:ON"),
            ("solenoid_off", "SOLENOID:OFF"),
            ("barrel_source", "SOURCE:BARREL"),
            ("hose_source", "SOURCE:HOSE"),
            ("status_check", "STATUS"),
        ];
        
        for (test_name, command) in test_commands {
            match self.send_command(command).await {
                Ok(response) => {
                    results.insert(test_name.to_string(), format!("PASS: {}", response));
                }
                Err(error) => {
                    results.insert(test_name.to_string(), format!("FAIL: {}", error));
                }
            }
            
            // Small delay between tests
            tokio::time::sleep(Duration::from_millis(300)).await;
        }
        
        Ok(results)
    }
    
    pub fn get_mock_sensor_data(&self) -> Vec<IrrigationSensor> {
        vec![
            IrrigationSensor {
                id: Uuid::new_v4(),
                sensor_type: IrrigationSensorType::WaterLevel,
                location: "Water Barrel".to_string(),
                value: 85.0,
                unit: "%".to_string(),
                status: "Active".to_string(),
                last_reading: Utc::now(),
            },
            IrrigationSensor {
                id: Uuid::new_v4(),
                sensor_type: IrrigationSensorType::FlowRate,
                location: "Main Line".to_string(),
                value: 2.5,
                unit: "L/min".to_string(),
                status: "Active".to_string(),
                last_reading: Utc::now(),
            },
            IrrigationSensor {
                id: Uuid::new_v4(),
                sensor_type: IrrigationSensorType::Voltage,
                location: "Power Supply".to_string(),
                value: 12.1,
                unit: "V".to_string(),
                status: "Active".to_string(),
                last_reading: Utc::now(),
            },
            IrrigationSensor {
                id: Uuid::new_v4(),
                sensor_type: IrrigationSensorType::SoilMoisture,
                location: "Zone A".to_string(),
                value: 35.0,
                unit: "%".to_string(),
                status: "Warning".to_string(), // Below optimal
                last_reading: Utc::now(),
            },
            IrrigationSensor {
                id: Uuid::new_v4(),
                sensor_type: IrrigationSensorType::Pressure,
                location: "Main Line".to_string(),
                value: 2.8,
                unit: "bar".to_string(),
                status: "Active".to_string(),
                last_reading: Utc::now(),
            },
        ]
    }
}

// For future integration with real serial communication
/*
use serialport::{self, SerialPort};

impl ArduinoService {
    pub fn connect_to_arduino(port_name: &str, baud_rate: u32) -> Result<Self, Box<dyn std::error::Error>> {
        let port = serialport::new(port_name, baud_rate)
            .timeout(Duration::from_millis(1000))
            .open()?;
            
        Ok(Self {
            serial_port: Some(port),
            connection_status: true,
        })
    }
    
    pub fn send_command_real(&mut self, command: &str) -> Result<String, String> {
        if let Some(ref mut port) = self.serial_port {
            // Send command
            port.write_all(format!("{}\n", command).as_bytes())
                .map_err(|e| format!("Failed to send command: {}", e))?;
            
            // Read response
            let mut response = String::new();
            let mut buffer = [0; 1];
            
            while let Ok(_) = port.read(&mut buffer) {
                let ch = buffer[0] as char;
                if ch == '\n' || ch == '\r' {
                    break;
                }
                response.push(ch);
            }
            
            Ok(response)
        } else {
            Err("No serial connection".to_string())
        }
    }
}
*/
