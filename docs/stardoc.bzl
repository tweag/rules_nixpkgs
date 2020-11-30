load("@io_bazel_stardoc//stardoc:stardoc.bzl", _stardoc = "stardoc")

def stardoc(
        name,
        out,
        input,
        aspect_template = "@io_tweag_rules_nixpkgs//docs:templates/aspect.vm",
        func_template = "@io_tweag_rules_nixpkgs//docs:templates/func.vm",
        header_template = "@io_tweag_rules_nixpkgs//docs:templates/header.vm",
        provider_template = "@io_tweag_rules_nixpkgs//docs:templates/provider.vm",
        rule_template = "@io_tweag_rules_nixpkgs//docs:templates/rule.vm",
        **kwargs):
    _stardoc(
        name = name,
        out = out,
        input = input,
        aspect_template = aspect_template,
        func_template = func_template,
        header_template = header_template,
        provider_template = provider_template,
        rule_template = rule_template,
        **kwargs
    )
