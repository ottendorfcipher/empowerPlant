use crate::repository::UserRepository;
use empower_plant_shared::{
    AppError, AppResult, CreateUserRequest, JwtService, KafkaClient, LoginRequest, LoginResponse,
    User, UserRegisteredEvent, UserLoggedInEvent, UserResponse, USER_EVENTS_TOPIC,
    create_event_metadata, hash_password, verify_password, validate_email
};
use uuid::Uuid;
use tracing::{info, instrument};

pub struct UserService {
    repository: UserRepository,
    kafka_client: KafkaClient,
    jwt_service: JwtService,
}

impl UserService {
    pub fn new(
        repository: UserRepository,
        kafka_client: KafkaClient,
        jwt_service: JwtService,
    ) -> Self {
        Self {
            repository,
            kafka_client,
            jwt_service,
        }
    }

    #[instrument(skip(self, request))]
    pub async fn register_user(&self, request: CreateUserRequest) -> AppResult<UserResponse> {
        info!("Registering new user: {}", request.email);

        // Validate email format
        if !validate_email(&request.email) {
            return Err(AppError::Validation("Invalid email format".to_string()));
        }

        // Check if user already exists
        if self.repository.find_by_email(&request.email).await?.is_some() {
            return Err(AppError::Conflict("User with this email already exists".to_string()));
        }

        // Hash password
        let password_hash = hash_password(&request.password)?;

        // Create user
        let user = self.repository.create(
            request.email.clone(),
            password_hash,
            request.first_name.clone(),
            request.last_name.clone(),
            request.roles.clone(),
        ).await?;

        // Publish user registered event
        let event = UserRegisteredEvent {
            metadata: create_event_metadata("user-management-service", None),
            user_id: user.id,
            email: user.email.clone(),
            first_name: user.first_name.clone(),
            last_name: user.last_name.clone(),
            roles: user.roles.clone(),
        };

        self.kafka_client
            .publish(USER_EVENTS_TOPIC, Some(&user.id.to_string()), &event)
            .await?;

        info!("User registered successfully: {}", user.id);
        Ok(user.into())
    }

    #[instrument(skip(self, request))]
    pub async fn login(&self, request: LoginRequest) -> AppResult<LoginResponse> {
        info!("User login attempt: {}", request.email);

        // Find user by email
        let user = self
            .repository
            .find_by_email(&request.email)
            .await?
            .ok_or_else(|| AppError::Authentication("Invalid credentials".to_string()))?;

        // Verify password
        if !verify_password(&request.password, &user.password_hash)? {
            return Err(AppError::Authentication("Invalid credentials".to_string()));
        }

        // Check if user is active
        if !user.is_active {
            return Err(AppError::Authentication("Account is deactivated".to_string()));
        }

        // Generate tokens
        let access_token = self.jwt_service.generate_token(&user.id, &user.email, user.roles.clone())?;
        let refresh_token = self.jwt_service.generate_refresh_token(&user.id, &user.email, user.roles.clone())?;

        // Publish user logged in event
        let event = UserLoggedInEvent {
            metadata: create_event_metadata("user-management-service", None),
            user_id: user.id,
            email: user.email.clone(),
            login_timestamp: chrono::Utc::now(),
            ip_address: None, // Could be extracted from request headers
            user_agent: None, // Could be extracted from request headers
        };

        self.kafka_client
            .publish(USER_EVENTS_TOPIC, Some(&user.id.to_string()), &event)
            .await?;

        info!("User logged in successfully: {}", user.id);

        Ok(LoginResponse {
            access_token,
            refresh_token,
            user: user.into(),
        })
    }

    #[instrument(skip(self))]
    pub async fn get_user_by_id(&self, user_id: &Uuid) -> AppResult<Option<UserResponse>> {
        let user = self.repository.find_by_id(user_id).await?;
        Ok(user.map(|u| u.into()))
    }

    #[instrument(skip(self))]
    pub async fn get_users(&self, page: i32, per_page: i32) -> AppResult<Vec<UserResponse>> {
        let users = self.repository.find_all(page, per_page).await?;
        Ok(users.into_iter().map(|u| u.into()).collect())
    }

    #[instrument(skip(self))]
    pub async fn update_user(&self, user_id: &Uuid, updates: serde_json::Value) -> AppResult<UserResponse> {
        let user = self.repository.update(user_id, updates).await?;
        Ok(user.into())
    }

    #[instrument(skip(self))]
    pub async fn deactivate_user(&self, user_id: &Uuid) -> AppResult<()> {
        self.repository.deactivate(user_id).await?;
        info!("User deactivated: {}", user_id);
        Ok(())
    }
}
