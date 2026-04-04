.PHONY: proto-go proto-dart build-go run-db run-backend

proto-go:
	protoc -I shared/proto --go_out=backend/internal/proto --go_opt=paths=source_relative \
    --go-grpc_out=backend/internal/proto --go-grpc_opt=paths=source_relative \
    shared/proto/api.proto

proto-dart:
	protoc -I shared/proto --dart_out=grpc:apps/mobile_app/lib/proto shared/proto/api.proto

run-db:
	docker-compose up -d

migrate:
	Get-Content infrastructure/docker/migrations/000001_init_schema.up.sql | docker exec -i gipjazes_db psql -U gipjazes -d gipjazes_main

run-backend:
	cd backend && go run cmd/api/main.go

build-mobile:
	cd apps/mobile_app && flutter pub get && flutter build apk
