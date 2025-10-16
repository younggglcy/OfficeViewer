.PHONY: build run format lint clean test help

# Format code with swift-format
format:
	swift format -i -r Sources/ Tests/

# Build the project
build:
	xcodebuild -scheme OfficeViewer build

# Run the app
run:
	xcodebuild -scheme OfficeViewer run

# Clean build artifacts
clean:
	xcodebuild clean
	rm -rf .build/

# Lint code formatting
lint:
	swift format lint -r Sources/ Tests/

# Run tests
test:
	xcodebuild -scheme OfficeViewerTests test

help:
	@echo "Available commands:"
	@echo "  make format  - Format code with swift-format"
	@echo "  make lint    - Check code formatting"
	@echo "  make build   - Build the project"
	@echo "  make run     - Run the app"
	@echo "  make test    - Run tests"
	@echo "  make clean   - Clean build artifacts"
