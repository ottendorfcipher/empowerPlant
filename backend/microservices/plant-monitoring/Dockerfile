# Multi-stage build for plant-monitoring microservice
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
COPY microservices/plant-monitoring/ ./microservices/plant-monitoring/
COPY microservices/weather-data/ ./microservices/weather-data/

# Build the application
ENV SQLX_OFFLINE=true
RUN cargo build --release --bin plant-monitoring

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
COPY --from=builder /app/target/release/plant-monitoring /app/plant-monitoring

# Change ownership
RUN chown -R appuser:appuser /app
USER appuser

# Expose port
EXPOSE 8082

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8082/health || exit 1

# Run the application
CMD ["./plant-monitoring"]
