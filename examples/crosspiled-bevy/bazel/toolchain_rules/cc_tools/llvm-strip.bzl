load(
    "@bazel_tools//tools/cpp:cc_toolchain_config_lib.bzl",
    "action_config",
    "flag_group",
    "flag_set",
    "tool",
)
load("@bazel_tools//tools/build_defs/cc:action_names.bzl", "ACTION_NAMES")

def strip_action_configs(binutils):
    return [action_config(
        action_name = ACTION_NAMES.strip,
        tools = [tool(path = "{}/bin/llvm-strip".format(binutils))],
        flag_sets = [
            flag_set(
                flag_groups = [
                    flag_group(
                        flags = ["-S", "-p", "-o", "%{output_file}"],
                    ),
                    flag_group(
                        iterate_over = "stripopts",
                        flags = ["%{stripopts}"],
                    ),
                    flag_group(
                        flags = ["%{input_file}"],
                    ),
                ],
            ),
        ],
    )]
