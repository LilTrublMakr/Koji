FROM --platform=linux/amd64 node:22-alpine AS client
WORKDIR /app
COPY ./client .
RUN yarn install
RUN yarn build

FROM rust:1.93-bookworm AS server
ENV PKG_CONFIG_ALLOW_CROSS=1
WORKDIR /usr/src/koji
COPY ./server .
RUN apt-get update && apt-get install -y
RUN cargo install --path . --locked

FROM rust:1.93-bookworm AS tsp
RUN apt-get update && apt-get install -y build-essential
RUN cargo install --git https://github.com/TurtIeSocks/tsp-mt --features fetch-lkh

FROM debian:bookworm-slim AS runner
RUN mkdir -p algorithms/src/routing/plugins
COPY --from=tsp /usr/local/cargo/bin/tsp-mt ./algorithms/src/routing/plugins/tsp
COPY --from=client /app/dist ./dist
COPY --from=server /usr/local/cargo/bin/koji /usr/local/bin/koji
RUN apt-get update \
    && apt-get install -y --no-install-recommends libssl3 ca-certificates \
    && rm -rf /var/lib/apt/lists/*

CMD koji
