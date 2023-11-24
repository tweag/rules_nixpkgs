# Bazel requires a Java runtime to run tests, so any module that contains tests
# will need Java configuration. However, not all modules should have to depend
# on rules_nixpkgs_java to provide a Java runtime, in particular the core
# module should be free of this dependency. Hence, the Java configuration
# exists in a separate configuration file.

build --java_runtime_version=nixpkgs_java_11
build --java_language_version=11
build --tool_java_runtime_version=nixpkgs_java_11
build --tool_java_language_version=11

# vim: ft=conf
