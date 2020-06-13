#!/bin/sh -l

REPO=`jq -r ".repository.full_name" "${GITHUB_EVENT_PATH}"`
PR=`jq -r ".number" "${GITHUB_EVENT_PATH}"`
BRANCH=`jq -r ".pull_request.head.ref" "${GITHUB_EVENT_PATH}"`
BASE_BRANCH=`jq -r ".pull_request.base.ref" "${GITHUB_EVENT_PATH}"`
echo "Run for PR # ${PR} of ${BRANCH} into ${BASE_BRANCH}"

cd "${GITHUB_WORKSPACE}"

git config --global user.email "submodule@github.com"
git config --global user.name "GitHub Submodules Action"

REMOTES=`git remote set-url origin "https://x-access-token:${GITHUB_TOKEN}@github.com/${REPO}.git/"`
git fetch --all -p

git checkout "${BASE_BRANCH}"

git submodule init
git submodule update

cd Libraries
lib_hash=`git rev-parse HEAD`

cd ..
git checkout "${BRANCH}"
git submodule update

cd Libraries
master_lib_hash=`git rev-parse HEAD`

echo "Submodule Hash: ${master_lib_hash} -> ${lib_hash}"

## If they are the same its all good
if [ "${master_lib_hash}" == "${lib_hash}" ]; then
    echo "PASS"
fi

if (git branch --contains "${lib_hash}" | grep master); then
    echo "Yes"
else
    echo "No"
fi

echo "::set-output name=fails::0"

exit 0
