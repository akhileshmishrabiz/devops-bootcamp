# Still single-stage, but fixed
FROM golang:1.21-bullseye

# Install curl, gnupg, and Node.js
RUN apt-get update && apt-get install -y curl gnupg ca-certificates && \
    curl -fsSL https://deb.nodesource.com/setup_18.x | bash - && \
    apt-get install -y nodejs && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy everything
COPY . .

# Build frontend (assumes /app/frontend has package.json)
WORKDIR /app/frontend
RUN npm install && npm run build

# Build backend
WORKDIR /app
RUN go build -o server main.go

EXPOSE 8080
CMD ["./server"]
