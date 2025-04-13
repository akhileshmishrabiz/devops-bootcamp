# Multi-stage Dockerfile

# Stage 1 - Build
FROM golang:1.21 AS builder

WORKDIR /app
COPY . .
RUN go build -o myapp main.go

# Stage 2 - Run
FROM scratch

WORKDIR /app
COPY --from=builder /app/myapp .

EXPOSE 8080
CMD ["./myapp"]
