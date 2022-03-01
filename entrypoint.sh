#!/bin/bash

error () {
	echo "::set-output name=fails::error"
	echo "::error::$1"
	exit 1
}

# When a new submodule is added we have no way to check for progression. In this case we will skip that check (instead of failing it)
newSubmodule=false
newSubmoduleWarning() {
	newSubmodule=true
	echo "::warning::Submodule $1 does not exist on the base branch/commit;  Cannot do progression check for new submodules"
}

## Path to JSON Payload of the Github Event Info
EVENT_PATH="${GITHUB_EVENT_PATH}"

## Check for override of event path - used for tests
if [[ ! -z "${INPUT_EVENT_PATH}" ]]; then
	EVENT_PATH="${INPUT_EVENT_PATH}"
	## Put warning here as this probably should not be used outside testing
	echo "::warning::Github Event Payload Path Overwritten. Only intended for testing use."
fi

echo "::group::Setup"

cd "${GITHUB_WORKSPACE}" || error "__Line:${LINENO}__Error: Cannot change directory to Github Workspace"

REPO=`jq -r ".repository.full_name" "${EVENT_PATH}"`

## Get all the info about this push or pr event we need to check the submodule
isPR=false
if [[ $(jq -r ".pull_request.head.ref" "${EVENT_PATH}") != "null" ]]; then
	PR=`jq -r ".number" "${EVENT_PATH}"`
	PR_BRANCH=`jq -r ".pull_request.head.ref" "${EVENT_PATH}"`
	BASE_BRANCH=`jq -r ".pull_request.base.ref" "${EVENT_PATH}"`
	USER=`jq -r ".pull_request.user.login" "${EVENT_PATH}"`
	git fetch origin "${PR_BRANCH}" --recurse-submodules=no --depth 1 || error "__Line:${LINENO}__Error: Could not fetch tip of ${PR_BRANCH}"
	git fetch origin "${BASE_BRANCH}" --recurse-submodules=no --depth 1 || error "__Line:${LINENO}__Error: Could not fetch tip of ${BASE_BRANCH}"
	TO_HASH=`git rev-parse origin/${PR_BRANCH}`
	FROM_HASH=`git rev-parse origin/${BASE_BRANCH}`
	echo "Run for PR # ${PR} of ${PR_BRANCH} into ${BASE_BRANCH} on ${REPO} by ${USER}"
	echo "Hash ${TO_HASH} into ${FROM_HASH}"
	isPR=true
elif [[ $(jq -r ".after" "${EVENT_PATH}") != "null" ]]; then
	TO_HASH=`jq -r ".after" "${EVENT_PATH}"`
	FROM_HASH=`jq -r ".before" "${EVENT_PATH}"`
	BRANCH_NAME=`jq -r ".ref" "${EVENT_PATH}"`
	BASE_BRANCH="${FROM_HASH}"
	PR_BRANCH="${TO_HASH}"
	USER=`jq -r ".pusher.name" "${EVENT_PATH}"`
	echo "Run for push of ${BRANCH_NAME} from ${FROM_HASH} to ${TO_HASH} on ${REPO} by ${USER}"
else
	## Doesn't appear to be a PR or a push
	error "Unknown Github Event Payload"
fi

## Fetch both branches for PR
if [[ "${isPR}" = true ]]; then
	echo "::group::Get PR Branches"
	echo "Fetch Branch Histories"
	if [[ ! -z "${INPUT_FETCH_DEPTH}" ]]; then
		echo "Histories to depth: ${INPUT_FETCH_DEPTH}"
		git fetch origin "${PR_BRANCH}" --recurse-submodules=no --depth "${INPUT_FETCH_DEPTH}" || error "__Line:${LINENO}__Error: Could not fetch history of ${PR_BRANCH}"
		git fetch origin "${BASE_BRANCH}" --recurse-submodules=no --depth "${INPUT_FETCH_DEPTH}" || error "__Line:${LINENO}__Error: Could not fetch history of ${BASE_BRANCH}"
	else
		echo "Full Brach Histories"
		git fetch origin --recurse-submodules=no "${PR_BRANCH}" || error "__Line:${LINENO}__Error: Could not fetch history of ${PR_BRANCH}"
		git fetch origin --recurse-submodules=no "${BASE_BRANCH}" || error "__Line:${LINENO}__Error: Could not fetch history of ${BASE_BRANCH}"
	fi
	echo "::endgroup::"
fi

echo "::endgroup::"
echo "::group::Get Submodule Info"


## Move to end hash when setting up submodule, otherwise would fail if submodule does not exist on whetever was originally checked out
git checkout "${TO_HASH}" || error "__Line:${LINENO}__Error: Could not checkout ${TO_HASH}"

## Check for submodule valid
SUBMODULES=`git config --file .gitmodules --name-only --get-regexp path`
echo "${SUBMODULES}" | grep ".${INPUT_PATH}." || error "Error: path \"${INPUT_PATH}\" is not a submodule on ${TO_HASH}"

## Initialize Submodule
git submodule update --init --depth=1 "${INPUT_PATH}" || error "__Line:${LINENO}__Error: Could not initialize submodule ${INPUT_PATH} as referenced by ${PR_BRANCH} (is the referenced commit pushed to remote?)"
cd "${INPUT_PATH}" || error "__Line:${LINENO}__Error: Cannot change directory to the submodule"
SUBMODULE_HASH=`git rev-parse HEAD`
echo "LIST!"
git rev-list "${SUBMODULE_HASH}" 

## Need to get all remote branches, we don't know what we don't know about the submodule
git remote set-branches origin '*' || error "__Line:${LINENO}__Error: Could not set branches"
git checkout "${SUBMODULE_HASH}" || error "__Line:${LINENO}__Error: Cannot checkout submodule hash"

## Update Submodule 
if [[ ! -z "${INPUT_SUB_FETCH_DEPTH}" ]]; then
	echo "Submodule History to depth: ${INPUT_SUB_FETCH_DEPTH}"
	git fetch origin --recurse-submodules=no --depth "${INPUT_SUB_FETCH_DEPTH}" || error "__Line:${LINENO}__Error: Error Fetching Submodule ${INPUT_PATH}"
else 
	echo "Full Submodule History"
	if [[ "$(git rev-parse --is-shallow-repository)" = true ]]; then
		git fetch origin --recurse-submodules=no || error "__Line:${LINENO}__Error: Error Fetching Submodule ${INPUT_PATH}"
	else
		git fetch origin --recurse-submodules=no --unshallow || error "__Line:${LINENO}__Error: Error Fetching Submodule ${INPUT_PATH}"
	fi
fi
echo "LIST2"
git rev-list "${SUBMODULE_HASH}" 

cd "${GITHUB_WORKSPACE}" || error "__Line:${LINENO}__Error: Cannot change directory to Github Workspace" 
git checkout "${FROM_HASH}"  || error "__Line:${LINENO}__Error: Could not checkout ${FROM_HASH}"

## Check if submodule is new between commits/branches
BASESUBMODULES=`git config --file .gitmodules --name-only --get-regexp path`
echo "${BASESUBMODULES}" | grep ".${INPUT_PATH}." || newSubmoduleWarning "${INPUT_PATH}"

## Only get submodule on base if it exists
if [ "$newSubmodule" = false ]; then
	git submodule update -N "${INPUT_PATH}"  || error "__Line:${LINENO}__Error: Could not checkout submodule hash referenced by ${BASE_BRANCH} (is it pushed to remote?)"

	cd "${INPUT_PATH}" || error "__Line:${LINENO}__Error: Cannot change directory to the submodule"
	SUBMODULE_HASH_BASE=`git rev-parse HEAD`

	echo "Submodule ${INPUT_PATH} Changed from: ${SUBMODULE_HASH_BASE} to ${SUBMODULE_HASH}"
fi

fail () {
	echo "::error file=${INPUT_PATH}::$1"
	echo "::set-output name=fails::$1"
	exit 1
}

pass () {
	echo -e "\033[0;32mPASS: $1\033[0m"
	echo "::set-output name=fails::"
	exit 0	
}

cd "${GITHUB_WORKSPACE}" || error "__Line:${LINENO}__Error: Cannot change directory to Github Workspace" 

echo "::endgroup::"

## Immediately pass if submodule is not changed (PR only)
if [[ ! -z "${INPUT_PASS_IF_UNCHANGED}" ]]; then
	echo "::group::Check if Unchanged"
	if [[ "${isPR}" = true ]]; then 
		echo "Check if submodule has been changed on ${PR_BRANCH}"
		CHANGED=`git diff --name-only ${FROM_HASH}...${TO_HASH}`
		if ! grep "^${INPUT_PATH}$" <<< "${CHANGED}"; then
			pass "Submodule ${INPUT_PATH} has not been changed on branch ${PR_BRANCH}"
		fi
		echo "Submodule has been changed"
	else
		echo "Note: Not a PR - Pass if Unchanged ignored"
	fi	
	echo "::endgroup::"
fi

cd "${INPUT_PATH}" || error "__Line:${LINENO}__Error: Cannot change directory to the submodule"
git checkout "${SUBMODULE_HASH}" || error "__Line:${LINENO}__Error: Cannot checkout submodule hash"
echo "status"
git status

## Check if most recent required
if [[ ! -z "${INPUT_REQUIRE_HEAD}" ]]; then
	echo "::group::Check if Most Recent"
	echo "Check if on most recent"
	if [[ -z "${INPUT_BRANCH}" ]]; then
		error "Error: Branch not provided but Head Commit is required"
	fi
	HEAD_SHA=`git rev-parse origin/${INPUT_BRANCH}`
	if [ "${HEAD_SHA}" == "${SUBMODULE_HASH}" ]; then
		pass "${INPUT_PATH} is the the most recent ${INPUT_BRANCH}"
	else
		fail "Submodule ${INPUT_PATH} is not on most recent ${INPUT_BRANCH} ($HEAD_SHA)"
	fi
	echo "::endgroup::"
fi

## Check if on required branch
if [[ ! -z "${INPUT_BRANCH}" ]]; then
	echo "::group::Check Required Branch"
	echo "Check for submodule on branch ${INPUT_BRANCH}"
	BRANCHES=`git branch -r --contains ${SUBMODULE_HASH}`
	echo "${BRANCHES}" | grep "/${INPUT_BRANCH}$" || fail "Submodule ${INPUT_PATH} Hash ${SUBMODULE_HASH} is not on branch ${INPUT_BRANCH}"
	echo "Submodule is on branch ${INPUT_BRANCH}"
	echo "::endgroup::"
fi


##only check for progression if we have something to compare against
if [ "$newSubmodule" = false ]; then
	echo "::group::Check Progression"
	## If they are the same pass
	echo "Check if submodule is identical hash"
	if [ "${SUBMODULE_HASH_BASE}" == "${SUBMODULE_HASH}" ]; then
		pass "${INPUT_PATH} is the same as ${BASE_BRANCH}"
	fi

	## Check that base hash is an ancestor of the ref hash
	echo "Verify old submodule hash is ancestor of current"
	echo "${SUBMODULE_HASH}"
	echo "${SUBMODULE_HASH_BASE}"
	git rev-list "${SUBMODULE_HASH}" 
	git log --pretty --oneline
	git rev-list "${SUBMODULE_HASH}" 
	git rev-list "${SUBMODULE_HASH}" | grep "${SUBMODULE_HASH_BASE}" || fail "Submodule ${INPUT_PATH} on ${BASE_BRANCH} is not an ancestor of that on ${PR_BRANCH}"
	echo "::endgroup::"
fi

pass "Valid submodule ${INPUT_PATH} on ${PR_BRANCH}"
