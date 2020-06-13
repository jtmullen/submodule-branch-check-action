FROM alpine:3.11

RUN apk --no-cache add git
RUN apk --no-cache add jq
RUN apk --no-cache add curl

COPY entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
