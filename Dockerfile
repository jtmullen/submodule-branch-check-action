FROM alpine:3.11

RUN apk add --no-cache bash
RUN apk --no-cache add git
RUN apk --no-cache add git-lfs
RUN apk --no-cache add jq


COPY entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
