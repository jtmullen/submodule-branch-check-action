#!/bin/sh -l

echo "I am here"
echo "Input Branch: $INPUT_BRANCH"
cd "$GITHUB_WORKSPACE"
GIT_STATUS=`git status`
echo "Status $GIT_STATUS"
BRANCH_NAME=`git rev-parse --abbrev-ref HEAD`
echo "Found branch $BRANCH_NAME"

echo "::set-output name=fails::0"

exit 0
