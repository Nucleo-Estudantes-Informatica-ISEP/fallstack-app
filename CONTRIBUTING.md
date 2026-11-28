# Contributing

This repository follows the organisation's [contributing guide](https://github.com/Nucleo-Estudantes-Informatica-ISEP/.github/blob/main/CONTRIBUTING.md) for commits, branches, pull requests, issues, reviews and agent rules.
This file only records what is specific to this repository.

## Branch workflow

This repository uses the **dev/main** model.

- Branch from an up-to-date `dev`.
- Open the pull request into `dev`.
- Do not push directly to `dev` or `main`.
- A reviewed `dev` → `main` promotion pull request ships a release.

## Closing issues

- Link the issue in the pull request with `Closes #N`, or `Refs #N` if the pull request only partly resolves it.
- An issue is done when its pull request merges into `dev`. The `Close issues` workflow then closes every issue named with `Closes`, `Fixes` or `Resolves`. `Refs` leaves the issue open.
- GitHub closes issues from keywords on its own only when a change reaches the default branch (`main`), which is why the workflow exists. GitHub also does not fill the Development link for pull requests into `dev`. Add it by hand if you need it.
