# Multi-stage build for weather-data microservice
FROM rust:latest as builder

# Install system dependencies
RUN apt-get update && apt-get install -y \
    pkg-config \
    libssl-dev \
    libpq-dev \
    default-libmysqlclient-dev \
    cmake \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy the workspace files
COPY Cargo.toml Cargo.lock ./
COPY shared/ ./shared/
COPY microservices/weather-data/ ./microservices/weather-data/
COPY microservices/plant-monitoring/ ./microservices/plant-monitoring/

# Build the application
ENV SQLX_OFFLINE=true
RUN cargo build --release --bin weather-data

# Runtime stage
FROM debian:bookworm-slim

# Install runtime dependencies
RUN apt-get update && apt-get install -y \
    ca-certificates \
    libssl3 \
    libpq5 \
    default-mysql-client \
    && rm -rf /var/lib/apt/lists/*

# Create app user
RUN groupadd -r appuser && useradd -r -g appuser appuser

WORKDIR /app

# Copy the binary
COPY --from=builder /app/target/release/weather-data /app/weather-data

# Change ownership
RUN chown -R appuser:appuser /app
USER appuser

# Expose port
EXPOSE 8081

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8081/health || exit 1

# Run the application
CMD ["./weather-data"]
