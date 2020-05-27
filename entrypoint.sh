#!/bin/sh -l

echo "I am here"
echo "Input Branch: $INPUT_BRANCH"
cd "$GITHUB_WORKSPACE"
BRANCH_NAME=`git rev-parse --abbrev-ref HEAD`
echo "Found branch $BRANCH_NAME"

