def is_bzlmod_enabled():
    """Returns True if bzlmod is enabled."""
    # Labels are only canonicalized (@@ prefix) if bzlmod is enabled.
    return str(Label("@//:BUILD.bazel")).startswith("@@")
