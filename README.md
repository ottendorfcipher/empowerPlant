# EmpowerPlant

Modern plant monitoring system with iOS app and Rust backend.

## Features

- **Plant Management** - Add, identify, and track plants
- **Sensor Monitoring** - Real-time environmental data
- **Live Camera** - Stream garden footage
- **Weather Integration** - Local weather conditions
- **User Authentication** - Secure access control

## Quick Start

### Backend
```bash
cd backend
cp ../.env.example .env
# Edit .env with your configuration
cargo run
```

### iOS App
Open `ios/empowerPlant.xcodeproj` in Xcode and run.

### Docker
```bash
docker-compose up
```

## API Endpoints

- `POST /api/v1/auth/login` - User authentication
- `GET /api/v1/plants` - List plants
- `POST /api/v1/plants/identify` - Identify plant from image
- `GET /api/v1/sensors` - Sensor data
- `GET /api/v1/cameras` - Camera streams
- `GET /api/v1/weather/current` - Current weather

## Architecture

- **Backend**: Rust + Actix-web + MySQL
- **Frontend**: Swift + SwiftUI
- **Deployment**: Docker + Docker Compose

## License

MIT
