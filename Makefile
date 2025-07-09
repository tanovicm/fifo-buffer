PROTO_DIR=proto
GO_OUT_DIR=gen/go
PY_OUT_DIR=client/gen
PROTO_FILE=$(PROTO_DIR)/fifo/v1/fifo.proto

.PHONY: all go python clean build run-server run-client

all: go python

go:
	@echo "Generating Go code..."
	mkdir -p $(GO_OUT_DIR)
	protoc \
		--proto_path=$(PROTO_DIR) \
		--go_out=$(GO_OUT_DIR) \
		--go_opt=paths=source_relative \
		$(PROTO_FILE)

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


clean:
	@echo "Cleaning generated files..."
	rm -rf $(GO_OUT_DIR)
	rm -rf $(PY_OUT_DIR)
	rm -rf bin/
	rm -rf venv/

build:
	@echo "Building Go server..."
	go build -o bin/server cmd/server/main.go

run-server: build
	@echo "Running Go server..."
	./bin/server

run-client:
	@echo "Running Python client..."
	python3 client/client.py
