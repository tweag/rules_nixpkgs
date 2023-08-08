# rules\_nixpkgs test modules

This sub-tree houses bzlmod test-modules for the rules\_nixpkgs component
modules as [recommended by the Bazel Central Registry][bcr-testing-module].

[bcr-testing-module]: https://github.com/bazelbuild/bazel-central-registry/blob/f809c03bd6665ff4cb12a1daad480be13960ea37/docs/README.md?rgh-link-date=2023-01-24T08%3A07%3A04Z#test-module

## rules\_go tests

NOTE, the rules\_go tests are split into separate workspace mode and bzlmod
mode tests. Please keep these two test cases in sync.

The reason is that the Bazel module rules\_go refers to itself as `@rules_go`,
while the Bazel workspace for rules\_go refers to itself as
`@io_bazel_rules_go`. In principle, Bazel offers to remap workspace names.
However, this would turn either the workspace or the bzlmod case into a very
unusual use-case of rules\_go, and would diminish the value of the test-case,
as it would be not cover how users would use rules\_go in either workspace or
bzlmod mode.
