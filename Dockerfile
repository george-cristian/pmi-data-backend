# Development Dockerfile with hot reload
FROM rust:1.84-slim

# Install system dependencies
RUN apt-get update && apt-get install -y \
    pkg-config \
    libssl-dev \
    postgresql-client \
    && rm -rf /var/lib/apt/lists/*

# Install cargo-watch for hot reload
RUN cargo install cargo-watch

# Set working directory
WORKDIR /app

# Copy dependency files first (for better Docker layer caching)
COPY Cargo.toml ./

# Create a dummy main.rs to build dependencies
RUN mkdir -p src && echo "fn main() {}" > src/main.rs

# Build dependencies (this layer will be cached unless Cargo.toml changes)
RUN cargo build --release && rm -rf src

# Expose port
EXPOSE 3000

# Default command for development (with hot reload)
CMD ["cargo", "watch", "-x", "run"]
