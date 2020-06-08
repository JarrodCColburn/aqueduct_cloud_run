FROM google/dart:2.8 as build

WORKDIR /app
# pubspec aqueduct version 4 required
ADD pubspec.* /app/
RUN pub get --no-precompile
ADD . /app
RUN pub get --offline --no-precompile \
    && rm -f *.aot \
    # (re)Create executable of an Aqueduct application.
    # (default output `[project_name].aot`)
    && pub run aqueduct build 

# For distroless images, CMD and ENTRYPOINT must be declared in array form
# w/o access to ENV variables
FROM gcr.io/distroless/base-debian10
COPY --from=build /app/*.aot /serve
ADD config.yaml /config.yaml 
# Must explicitly address 0.0.0.0 or will not accept incoming connections
ENTRYPOINT ["/serve","--config-path=/config.yaml","--port=8080","--address=0.0.0.0"]
# Service must listen to $PORT environment variable.
# This default value facilitates local development.
EXPOSE 8080

# TODO should set flag `--timeout=n` for entrypoint? What's a good n value?

# TODO should set flag `--isolates=n` for `n=$(($(nproc)/2))` for entrypoint? 
# Distroless does not have `nproc`
