"""Unit tests for the hub repository registry.
"""

load("@bazel_skylib//lib:unittest.bzl", "asserts", "unittest")
load("@rules_nixpkgs_core//private:module_registry.bzl", "registry")

def _add_module_test_impl(ctx):
    env = unittest.begin(ctx)

    r = registry.make()
    key, err = registry.add_module(r, name = "test_module", version = "1.0.0")
    asserts.equals(env, expected = None, actual = err, msg = "No error expected.")

    _, err = registry.add_module(r, name = "test_module", version = "1.2.0")
    asserts.equals(env, expected = "Duplicate module 'test_module 1.2.0', previous version '1.0.0'.", actual = err, msg = "Duplicate module error expected.")

    return unittest.end(env)

_add_module_test = unittest.make(_add_module_test_impl)

def _global_repo_test_impl(ctx):
    env = unittest.begin(ctx)

    r = registry.make()
    key, err = registry.add_module(r, name = "test_module", version = "1.0.0")
    asserts.equals(env, expected = None, actual = err, msg = "No error expected.")

    _, err = registry.add_global_repo(r, name = "global_repo", repo = "repo")
    asserts.equals(env, expected = None, actual = err, msg = "No error expected.")

    has_global_repo = registry.has_global_repo(r, name = "global_repo")
    asserts.true(env, has_global_repo, msg = "Global repo should exist.")

    global_repo = registry.get_global_repo(r, name = "global_repo")
    asserts.equals(env, expected = "repo", actual = global_repo, msg = "Unexpected repo value returned.")

    _, err = registry.add_global_repo(r, name = "global_repo", repo = "another_repo")
    asserts.equals(env, expected = "Duplicate global repository 'global_repo'.", actual = err, msg = "Duplicate global repo error expected.")

    global_repo = registry.get_global_repo(r, name = "global_repo")
    asserts.equals(env, expected = "repo", actual = global_repo, msg = "Unexpected repo value returned.")

    return unittest.end(env)

_global_repo_test = unittest.make(_global_repo_test_impl)

def _local_repo_test_impl(ctx):
    env = unittest.begin(ctx)

    r = registry.make()
    key, err = registry.add_module(r, name = "test_module", version = "1.0.0")
    asserts.equals(env, expected = None, actual = err, msg = "No error expected.")

    _, err = registry.add_local_repo(r, key = key, name = "local_repo", repo = "repo")
    asserts.equals(env, expected = None, actual = err, msg = "No error expected.")

    _, err = registry.add_local_repo(r, key = key, name = "local_repo", repo = "repo")
    asserts.equals(env, expected = "Duplicate local repository 'local_repo', requested by module 'test_module 1.0.0'.", actual = err, msg = "Duplicate local repo error expected.")

    repo, err = registry.pop_local_repo(r, key = key, name = "local_repo")
    asserts.equals(env, expected = None, actual = err, msg = "No error expected.")
    asserts.equals(env, expected = "repo", actual = repo, msg = "Unexpected repo value returned.")

    _, err = registry.pop_local_repo(r, key = key, name = "local_repo")
    asserts.equals(env, expected = "Local repository 'local_repo' not found, requested by module 'test_module 1.0.0'.", actual = err, msg = "Local repo not found error expected.")

    return unittest.end(env)

_local_repo_test = unittest.make(_local_repo_test_impl)

def _use_global_repo_test_impl(ctx):
    env = unittest.begin(ctx)

    r = registry.make()
    key, err = registry.add_module(r, name = "test_module", version = "1.0.0")
    asserts.equals(env, expected = None, actual = err, msg = "No error expected.")

    _, err = registry.use_global_repo(r, key = key, name = "global_repo")
    asserts.equals(env, expected = None, actual = err, msg = "No error expected.")

    _, err = registry.use_global_repo(r, key = "nonexistent_key", name = "global_repo")
    asserts.equals(env, expected = "Module not found: 'nonexistent_key'.", actual = err, msg = "Module not found error expected.")

    return unittest.end(env)

_use_global_repo_test = unittest.make(_use_global_repo_test_impl)

def _set_default_global_repo_test_impl(ctx):
    env = unittest.begin(ctx)

    r = registry.make()
    key, err = registry.add_module(r, name = "test_module", version = "1.0.0")
    asserts.equals(env, expected = None, actual = err, msg = "No error expected.")

    registry.set_default_global_repo(r, name = "default_global_repo", repo = "repo")

    registry.set_default_global_repo(r, name = "default_global_repo", repo = "another_repo")

    global_repo = registry.get_global_repo(r, name = "default_global_repo")
    asserts.equals(env, expected = "repo", actual = global_repo, msg = "Unexpected global default repo value returned.")

    return unittest.end(env)

_set_default_global_repo_test = unittest.make(_set_default_global_repo_test_impl)

def _get_all_repositories_test_impl(ctx):
    env = unittest.begin(ctx)

    r = registry.make()

    key, err = registry.add_module(r, name = "test_module", version = "1.0.0")
    asserts.equals(env, expected = None, actual = err, msg = "No error expected when adding module.")

    _, err = registry.add_local_repo(r, key = key, name = "local_repo", repo = "local_repo_obj")
    asserts.equals(env, expected = None, actual = err, msg = "No error expected when adding local_repo.")

    _, err = registry.add_global_repo(r, name = "global_repo", repo = "global_repo_obj")
    asserts.equals(env, expected = None, actual = err, msg = "No error expected when adding global_repo.")

    all_repositories = registry.get_all_repositories(r)
    expected_repositories = {
        "global_repo": "global_repo_obj",
        "test_module_1.0.0_local_repo": "local_repo_obj",
    }
    asserts.equals(env, expected = expected_repositories, actual = all_repositories, msg = "Unexpected repositories returned.")

    return unittest.end(env)

_get_all_repositories_test = unittest.make(_get_all_repositories_test_impl)

def _get_all_module_scopes_test_impl(ctx):
    env = unittest.begin(ctx)

    r = registry.make()
    key1, err = registry.add_module(r, name = "test_module1", version = "1.0.0")
    asserts.equals(env, expected = None, actual = err, msg = "No error expected.")

    key2, err = registry.add_module(r, name = "test_module2", version = "2.0.0")
    asserts.equals(env, expected = None, actual = err, msg = "No error expected.")

    # Use global repositories before they are added
    _, err = registry.use_global_repo(r, key = key1, name = "global_repo1")
    asserts.equals(env, expected = None, actual = err, msg = "No error expected.")
    _, err = registry.use_global_repo(r, key = key2, name = "global_repo2")
    asserts.equals(env, expected = None, actual = err, msg = "No error expected.")

    # Add one global repository
    _, err = registry.add_global_repo(r, name = "global_repo1", repo = "global_repo1_obj")
    asserts.equals(env, expected = None, actual = err, msg = "No error expected.")

    # Test with unregistered global repository
    scopes, err = registry.get_all_module_scopes(r)
    asserts.equals(env, expected = "Global repository 'global_repo2' not registered, requested by module 'test_module2 2.0.0'.", actual = err, msg = "Global repository not registered error expected.")

    # Add the other global repository
    _, err = registry.add_global_repo(r, name = "global_repo2", repo = "global_repo2_obj")
    asserts.equals(env, expected = None, actual = err, msg = "No error expected.")

    # Add local repositories
    _, err = registry.add_local_repo(r, key = key1, name = "local_repo1", repo = "local_repo1_obj")
    asserts.equals(env, expected = None, actual = err, msg = "No error expected.")
    _, err = registry.add_local_repo(r, key = key2, name = "local_repo2", repo = "local_repo2_obj")
    asserts.equals(env, expected = None, actual = err, msg = "No error expected.")

    scopes, err = registry.get_all_module_scopes(r)
    asserts.equals(env, expected = None, actual = err, msg = "No error expected.")
    expected_scopes = {
        key1: {
            "global_repo1": "global_repo1",
            "local_repo1": "test_module1_1.0.0_local_repo1",
        },
        key2: {
            "global_repo2": "global_repo2",
            "local_repo2": "test_module2_2.0.0_local_repo2",
        },
    }
    asserts.equals(env, expected = expected_scopes, actual = scopes, msg = "Scopes do not match expected value.")

    return unittest.end(env)

_get_all_module_scopes_test = unittest.make(_get_all_module_scopes_test_impl)

def module_registry_test_suite(name):
    unittest.suite(
        name,
        _add_module_test,
        _global_repo_test,
        _local_repo_test,
        _use_global_repo_test,
        _set_default_global_repo_test,
        _get_all_repositories_test,
        _get_all_module_scopes_test,
    )
