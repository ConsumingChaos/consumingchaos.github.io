_COMMAND = """
OUT="$1"
shift

mkdir --parents "$OUT"
while [ $# -ne 0 ]; do
    mkdir --parents "$OUT/$(dirname "$2")"
    ln --symbolic "$(realpath $1)" "$OUT/$2"
    shift 2
done
"""

def _directorygroup_impl(ctx):
    directory = ctx.actions.declare_directory(ctx.attr.name)

    args = ctx.actions.args()
    args.add(directory.path)
    for target, path in ctx.attr.srcs.items():
        files = target.files.to_list()
        if len(files) != 1:
            fail(msg = "Unexpected number of files in target {}: {}".format(target, len(files)))
        args.add(files[0])
        args.add(path)

    ctx.actions.run_shell(
        inputs = ctx.files.srcs,
        outputs = [directory],
        arguments = [args],
        command = _COMMAND,
    )
    return DefaultInfo(files = depset([directory]))

directorygroup = rule(
    implementation = _directorygroup_impl,
    attrs = {
        "srcs": attr.label_keyed_string_dict(
            allow_files = True,
        ),
    },
)
