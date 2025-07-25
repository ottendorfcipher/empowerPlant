use super::*;
use crate::models::*;

pub async fn get_user_profile(_pool: web::Data<MySqlPool>) -> ActixResult<HttpResponse> {
    let user = User {
        id: Uuid::new_v4(),
        email: "user@example.com".to_string(),
        name: "John Doe".to_string(),
        created_at: Utc::now(),
    };

    Ok(HttpResponse::Ok().json(ApiResponse::success(user, "User profile retrieved successfully")))
}

pub async fn update_user_profile(
    req: web::Json<UpdateUserRequest>,
    _pool: web::Data<MySqlPool>,
) -> ActixResult<HttpResponse> {
    let user = User {
        id: Uuid::new_v4(),
        email: req.email.clone().unwrap_or("user@example.com".to_string()),
        name: req.name.clone().unwrap_or("John Doe".to_string()),
        created_at: Utc::now(),
    };

    Ok(HttpResponse::Ok().json(ApiResponse::success(user, "User profile updated successfully")))
}
