# Build stage
FROM golang:1.25-alpine AS builder

WORKDIR /app

# Copy the entire monorepo context to handle shared dependencies if needed
COPY go.mod go.sum ./
RUN go mod download

COPY . .

# Build the API binary
RUN go build -o main ./cmd/api/main.go

# Final stage
FROM alpine:latest
RUN apk --no-cache add ca-certificates

WORKDIR /root/

# Copy binary from builder
COPY --from=builder /app/main .

# Expose the API and gRPC ports
EXPOSE 8080 9090

# Run the application
CMD ["./main"]
