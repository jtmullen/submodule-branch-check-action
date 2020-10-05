#!/bin/bash

error () {
	echo "::error::$1"
	exit 1
}

REPO=`jq -r ".repository.full_name" "${GITHUB_EVENT_PATH}"`

isPR=false
if [[ $(jq -r ".pull_request.head.ref" "${GITHUB_EVENT_PATH}") != "null" ]]; then
	PR=`jq -r ".number" "${GITHUB_EVENT_PATH}"`
	TO_HASH=`jq -r ".pull_request.head.sha" "${GITHUB_EVENT_PATH}"`
	FROM_HASH=`jq -r ".pull_request.base.sha" "${GITHUB_EVENT_PATH}"`
	PR_BRANCH=`jq -r ".pull_request.head.ref" "${GITHUB_EVENT_PATH}"`
	BASE_BRANCH=`jq -r ".pull_request.base.ref" "${GITHUB_EVENT_PATH}"`
	USER=`jq -r ".pull_request.user.login" "${GITHUB_EVENT_PATH}`
	echo "Run for PR # ${PR} of ${PR_BRANCH} into ${BASE_BRANCH} on ${REPO} by ${USER}"
	echo "Hash ${TO_HASH} into ${FROM_HASH}"
	isPR=true
elif [[ $(jq -r ".after" "${GITHUB_EVENT_PATH}") != "null" ]]; then
	TO_HASH=`jq -r ".after" "${GITHUB_EVENT_PATH}"`
	FROM_HASH=`jq -r ".before" "${GITHUB_EVENT_PATH}"`
	BRANCH_NAME=`jq -r ".ref" "${GITHUB_EVENT_PATH}"`
	USER=`jq -r ".pusher.name" "${GITHUB_EVENT_PATH}"`
	echo "Run for push of ${BRANCH_NAME} from ${FROM_HASH} to ${TO_HASH} on ${REPO} by ${USER}"
else
	error "Unknown Github Event Path"
fi

cd "${GITHUB_WORKSPACE}" || error "__Line:${LINENO}__Error: Cannot change directory to Github Workspace"

## Fetch both branches for PR
if [[ "${isPR}" = true ]]; then
	echo "Fetch Branch Histories"
	if [[ ! -z "${INPUT_FETCH_DEPTH}" ]]; then
		echo "Histories to depth: ${INPUT_FETCH_DEPTH}"
		git fetch origin "${TO_HASH}" --recurse-submodules=no --depth "${INPUT_FETCH_DEPTH}" || error "__Line:${LINENO}__Error: Could not fetch history of ${TO_HASH}"
		git fetch origin "${FROM_HASH}" --recurse-submodules=no --depth "${INPUT_FETCH_DEPTH}" || error "__Line:${LINENO}__Error: Could not fetch history of ${FROM_HASH}"
	else
		echo "Full Brach Histories"
		git fetch origin --recurse-submodules=no "${TO_HASH}" || error "__Line:${LINENO}__Error: Could not fetch history of ${TO_HASH}"
		git fetch origin --recurse-submodules=no "${FROM_HASH}" || error "__Line:${LINENO}__Error: Could not fetch history of ${FROM_HASH}"
	fi
fi

## Check for submodule valid
echo "Submodule and Tree Info"
SUBMODULES=`git config --file .gitmodules --name-only --get-regexp path`
echo "${SUBMODULES}" | grep ".${INPUT_PATH}." || error "Error: path \"${INPUT_PATH}\" is not a submodule"

git checkout "${TO_HASH}" || error "__Line:${LINENO}__Error: Could not checkout ${TO_HASH}"
git submodule init "${INPUT_PATH}" || error "__Line:${LINENO}__Error: Could initialize submodule"
git submodule update "${INPUT_PATH}" || error "__Line:${LINENO}__Error: Could not checkout submodule hash referenced by ${TO_HASH} (is it pushed to remote?)"

echo "Switch to submodule at: ${INPUT_PATH}"
cd "${INPUT_PATH}" || error "__Line:${LINENO}__Error: Cannot change directory to the submodule"
SUBMODULE_HASH=`git rev-parse HEAD`

cd "${GITHUB_WORKSPACE}" || error "__Line:${LINENO}__Error: Cannot change directory to Github Workspace" 
git checkout "${FROM_HASH}"  || error "__Line:${LINENO}__Error: Could not checkout ${FROM_HASH}"

git submodule update "${INPUT_PATH}"  || error "__Line:${LINENO}__Error: Could not checkout submodule hash referenced by ${FROM_HASH} (is it pushed to remote?)"

cd "${INPUT_PATH}" || error "__Line:${LINENO}__Error: Cannot change directory to the submodule"
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

cd "${GITHUB_WORKSPACE}" || error "__Line:${LINENO}__Error: Cannot change directory to Github Workspace" 

## Pass if they are unchanged
if [[ ! -z "${INPUT_PASS_IF_UNCHANGED}" ]]; then
	if [[ "${isPR}" = true ]]; then 
		echo "Check if submodule has been changed on ${TO_HASH}"
		CHANGED=`git diff --name-only origin/${FROM_HASH}...origin/${TO_HASH}`
		if ! grep "^${INPUT_PATH}$" <<< "${CHANGED}"; then
			pass "Submodule ${INPUT_PATH} has not been changed on branch ${TO_HASH}"
		fi
		echo "Submodule has been changed"
	else
		echo "Note: Not a PR - Pass if Unchanged ignored"
	fi	
fi

cd "${INPUT_PATH}" || error "__Line:${LINENO}__Error: Cannot change directory to the submodule"

## Check if on required branch
if [[ ! -z "${INPUT_BRANCH}" ]]; then
	echo "Check for submodule on branch ${INPUT_BRANCH}"
	BRANCHES=`git branch -r --contains ${SUBMODULE_HASH}`
	echo "${BRANCHES}" | grep "/${INPUT_BRANCH}$" || fail "Submodule ${INPUT_PATH} Hash ${SUBMODULE_HASH} is not on branch ${INPUT_BRANCH}"
	echo "Submodule is on branch ${INPUT_BRANCH}"
fi

## If they are the same pass
echo "Check if submodule unchanged"
if [ "${master_lib_hash}" == "${lib_hash}" ]; then
    pass "${INPUT_PATH} is the same as ${FROM_HASH}"
fi

## Check that base hash is an ancestor of the ref hash
echo "Check if old submodule has is parent of current"
git rev-list "${SUBMODULE_HASH}" | grep "${SUBMODULE_HASH_BASE}" || fail "Submodule ${INPUT_PATH} on ${FROM_HASH} is not an ancestor of that on ${TO_HASH}"

pass "Valid submodule ${INPUT_PATH} on ${TO_HASH}"
