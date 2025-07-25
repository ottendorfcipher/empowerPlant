use chrono::{DateTime, Utc};
use serde_json::Value;
use uuid::Uuid;

pub fn generate_id() -> Uuid {
    Uuid::new_v4()
}

pub fn current_timestamp() -> DateTime<Utc> {
    Utc::now()
}

pub fn validate_email(email: &str) -> bool {
    email.contains('@') && email.contains('.')
}

pub fn sanitize_string(input: &str) -> String {
    input
        .trim()
        .chars()
        .filter(|c| c.is_alphanumeric() || c.is_whitespace() || "-_@.".contains(*c))
        .collect()
}

pub fn calculate_percentage(part: f64, total: f64) -> f64 {
    if total == 0.0 {
        0.0
    } else {
        (part / total) * 100.0
    }
}

pub fn round_to_precision(value: f64, precision: usize) -> f64 {
    let multiplier = 10_f64.powi(precision as i32);
    (value * multiplier).round() / multiplier
}

pub fn merge_json_objects(base: &Value, overlay: &Value) -> Value {
    match (base, overlay) {
        (Value::Object(base_map), Value::Object(overlay_map)) => {
            let mut result = base_map.clone();
            for (key, value) in overlay_map {
                result.insert(key.clone(), value.clone());
            }
            Value::Object(result)
        }
        _ => overlay.clone(),
    }
}

pub fn format_duration_minutes(minutes: i32) -> String {
    if minutes < 60 {
        format!("{}m", minutes)
    } else {
        let hours = minutes / 60;
        let remaining_minutes = minutes % 60;
        if remaining_minutes == 0 {
            format!("{}h", hours)
        } else {
            format!("{}h {}m", hours, remaining_minutes)
        }
    }
}

pub fn calculate_water_usage_efficiency(
    water_used: f64,
    area_covered: f64,
    duration_hours: f64,
) -> f64 {
    if area_covered == 0.0 || duration_hours == 0.0 {
        0.0
    } else {
        water_used / (area_covered * duration_hours)
    }
}

pub fn calculate_growth_rate(
    current_measurement: f64,
    previous_measurement: f64,
    days_elapsed: i32,
) -> f64 {
    if days_elapsed == 0 || previous_measurement == 0.0 {
        0.0
    } else {
        ((current_measurement - previous_measurement) / previous_measurement) * 100.0 / days_elapsed as f64
    }
}

pub fn is_within_threshold(value: f64, target: f64, threshold_percent: f64) -> bool {
    let threshold = target * (threshold_percent / 100.0);
    (value - target).abs() <= threshold
}

pub fn calculate_average(values: &[f64]) -> f64 {
    if values.is_empty() {
        0.0
    } else {
        values.iter().sum::<f64>() / values.len() as f64
    }
}

pub fn calculate_moving_average(values: &[f64], window_size: usize) -> Vec<f64> {
    let mut averages = Vec::new();
    
    if window_size == 0 || values.is_empty() {
        return averages;
    }
    
    for i in 0..values.len() {
        let start = if i + 1 >= window_size { i + 1 - window_size } else { 0 };
        let end = i + 1;
        let window = &values[start..end];
        averages.push(calculate_average(window));
    }
    
    averages
}

pub fn detect_anomaly(current_value: f64, historical_values: &[f64], std_dev_threshold: f64) -> bool {
    if historical_values.len() < 3 {
        return false;
    }
    
    let mean = calculate_average(historical_values);
    let variance = historical_values
        .iter()
        .map(|x| (x - mean).powi(2))
        .sum::<f64>() / historical_values.len() as f64;
    let std_dev = variance.sqrt();
    
    (current_value - mean).abs() > (std_dev * std_dev_threshold)
}

pub fn interpolate_missing_values(values: &[Option<f64>]) -> Vec<f64> {
    let mut result = Vec::new();
    let mut last_valid_index = None;
    
    // Forward pass - carry forward last valid value
    for (i, value) in values.iter().enumerate() {
        match value {
            Some(v) => {
                result.push(*v);
                last_valid_index = Some(i);
            }
            None => {
                if let Some(last_idx) = last_valid_index {
                    result.push(result[last_idx]);
                } else {
                    result.push(0.0); // Default value if no valid value found yet
                }
            }
        }
    }
    
    result
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_calculate_percentage() {
        assert_eq!(calculate_percentage(25.0, 100.0), 25.0);
        assert_eq!(calculate_percentage(0.0, 100.0), 0.0);
        assert_eq!(calculate_percentage(25.0, 0.0), 0.0);
    }

    #[test]
    fn test_round_to_precision() {
        assert_eq!(round_to_precision(3.14159, 2), 3.14);
        assert_eq!(round_to_precision(3.14159, 0), 3.0);
        assert_eq!(round_to_precision(3.14159, 4), 3.1416);
    }

    #[test]
    fn test_format_duration_minutes() {
        assert_eq!(format_duration_minutes(30), "30m");
        assert_eq!(format_duration_minutes(60), "1h");
        assert_eq!(format_duration_minutes(90), "1h 30m");
        assert_eq!(format_duration_minutes(120), "2h");
    }

    #[test]
    fn test_calculate_average() {
        assert_eq!(calculate_average(&[1.0, 2.0, 3.0, 4.0, 5.0]), 3.0);
        assert_eq!(calculate_average(&[]), 0.0);
        assert_eq!(calculate_average(&[5.0]), 5.0);
    }

    #[test]
    fn test_is_within_threshold() {
        assert!(is_within_threshold(95.0, 100.0, 10.0));
        assert!(!is_within_threshold(85.0, 100.0, 10.0));
        assert!(is_within_threshold(105.0, 100.0, 10.0));
    }
}
