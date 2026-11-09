# Slika servera: Dart se kompajlira u jedan izvršni fajl i radi u praznoj (scratch) slici.
FROM dart:3.13.5 AS build
WORKDIR /workspace
# Workspace samo sa paketima koje server koristi (bez Fluttera).
COPY <<EOF pubspec.yaml
name: kap_server_image
environment:
  sdk: ^3.13.0
workspace:
  - packages/domain
  - packages/demo_data
  - packages/api_contract
  - packages/api_mapping
  - apps/server
EOF
COPY pubspec.lock ./
COPY packages/domain packages/domain
COPY packages/demo_data packages/demo_data
COPY packages/api_contract packages/api_contract
COPY packages/api_mapping packages/api_mapping
COPY apps/server apps/server
RUN dart pub get
RUN dart compile exe apps/server/bin/server.dart -o /server

FROM scratch
COPY --from=build /runtime/ /
COPY --from=build /server /app/server
WORKDIR /app
ENV HOST=0.0.0.0
USER 65532:65532
EXPOSE 8080
CMD ["/app/server"]
