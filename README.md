# med_connect

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Running in Docker

No local Flutter SDK is required — only Docker.

| Command        | What it does                                              |
|----------------|-----------------------------------------------------------|
| `make dev`     | Hot-reload dev server → http://localhost:8080 (`r` reload, `R` restart, `q` quit) |
| `make prod`    | Release web build served by nginx → http://localhost:8081 |
| `make test`    | Run `flutter test` in the container                        |
| `make analyze` | Run `flutter analyze`                                     |
| `make shell`   | Bash shell with the Flutter SDK                           |
| `make stop`    | Stop containers                                           |

Flutter version is pinned via `FLUTTER_VERSION` in the `Dockerfile` (currently 3.44.0).
Android/iOS builds still need a local SDK/Xcode — the container targets web.
