# Weather API Setup Instructions

This guide explains how to securely configure the OpenWeatherMap API key for the EmpowerPlant weather service.

## Security Features

✅ **API Key Protection**: The `.env` file is excluded from version control
✅ **Manual API Calls**: Weather API is only called when explicitly requested
✅ **Caching**: Data is cached to minimize API usage
✅ **Location-Specific**: Pre-configured for E Crescent Dr, Jackson Township, IN 47274

## Quick Setup

### 1. Get Your OpenWeatherMap API Key

1. Visit [OpenWeatherMap](https://openweathermap.org/api)
2. Sign up for a free account
3. Go to your API keys section
4. Copy your API key

### 2. Configure the Environment

```bash
# Copy the example environment file
cp .env.example .env

# Edit the .env file and add your API key
# Replace 'your_api_key_here' with your actual API key
OPENWEATHER_API_KEY=your_actual_api_key_here
```

### 3. Restart the Service

```bash
# Stop the current containers
docker-compose down

# Rebuild and start with the new API key
docker-compose up --build -d
```

## API Endpoints

### 🏠 Jackson Township Weather (Default Location)

**Get Cached Data (No API Call)**
```bash
GET http://localhost:8081/api/v1/weather/jackson-township
```

**Manual API Call (Requires Confirmation)**
```bash
POST http://localhost:8081/api/v1/weather/manual/jackson-township
```

### 🌍 Custom Location Weather

**Get Cached Data**
```bash
GET http://localhost:8081/api/v1/weather/current/{location}
```

**Manual API Call**
```bash
POST http://localhost:8081/api/v1/weather/manual/{location}
```

## Example Usage

### 1. Check Jackson Township Weather (Cached)
```bash
curl -X GET "http://localhost:8081/api/v1/weather/jackson-township"
```

**Response when no cached data:**
```json
{
  "success": false,
  "cached": false,
  "message": "No cached data available. Use the manual API call endpoint to fetch fresh data.",
  "manual_endpoint": "/api/v1/weather/manual/jackson-township",
  "timestamp": "2025-07-22T14:30:00Z"
}
```

### 2. Make Manual API Call for Fresh Data
```bash
curl -X POST "http://localhost:8081/api/v1/weather/manual/jackson-township"
```

**Response with fresh data:**
```json
{
  "success": true,
  "data": {
    "id": "12345",
    "location": "E Crescent Dr, Jackson Township, IN 47274",
    "temperature": 22.5,
    "humidity": 65.2,
    "wind_speed": 8.5,
    "weather_condition": "Clear",
    "timestamp": "2025-07-22T14:30:00Z"
  },
  "api_call_made": true,
  "message": "Fresh weather data retrieved from OpenWeatherMap API",
  "timestamp": "2025-07-22T14:30:00Z"
}
```

### 3. Subsequent Calls Return Cached Data
```bash
curl -X GET "http://localhost:8081/api/v1/weather/jackson-township"
```

**Response with cached data:**
```json
{
  "success": true,
  "data": { /* same weather data */ },
  "cached": true,
  "message": "Returning cached data. Use /manual endpoint to fetch fresh data.",
  "timestamp": "2025-07-22T14:31:00Z"
}
```

## Security Notes

- 🔒 **Never commit your `.env` file** - It's automatically excluded by `.gitignore`
- 🔑 **API Key Validation** - The service checks if a valid API key is configured
- ⏰ **Cache Duration** - Weather data is cached for 30 minutes to reduce API calls
- 📝 **Manual Confirmation** - API calls only happen when you explicitly use the `/manual` endpoints

## Troubleshooting

### "OpenWeatherMap API key not configured"
- Check that `OPENWEATHER_API_KEY` is set in your `.env` file
- Ensure the API key is not empty or placeholder text
- Restart the containers after updating the `.env` file

### "Weather API returned error: 401 Unauthorized"
- Your API key may be invalid or expired
- Check your OpenWeatherMap account status
- Verify the API key is copied correctly

### No response from API
- Ensure containers are running: `docker-compose ps`
- Check service logs: `docker logs empowerplant-weather-data`
- Verify network connectivity

## Environment Variables

| Variable | Description | Default | Required |
|----------|-------------|---------|----------|
| `OPENWEATHER_API_KEY` | Your OpenWeatherMap API key | - | Yes |
| `DATABASE_URL` | MySQL connection string | Auto-configured | No |
| `HOST` | Service bind address | 0.0.0.0 | No |
| `PORT` | Service port | 8081 | No |

## File Structure

```
backend/
├── .env                 # Your environment variables (excluded from git)
├── .env.example         # Template for environment variables
├── .gitignore          # Excludes .env from version control
├── docker-compose.yml  # Service configuration
└── microservices/
    └── weather-data/   # Weather service implementation
```

---

**Ready to test?** Start with the Jackson Township endpoint to see your local weather data!
