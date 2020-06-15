FROM alpine:3.11

RUN apk --no-cache add git
RUN apk --no-cache add jq

COPY github.sig /github.sig
COPY entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
