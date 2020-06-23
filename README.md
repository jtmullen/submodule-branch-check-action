# submodule-branch-check-action
A [github action](https://help.github.com/en/actions) to ensure that a submodule is progressing to a child of the previous version on the base branch (for a PR) and that the new submodule version is on a specific branch (optional). 


## Inputs
### `path`
The path to the submodule, this is required. Do not include leading or trailing slashes. 
*Note: this must be the path the submodule is located at in the repo and the path to which you checkout the submodule in the workflow!*

### `branch`
The branch that the submodule version must be on. 

This is optional, if not included the submodule will only be checked for progression, not commit presence on a specific branch. 

## Outputs
### `fails`
The reason the action failed (if any). The check will stop at the first failure. 

## Usage
To add to a repo create a workflow file (such as `.github/workflows/check-submodules.yml`) with the following content adjusted for your needs:

```yml
name: check-submodule

on: [push, pull_request]

jobs:
  check-submodules:
    name: Check Submodule
    runs-on: ubuntu-latest
    steps:
    - name: Checkout this repo
      uses: actions/checkout@v2
	  with:
		fetch-depth: 0
    - name: Checkout submodule repo
      uses: actions/checkout@v2
	  with:
	    repository: UserOrOrganization/Repo
		path: "path/to/repo"
		token: ${{ secrets.PAT_for_Private_Submodule }}
		fetch-depth: 0
    - name: Check Submodule Name
      uses: jtmullen/submodule-branch-check-action@v0.1.0
      with:
        path: "path/to/submodule"
        branch: "master"
```

### Usage Notes
To ensure this action runs correctly you must checkout both the current repo and the submodule repo as expected with the appropriate amount of information about the repo history included. As shown above, the [Github Checkout Action](https://github.com/actions/checkout/) is a good way to set this up. Below are the main requirements for doing so:

**Fetch Depth:** This action requires enough git history to have access to the last commit on both branches on the PR in the repo the action is run from and enough history to determine the relationship between the respecitive submodule commits for those two branches. A fetch depth of 0 will checkout the full history. Depending on the workflow on your two repos you may be able to safely cap this at a specific depth.

**Token:** If your submodule is private, provide a personal access token repo level access for the submodule. 

**Path:** Leave the repo the action is run on at the default location, checkout the submodule into its apropriate location in the repo. 

You can also see [where this is used](https://github.com/search?l=YAML&q=submodule-branch-check-action&type=Code)

*Note: this was developed for several private repos so many uses will not be listed above*