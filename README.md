# submodule-branch-check-action
A [github action](https://help.github.com/en/actions) to ensure that a submodule is progressing to a child of the previous version (or not changing) and that the new submodule version is on a specific branch (optional). 


## Inputs
### `path`
The path to the submodule, this is required. Do not include leading or trailing slashes. 
*Note: this must be the path the submodule is located at in the repo and the path to which you checkout the submodule in the workflow!*

### `branch`
The branch that the submodule version must be on. 

This is optional, if not included the submodule will only be checked for progression, not commit presence on a specific branch. 

### `pass_if_unchanged`
If the check should automatically pass if the submodule was not changed on this branch. Only available on a PR, not a push. 

This is optional, if included an unchanged submodule results in automatic pass. Will be ignored if the trigger event is not a pull request. 

### `fetch_depth`
Fetch depth for the two relevant branches on a PR trigger. The action will checkout the two branches to this depth, if you know your branches are relatively short lived compared to the full history of your repo this can save you some processing time, network traffic, etc. by only checking out enough to cover your needs. 

This is optional, if not included it will default to full history for the branches.

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
    - name: Checkout submodule repo
      uses: actions/checkout@v2
          with:
              repository: UserOrOrganization/Repo
              path: "path/to/repo"
              token: ${{ secrets.PAT_for_Private_Submodule }}
              fetch-depth: 0
    - name: Check Submodule Name
      uses: jtmullen/submodule-branch-check-action@v0.5.0-beta
      with:
        path: "path/to/submodule"
        branch: "master"
        fetch_depth: "50"
        pass_if_unchanged: "true"
```

### Usage Notes
To ensure this action runs correctly you must checkout both the current repo and the submodule repo as expected with the appropriate amount of information about the repo history included. As shown above, the [Github Checkout Action](https://github.com/actions/checkout/) is a good way to set this up. Below are the main requirements for doing so:

**Fetch Depth:** This action handles the fetching (not cloning!) for the repo it is run on (checkout action does not have multibranch depth option at this time). On the submodule this will vary based on your workflow. You will need enough history for this action to determine the relationship between the submodule versions on the version being compared. If you are always working with very recent versions of the submodule this may be a small number, otherwise it could be much larger. 

**Token:** If your submodule is private, provide a personal access token repo level access for the submodule so it can be checked out. If not using actions/Checkout ensure your method also persists the token so this action can access the remote repo.  

**Path:** Leave the repo the action is run on at the default location, checkout the submodule into its appropriate location in the repo. 

You can also see [where this is used](https://github.com/search?l=YAML&q=submodule-branch-check-action&type=Code)

*Note: this was developed for several private repos so many uses will not be listed above*
