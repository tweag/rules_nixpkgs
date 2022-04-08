load("@bazel_skylib//lib:unittest.bzl", "asserts", "unittest")
load(
    "@rules_nixpkgs_core//:util.bzl",
    "parse_expand_location",
    "resolve_label",
)

def _parse_expand_location_test(ctx):
    env = unittest.begin(ctx)

    asserts.equals(
        env,
        expected = ([], None),
        actual = parse_expand_location(""),
        msg = "Parses the empty string",
    )

    asserts.equals(
        env,
        expected = ([("string", "plain string")], None),
        actual = parse_expand_location("plain string"),
        msg = "Parses a plain string",
    )

    asserts.equals(
        env,
        expected = ([("string", "$")], None),
        actual = parse_expand_location("$$"),
        msg = "Parses an escaped dollar sign",
    )

    asserts.equals(
        env,
        expected = ([("location", "@workspace//package:target")], None),
        actual = parse_expand_location("$(location @workspace//package:target)"),
        msg = "Parses a location command",
    )

    asserts.equals(
        env,
        expected = ([
            ("string", "before "),
            ("location", "//label:1"),
            ("string", " "),
            ("string", "$"),
            ("string", " "),
            ("location", "//label:2"),
            ("string", " after"),
        ], None),
        actual = parse_expand_location(
            "before $(location //label:1) $$ $(location //label:2) after",
        ),
        msg = "Parses a complex location expansion string",
    )

    asserts.equals(
        env,
        expected = (None, "Unescaped '$' in location expansion at position 0 of input."),
        actual = parse_expand_location("$"),
        msg = "Fails on unescaped dollar sign",
    )

    asserts.equals(
        env,
        expected = (None, "Unbalanced parentheses in location expansion for '$(location //label:1'."),
        actual = parse_expand_location("$(location //label:1"),
        msg = "Fails on unbalanced parentheses",
    )

    asserts.equals(
        env,
        expected = (None, "Unrecognized location expansion '$(misspelled)'."),
        actual = parse_expand_location("$(misspelled)"),
        msg = "Fails on unknown location expansion command",
    )

    return unittest.end(env)

parse_expand_location_test = unittest.make(_parse_expand_location_test)

def _resolve_label_test(ctx):
    env = unittest.begin(ctx)

    asserts.equals(
        env,
        expected = ("correct/path", None),
        actual = resolve_label(
            "@workspace//package:target",
            {
                Label("@workspace//package:target"): "correct/path",
                Label("@another//package:target"): "wrong/path",
            },
        ),
        msg = "Finds an absolute label",
    )

    asserts.equals(
        env,
        expected = ("correct/path", None),
        actual = resolve_label(
            "//package:target",
            {
                Label("@workspace//package:target"): "correct/path",
                Label("@another//different:target"): "wrong/path",
            },
        ),
        msg = "Finds an unambiguous relative label",
    )

    asserts.equals(
        env,
        expected = (None, "Unknown label '@unknown//package:target' in location expansion."),
        actual = resolve_label(
            "@unknown//package:target",
            {
                Label("@workspace//package:target"): "wrong/path",
                Label("@another//package:target"): "another/wrong/path",
            },
        ),
        msg = "Fails on an unknown label",
    )

    asserts.equals(
        env,
        expected = (None, "Ambiguous label '//package:target' in location expansion. Candidates: @workspace//package:target, @another//package:target"),
        actual = resolve_label(
            "//package:target",
            {
                Label("@workspace//package:target"): "wrong/path",
                Label("@another//package:target"): "another/wrong/path",
            },
        ),
        msg = "Fails on an ambiguous relative label",
    )

    return unittest.end(env)

resolve_label_test = unittest.make(_resolve_label_test)

def expand_location_unit_test_suite():
    unittest.suite(
        "expand_location_unit_test_suite",
        parse_expand_location_test,
        resolve_label_test,
    )
