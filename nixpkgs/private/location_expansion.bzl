load("@bazel_skylib//lib:paths.bzl", "paths")

def parse_expand_location(string):
    """Parse a string that might contain location expansion commands.

    Generates a list of pairs of command and argument.
    The command can have the following values:
    - `string`: argument is a string, append it to the result.
    - `location`: argument is a label, append its location to the result.

    Attrs:
      string: string, The string to parse.

    Returns:
      (result, error):
        result: The generated list of pairs of command and argument.
        error: string or None, This is set if an error occurred.
    """
    result = []
    offset = 0
    len_string = len(string)

    # Step through occurrences of `$`. This is bounded by the length of the string.
    for _ in range(len_string):
        # Find the position of the next `$`.
        position = string.find("$", offset)
        if position == -1:
            position = len_string

        # Append the in-between literal string.
        if offset < position:
            result.append(("string", string[offset:position]))

        # Terminate at the end of the string.
        if position == len_string:
            break

        # Parse the `$` command.
        if string[position:].startswith("$$"):
            # Insert verbatim '$'.
            result.append(("string", "$"))
            offset = position + 2
        elif string[position:].startswith("$("):
            # Expand a location command.
            group_start = position + 2
            group_end = string.find(")", group_start)
            if group_end == -1:
                return (None, "Unbalanced parentheses in location expansion for '{}'.".format(string[position:]))

            group = string[group_start:group_end]
            command = None
            if group.startswith("location "):
                label_str = group[len("location "):]
                command = ("location", label_str)
            else:
                return (None, "Unrecognized location expansion '$({})'.".format(group))

            result.append(command)
            offset = group_end + 1
        else:
            return (None, "Unescaped '$' in location expansion at position {} of input.".format(position))

    return (result, None)

def resolve_label(label_str, labels):
    """Find the label that corresponds to the given string.

    Attr:
      label_str: string, String representation of a label.
      labels: dict from Label to path: Known label to path mappings.

    Returns:
      (path, error):
        path: path, The path to the resolved label
        error: string or None, This is set if an error occurred.
    """
    label_candidates = [
        (lbl, path)
        for (lbl, path) in labels.items()
        if lbl.relative(label_str) == lbl
    ]

    if len(label_candidates) == 0:
        return (None, "Unknown label '{}' in location expansion.".format(label_str))
    elif len(label_candidates) > 1:
        return (None, "Ambiguous label '{}' in location expansion. Candidates: {}".format(
            label_str,
            ", ".join([str(lbl) for (lbl, _) in label_candidates]),
        ))

    return (label_candidates[0][1], None)

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
    (parsed, error) = parse_expand_location(string)
    if error != None:
        fail(error, attr)

    result = ""
    for (command, argument) in parsed:
        if command == "string":
            result += argument
        elif command == "location":
            (label, error) = resolve_label(argument, labels)
            if error != None:
                fail(error, attr)

            result += paths.join(".", paths.relativize(
                str(repository_ctx.path(label)),
                str(repository_ctx.path(".")),
            ))
        else:
            fail("Internal error: Unknown location expansion command '{}'.".format(command), attr)

    return result
