# submodule-branch-check-action
A [github action](https://help.github.com/en/actions) to ensure that a submodule is progressing to a child of the previous version (or not changing) and that the new submodule version is on a specific branch (optional). 


## Inputs
### `path` (required)
The path to the submodule, this is required. Do not include leading or trailing slashes. 
*Note: this must be the path the submodule is located at in the repo!*

### `branch` (optional)
The name of a branch that the submodule hash must be on (after the push or on the head PR branch)

### `first_parent` (optional)
Require the submodule's checked-out commit to be an ancestor of the specified branch strictly along the path following first parents only.  That is, the submodule's current HEAD must either currently be or have at some point in the past been the tip of the branch specified.

### `pass_if_unchanged` (optional)
For pull request only, if this is included the check will automatically pass if none of the commits modify the submodule. 

### `fetch_depth` (optional)
Fetch depth for the two relevant branches on a PR trigger. The action will checkout the two branches to this depth, if you know your branches are relatively short lived compared to the full history of your repo this can save you some processing time, network traffic, etc. by only checking out enough to cover your needs instead of the default full history.

### `sub_fetch_depth` (optional)
Fetch depth for the submodule being checked. This will check out every branch to this depth. By default the full history will be checked out. I recommend leaving this at default unless your submodule is excessively large. Due to the nature of submodules there are many situations where, if the submodule is in a weird state, you will not get descriptive errors without a full fetch. 

### `require_head` (optional)
If the submodule is required to be on the head (most recent commit) of the specified branch. Keep in mind that it is possible that this will pass on a PR at the time it is run but no longer be on the most recent at the time of merge. Branch must also be specified for this to be checked.

## Outputs
### `fails`
The reason the action failed (if any). The check will stop at the first failure. In case of an error, fails will equal "error"

## Usage
To add to a repo create a workflow file (such as `.github/workflows/check-submodules.yml`) with the following content adjusted for your needs. Note that the step to checkout the submodule is only required for private submodules. 
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
    ## Step only reqired for private submodules
    - name: Checkout submodule repo
      uses: actions/checkout@v2
      with:
        repository: UserOrg/RepoName
        path: "path/to/repo"
        token: ${{ secrets.PAT_for_Private_Submodule }}
    - name: Check Submodule Name
      uses: jtmullen/submodule-branch-check-action@v1
      with:
        path: "path/to/submodule"
        branch: "main"
        first_parent: true
        fetch_depth: "50"
        pass_if_unchanged: true
        require_head: true
```

### Usage Notes
To ensure this action runs correctly you must checkout the current repo. If the submodule is private, you must also check out the submodule repo, in the correct location. As shown above, the [Github Checkout Action](https://github.com/actions/checkout/) is a good way to set this up. Below are the main requirements for doing so:

**Fetch Depth:** This action handles the fetch depth for both the parent repo and submodule. If you are restricting the fetch depth in this action be sure to pay attention to the default in your checkout method - you may need to restrict it there as well for the desired effect.

**Token:** If your submodule is private, provide a personal access token with repo level access for the submodule so it can be checked out. If not using the first party GitHub Checkout Action, ensure your method also persists the token so this action can access the remote repo.  

**Path:** Leave the repo the action is run on at the default location, checkout the submodule into its appropriate location within the repo. 


You can also see [where this is used](https://github.com/search?l=YAML&q=submodule-branch-check-action&type=Code)

*Note: this was developed for several private repos so many uses will not be listed above*
