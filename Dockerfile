# syntax=docker/dockerfile:1
ARG FLUTTER_VERSION=3.44.0

# ---------- base: Flutter SDK ----------
FROM ghcr.io/cirruslabs/flutter:${FLUTTER_VERSION} AS base
WORKDIR /app
RUN git config --global --add safe.directory '*' \
 && flutter config --no-analytics --enable-web >/dev/null \
 && flutter precache --web

# ---------- dev: hot-reload web server ----------
FROM base AS dev
COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get
COPY . .
EXPOSE 8080
CMD ["flutter", "run", "-d", "web-server", "--web-hostname", "0.0.0.0", "--web-port", "8080"]

# ---------- build: release web bundle ----------
FROM base AS build
COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get
COPY . .
RUN flutter build web --release

# ---------- prod: static nginx ----------
FROM nginx:1.27-alpine AS prod
COPY docker/nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=build /app/build/web /usr/share/nginx/html
EXPOSE 80
HEALTHCHECK CMD wget -qO- http://localhost/ >/dev/null || exit 1
