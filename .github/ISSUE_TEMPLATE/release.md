---
name: Prepare new release (for maintainers only)
title: Prepare release MAJOR.MINOR.PATCH
about: Steps to work through in order to publish a new release

---

- [ ] Read through this process in its entirety so you understand it.
- [ ] Create and checkout a new release preparation branch, named
      `release-<major>.<minor>.<patch>`.
- [ ] If the minimal Bazel version has changed:
  - [ ] update it in [the `README`][readme] and in `presubmit.yml` files from the `.bcr` folder
  - [ ] add a note about this change to the [`CHANGELOG`][changelog]
- [ ] List user facing changes in the [`CHANGELOG`][changelog] by summarising all significant
      pull requests since the last release. Specifically:
  - Add a "Highlights" section for major improvements/changes.
  - Create "Added", "Removed", "Changed" and "Fixed" sections, as necessary.
  - If relevant, add links to the corresponding PRs to the entries.
  - Look through:
    * [merged PRs](https://github.com/tweag/rules_nixpkgs/pulls?q=is:pr+base:master+merged:>2023-10-18+-author:app/github-actions+-author:app/dependabot) or
    * `git log master ^v0.x.x --oneline --merges --grep='pull request' --grep='#' | grep -v 'tweag/dependabot/github_actions/' | grep -v 'tweag/update_flake_lock_action'`
- [ ] Bump version numbers in `MODULE.bazel` and the registry, rename files
    ```
        grep '0.10.0 -r --exclude-dir=.git lists occurences of 0.10.0 in files
        find -path ./.git -prune -o -name '*0.10.0*' -print lists occurences of 0.10.0 in names
    ```
- [ ] Push the `release-<major>.<minor>.<patch>` branch and open a PR,
      go through review and merge upon success.
- [ ] Trigger the `Prepare Release` workflow
  - either via the Github UI **or**
  - run `gh workflow run -f version=<major>.<minor>.<patch> 'Prepare Release'` using the Github CLI
- [ ] Go to the [releases], open the draft release which was created to inspect it
  - Do the code snippets look valid?
  - Is there a release artifact attached to it?
  - If you're happy, publish the release... :rocket:
- [ ] Announce the new version on Twitter by asking someone with access.


[changelog]: /CHANGELOG.md
[readme]: /README.md
[releases]: https://github.com/tweag/rules_nixpkgs/releases
