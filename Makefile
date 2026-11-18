FLUTTER = docker compose run --rm --service-ports dev flutter

.PHONY: dev prod stop shell test analyze pub-get build-web clean

dev:        ## Run app with hot reload at http://localhost:8080
	docker compose run --rm --service-ports dev
prod:       ## Build & serve release web build at http://localhost:8081
	docker compose up --build -d web
stop:
	docker compose down
shell:      ## Shell inside the Flutter container
	docker compose run --rm dev bash
test:
	docker compose run --rm dev flutter test
analyze:
	docker compose run --rm dev flutter analyze
pub-get:
	docker compose run --rm dev flutter pub get
build-web:  ## Release web build into ./build (via bind mount)
	docker compose run --rm -v $(PWD)/build:/app/build dev flutter build web --release
clean:
	docker compose down -v --rmi local
