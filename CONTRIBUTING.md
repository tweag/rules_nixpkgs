# Contributing to Bazel

## Contributor License Agreement

Contributions to this project must be accompanied by a Contributor License
Agreement. You (or your employer) retain the copyright to your contribution,
this simply gives us permission to use and redistribute your contributions as
part of the project. Head over to <https://cla.developers.google.com/> to see
your current agreements on file or to sign a new one.

You generally only need to submit a CLA once, so if you've already submitted one
(even if it was for a different project), you probably don't need to do it
again.

## Contribution process

1. Explain your idea and discuss your plan with members of the team.
   The best way to do this is to create an [issue][issue-tracker] or
   comment on an existing issue.
1. Prepare a git commit with your change. Don't forget to
   add [tests][tests]. Run the existing tests with `bazel test //...`.
   Update [README.md](./README.md) if appropriate.
1. [Create a pull request](https://help.github.com/articles/creating-a-pull-request/).
   This will start the code review process. **All submissions,
   including submissions by project members, require review.**
1. You may be asked to make some changes. You'll also need to sign the
   CLA at this point, if you haven't done so already. Our continuous
   integration bots will test your change automatically on supported
   platforms. Once everything looks good, your change will be merged.

[issue-tracker]: https://github.com/tweag/rules_nixpkgs/issues
[tests]: https://github.com/tweag/rules_nixpkgs/tree/master/tests

## Setting up your development environment

Read how to [set up your development environment](https://bazel.build/contributing.html)
