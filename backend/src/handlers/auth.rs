use super::*;
use crate::models::*;

pub async fn auth_login(
    req: web::Json<LoginRequest>,
    __pool: web::Data<MySqlPool>,
) -> ActixResult<HttpResponse> {
    // Mock authentication - replace with actual auth logic
    let token = "mock_jwt_token_here";
    let response = LoginResponse {
        token: token.to_string(),
        user_id: Uuid::new_v4(),
        email: req.email.clone(),
    };

    Ok(HttpResponse::Ok().json(ApiResponse::success(response, "Login successful")))
}

pub async fn auth_register(
    req: web::Json<RegisterRequest>,
    __pool: web::Data<MySqlPool>,
) -> ActixResult<HttpResponse> {
    let user = User {
        id: Uuid::new_v4(),
        email: req.email.clone(),
        name: req.name.clone(),
        created_at: Utc::now(),
    };

    Ok(HttpResponse::Created().json(ApiResponse::success(user, "User registered successfully")))
}
