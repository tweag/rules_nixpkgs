load("@npm//:defs.bzl", "npm_link_all_packages")
load("@aspect_rules_js//js:defs.bzl", "js_binary", "js_run_binary", "js_test")

npm_link_all_packages(name = "node_modules")

js_binary(
    name = "hello",
    entry_point = ":hello.js",
    data = [ ":node_modules/ololog", ]
)
