#!/bin/sh -l

echo "I am here"
echo "Input Branch: $INPUT_BRANCH"
cd "$GITHUB_WORKSPACE"
GIT_STATUS=`git status`
echo "Status $GIT_STATUS"
BRANCH_NAME=`git rev-parse --abbrev-ref HEAD`
echo "Found branch $BRANCH_NAME"

GIT_HASH=`git rev-parse`
HEAD_HASH=`git rev-parse HEAD`
echo "Hash: $GIT_HASH  -  $HEAD_HASH"
cd common/api/CAN
GIT_HASH=`git rev-parse`
HEAD_HASH=`git rev-parse HEAD`
echo "CAN Hash: $GIT_HASH  -  $HEAD_HASH"

echo "::set-output name=fails::0"

exit 0
