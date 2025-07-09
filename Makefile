PROTO_DIR=proto
GO_OUT_DIR=gen/go
PY_OUT_DIR=client/gen
PROTO_FILE=$(PROTO_DIR)/fifo/v1/fifo.proto

.PHONY: all
all: go python

.PHONY: go
go:
	@echo "Generating Go code..."
	mkdir -p $(GO_OUT_DIR)
	protoc \
		--proto_path=$(PROTO_DIR) \
		--go_out=$(GO_OUT_DIR) \
		--go_opt=paths=source_relative \
		$(PROTO_FILE)

.PHONY: python
python:
	@echo "Generating Python code..."
	mkdir -p $(PY_OUT_DIR)
	protoc \
		--proto_path=$(PROTO_DIR) \
		--python_out=$(PY_OUT_DIR) \
		$(PROTO_FILE)
	@echo "Creating __init__.py files..."
	touch $(PY_OUT_DIR)/__init__.py
	touch $(PY_OUT_DIR)/fifo/__init__.py
	touch $(PY_OUT_DIR)/fifo/v1/__init__.py

.PHONY: clean
clean:
	@echo "Cleaning generated files..."
	rm -rf $(GO_OUT_DIR)
	rm -rf $(PY_OUT_DIR)
	rm -rf bin/
	rm -rf venv/

.PHONY: build
build:
	@echo "Building Go server..."
	go build -o bin/server cmd/server/main.go

.PHONY: run-server
run-server: build
	@echo "Running Go server..."
	./bin/server

.PHONY: run-client
run-client:
	@echo "Running Python client..."
	python3 client/client.py

.PHONY: install-tools
install-tools:
	@echo "Installing Go formatting tools..."
	go install mvdan.cc/gofumpt@latest

.PHONY: format
format: install-tools
	@echo "Formatting Go code with gofumpt..."
	gofumpt -w .

.PHONY: fmt
fmt: format

.PHONY: docker-build
docker-build:
	@echo "Building Docker images..."
	docker-compose build

.PHONY: docker-up
docker-up:
	@echo "Starting services with Docker Compose..."
	docker-compose up -d

.PHONY: docker-down
docker-down:
	@echo "Stopping Docker services..."
	docker-compose down

.PHONY: docker-test
docker-test:
	@echo "Running Docker test..."
	docker-compose up --build