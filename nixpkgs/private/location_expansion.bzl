load("@bazel_skylib//lib:paths.bzl", "paths")

def expand_location(repository_ctx, string, labels, attr = None):
    """Expand `$(location label)` to a path.

    Raises an error on unexpected occurrences of `$`.
    Use `$$` to insert a verbatim `$`.

    Attrs:
      repository_ctx: The repository rule context.
      string: string, Replace instances of `$(location )` in this string.
      labels: dict from label to path: Known label to path mappings.
      attr: string, The rule attribute to use for error reporting.

    Returns:
      The string with all instances of `$(location )` replaced by paths.
    """
    result = ""
    offset = 0

    # Step through occurrences of `$`. This is bounded by the length of the string.
    for _ in range(len(string)):
        start = string.find("$", offset)
        if start == -1:
            result += string[offset:]
            break
        else:
            result += string[offset:start]
        if start + 1 == len(string):
            fail("Unescaped '$' in location expansion at end of input", attr)
        elif string[start + 1] == "$":
            # Insert verbatim '$'.
            result += "$"
            offset = start + 2
        elif string[start + 1] == "(":
            group_start = start + 2
            group_end = string.find(")", group_start)
            if group_end == -1:
                fail("Unbalanced parentheses in location expansion for '{}'.".format(string[start:]), attr)
            group = string[group_start:group_end]
            if group.startswith("location "):
                label_str = group[len("location "):]
                label_candidates = [
                    (lbl, path)
                    for (lbl, path) in labels.items()
                    if lbl.relative(label_str) == lbl
                ]
                if len(label_candidates) == 0:
                    fail("Unknown label '{}' in location expansion for '{}'.".format(label_str, string), attr)
                elif len(label_candidates) > 1:
                    fail(
                        "Ambiguous label '{}' in location expansion for '{}'. Candidates: {}".format(
                            label_str,
                            string,
                            ", ".join([str(lbl) for lbl in label_candidates]),
                        ),
                        attr,
                    )
                location = paths.join(".", paths.relativize(
                    str(repository_ctx.path(label_candidates[0][1])),
                    str(repository_ctx.path(".")),
                ))
                result += location
            else:
                fail("Unrecognized location expansion '$({})'.".format(group), attr)
            offset = group_end + 1
        else:
            fail("Unescaped '$' in location expansion at position {} of input.".format(start), attr)
    return result
