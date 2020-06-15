# submodule-branch-check-action
A {github action](https://help.github.com/en/actions) to ensure that a submodule is progressing to a child of the previous version on the base branch (for a PR) and that the new submodule version is on a specific branch (optional). 

Currently, there are some limitations:
* Only supports run on pull requests, behaviors on other triggers are undefined
* Does not support submodules to private repos

## Inputs
### `path`
The path to the submodule, this is required. Do not include leading or trailing slashes.  

### `branch`
The branch that the submodule version must be on. 

This is optional, if not included the submodule will only be checked for progression, not if it is on a specific branch. 

## Outputs
### `fails`
The reason the action failed (if any). The check will stop at the first failure. 

## Usage
To add to a repo create a workflow file (such as `.github/workflows/check-submodules.yml`) with the following content:

```yml
name: check-submodule

on: [pull_request]

jobs:
  check-submodules:
    name: Check MBED Submodule
    runs-on: ubuntu-latest
    steps:
    - name: Checkout
      uses: actions/checkout@v2
    - name: Check Submodule Name
      uses: jtmullen/submodule-branch-check-action@v0.1.0
      with:
        path: "path/to/submodule"
        branch: "master"
```

You can also see [where this is used](https://github.com/search?l=YAML&q=submodule-branch-check-action&type=Code)

## TODO
- [ ] Support Private Submodules
- [ ] Have version for push trigger
