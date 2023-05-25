def _workspace_root_impl(repository_ctx):
    repository_ctx.file(
        "BUILD.bazel",
        "",
        executable = False,
    )
    repository_ctx.file(
        "workspace_root.bzl",
        "WORKSPACE_ROOT = \"{}\"".format(repository_ctx.workspace_root),
        executable = False,
    )

    return None

_workspace_root = repository_rule(
    implementation = _workspace_root_impl,
    attrs = {},
    local = True,
    doc = "Generate `@workspace_root//:workspace_root.bzl` containing `WORKSPACE_ROOT`.",
)

def workspace_root():
    _workspace_root(name = "workspace_root")
