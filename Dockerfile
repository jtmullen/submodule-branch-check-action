FROM alpine:3.11

RUN apk --no-cache add git

COPY entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
