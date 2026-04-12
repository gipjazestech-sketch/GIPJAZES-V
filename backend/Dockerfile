# Build stage
FROM golang:alpine AS builder

WORKDIR /app

# Copy the backend context
COPY backend/go.mod backend/go.sum ./backend/
WORKDIR /app/backend
RUN go mod download

WORKDIR /app
COPY backend ./backend

# Build the API binary
WORKDIR /app/backend
RUN go mod tidy
RUN go build -o main ./cmd/api/main.go

# Final stage
FROM alpine:latest
RUN apk --no-cache add ca-certificates

WORKDIR /root/

# Copy binary from builder
COPY --from=builder /app/backend/main .

# Expose the API and gRPC ports
EXPOSE 8080 9090

# Run the application
CMD ["./main"]
