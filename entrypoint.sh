#!/bin/sh -l

error () {
	echo "::error::$1"
	exit 1
}

echo "Branch test checkout action for submodules"

REPO=`jq -r ".repository.full_name" "${GITHUB_EVENT_PATH}"`
PR=`jq -r ".number" "${GITHUB_EVENT_PATH}"`
BRANCH=`jq -r ".pull_request.head.ref" "${GITHUB_EVENT_PATH}"`
BASE_BRANCH=`jq -r ".pull_request.base.ref" "${GITHUB_EVENT_PATH}"`
echo "Run for PR # ${PR} of ${BRANCH} into ${BASE_BRANCH}"

echo "Move to github directory"
cd "${GITHUB_WORKSPACE}" || error "Error: Cannot change directory to Github Workspace"

## Check for submodule valid
echo "CHECK SM"
SUBMODULES=`git config --file .gitmodules --name-only --get-regexp path`
echo "${SUBMODULES}" | grep ".${INPUT_PATH}." || error "Error: path is not a submodule"

cd "${INPUT_PATH}" || error "Error: cannot move to sm path"

echo "Back to gh workspace"
cd "${GITHUB_WORKSPACE}" || error "Error: Cannot change directory to Github Workspace"

echo "LOG"
git log

echo "Checkout master"

git checkout master

echo "Done"

git submodule update "${INPUT_PATH}"

cd "${INPUT_PATH}" || error "Error: cannot move to sm path"

echo "SM hash after update"
git rev-parse HEAD

exit 1


### IGNORE FOR NOW



cd "${GITHUB_WORKSPACE}" || die "Error: Cannot change directory to Github Workspace"

git config --global user.email "action@github.com"
git config --global user.name "GitHub Submodule Check Action"

## Use given token if provided, otherwise Github token
if [[ ! -z INPUT_TOKEN ]]; then
    TOKEN="${INPUT_TOKEN}"
    echo "Input Token"
else
    TOKEN="${GITHUB_TOKEN}"
    echo "GH token"
fi

git remote set-url origin "https://x-access-token:${TOKEN}@github.com/${REPO}.git/"
REMOTES=`git fetch --all -p`

## Check for submodule valid
SUBMODULES=`git config --file .gitmodules --name-only --get-regexp path`
echo "${SUBMODULES}" | grep ".${INPUT_PATH}." || die "Error: path is not a submodule"



git checkout "${BRANCH}"
git submodule init "${INPUT_PATH}"
git submodule update "${INPUT_PATH}"

echo "Switch to submodule at: ${INPUT_PATH}"
cd "${INPUT_PATH}" || die "Error: Cannot change directory to the submodule"
SUBMODULE_HASH=`git rev-parse HEAD`

cd ..
git checkout "${BASE_BRANCH}"

git submodule update "${INPUT_PATH}"

cd "${INPUT_PATH}" 
SUBMODULE_HASH_BASE=`git rev-parse HEAD`

echo "Submodule ${INPUT_PATH} Changed from: ${SUBMODULE_HASH_BASE} to ${SUBMODULE_HASH}"

fail () {
	echo "::error file=${INPUT_PATH}::$1"
	echo "::set-output name=fails::$1"
	exit 1
}

pass () {
    echo "PASS: $1"
	echo "::set-output name=fails::"
	exit 0	
}

## Check if on required branch
if [[ ! -z INPUT_BRANCH ]]; then
	echo "Check for submodule on branch ${INPUT_BRANCH}"
	BRANCHES=`git branch -r --contains ${SUBMODULE_HASH}`
	echo "${BRANCHES}" | grep "/${INPUT_BRANCH}$" || fail "Submodule ${INPUT_PATH} Hash ${SUBMODULE_HASH} is not on branch ${INPUT_BRANCH}"
	echo "Submodule is on branch ${INPUT_BRANCH}"
fi

## If they are the same pass
echo "Check if submodule unchanged from ${BASE_BRANCH}"
if [ "${master_lib_hash}" == "${lib_hash}" ]; then
    pass "${INPUT_PATH} is unchanged from ${BASE_BRANCH}"
fi

## Check that base hash is an ancestor of the ref hash
git rev-list "${SUBMODULE_HASH}" | grep "${SUBMODULE_HASH_BASE}" || fail "Submodule ${INPUT_PATH} on ${BASE_BRANCH} is not an ancestor of that on ${BRANCH}"

pass "Valid submodule ${INPUT_PATH} on ${BRANCH}"
