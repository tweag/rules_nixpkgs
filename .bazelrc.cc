build --crosstool_top=@nixpkgs_config_cc//:toolchain
# Using toolchain resolution can lead to spurious dependencies on
# `@local_config_cc//:builtin_include_directory_paths`. This needs to be
# resolved before `--incompatible_enable_cc_toolchain_resolution` can be
# recommended for `nixpkgs_cc_configure_hermetic`.
# build --incompatible_enable_cc_toolchain_resolution

# vim: ft=conf
