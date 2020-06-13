#!/bin/sh -eux

echo "I am here"

jq . "${GITHUB_EVENT_PATH}"


echo "::set-output name=fails::0"

exit 0
