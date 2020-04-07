FROM fpco/stack-build:lts-9.10 as build

ENV LANG=C.UTF-8

WORKDIR /build

COPY . .

RUN stack build --system-ghc

FROM debian:buster-slim

WORKDIR /app

COPY --from=build /build/.stack-work/install/x86_64-linux/lts-9.10/8.0.2/bin /usr/local/bin

ENV LANG=C.UTF-8

RUN mkdir /app/log && \
    ln -sf /dev/stdout /app/log/access.log && \
    ln -sf /dev/stderr /app/log/error.log

CMD /usr/local/bin/duckling-example-exe
