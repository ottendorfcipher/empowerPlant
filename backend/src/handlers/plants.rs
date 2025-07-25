use super::*;
use crate::models::*;

pub async fn get_plants(pool: web::Data<MySqlPool>) -> ActixResult<HttpResponse> {
    // Mock data for now - replace with actual database queries
    let plants = vec![
        Plant {
            id: Uuid::new_v4(),
            name: "Tomato Plant".to_string(),
            plant_type: "Tomato".to_string(),
            location: Some("Garden Bed 1".to_string()),
            created_at: Utc::now(),
        }
    ];

    Ok(HttpResponse::Ok().json(ApiResponse::success(plants, "Plants retrieved successfully")))
}

pub async fn create_plant(
    req: web::Json<CreatePlantRequest>,
    pool: web::Data<MySqlPool>,
) -> ActixResult<HttpResponse> {
    let plant = Plant {
        id: Uuid::new_v4(),
        name: req.name.clone(),
        plant_type: req.plant_type.clone(),
        location: req.location.clone(),
        created_at: Utc::now(),
    };

    Ok(HttpResponse::Created().json(ApiResponse::success(plant, "Plant created successfully")))
}

pub async fn identify_plant(
    mut payload: Multipart,
    pool: web::Data<MySqlPool>,
) -> ActixResult<HttpResponse> {
    // Mock plant identification - in production this would use ML models
    let identification = PlantIdentification {
        plant_type: "Tomato".to_string(),
        scientific_name: "Solanum lycopersicum".to_string(),
        confidence: 0.92,
        care_instructions: CareInstructions {
            water_frequency: "Every 2-3 days".to_string(),
            light_requirements: "Full sun (6-8 hours)".to_string(),
            soil_type: "Well-draining, slightly acidic".to_string(),
            optimal_temperature: "65-75°F (18-24°C)".to_string(),
        },
    };

    Ok(HttpResponse::Ok().json(ApiResponse::success(identification, "Plant identified successfully")))
}

pub async fn get_plant(
    path: web::Path<Uuid>,
    pool: web::Data<MySqlPool>,
) -> ActixResult<HttpResponse> {
    let plant_id = path.into_inner();
    
    let plant = Plant {
        id: plant_id,
        name: "Tomato Plant".to_string(),
        plant_type: "Tomato".to_string(),
        location: Some("Garden Bed 1".to_string()),
        created_at: Utc::now(),
    };

    Ok(HttpResponse::Ok().json(ApiResponse::success(plant, "Plant retrieved successfully")))
}

pub async fn update_plant(
    path: web::Path<Uuid>,
    req: web::Json<UpdatePlantRequest>,
    pool: web::Data<MySqlPool>,
) -> ActixResult<HttpResponse> {
    let plant_id = path.into_inner();
    
    let plant = Plant {
        id: plant_id,
        name: req.name.clone().unwrap_or("Updated Plant".to_string()),
        plant_type: req.plant_type.clone().unwrap_or("Unknown".to_string()),
        location: req.location.clone(),
        created_at: Utc::now(),
    };

    Ok(HttpResponse::Ok().json(ApiResponse::success(plant, "Plant updated successfully")))
}

pub async fn delete_plant(
    path: web::Path<Uuid>,
    pool: web::Data<MySqlPool>,
) -> ActixResult<HttpResponse> {
    let _plant_id = path.into_inner();
    Ok(HttpResponse::Ok().json(ApiResponse::<()>::error("Plant deleted successfully")))
}
