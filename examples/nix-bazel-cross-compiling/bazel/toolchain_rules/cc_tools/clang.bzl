load(
    "@bazel_tools//tools/cpp:cc_toolchain_config_lib.bzl",
    "action_config",
    "flag_group",
    "flag_set",
    "tool",
    "with_feature_set",
)
load("@bazel_tools//tools/build_defs/cc:action_names.bzl", "ACTION_NAMES")

BAZEL_COMPILE_FLAG_SET = flag_set(
    flag_groups = [
        flag_group(
            flags = ["-MD", "-MF", "%{dependency_file}"],
            expand_if_available = "dependency_file",
        ),
        flag_group(
            flags = ["-frandom-seed=%{output_file}"],
            expand_if_available = "output_file",
        ),
        flag_group(
            flags = ["-D%{preprocessor_defines}"],
            iterate_over = "preprocessor_defines",
        ),
        flag_group(
            flags = ["-include", "%{includes}"],
            iterate_over = "includes",
            expand_if_available = "includes",
        ),
        flag_group(
            flags = ["-iquote", "%{quote_include_paths}"],
            iterate_over = "quote_include_paths",
        ),
        flag_group(
            flags = ["-I%{include_paths}"],
            iterate_over = "include_paths",
        ),
        flag_group(
            flags = ["-isystem", "%{system_include_paths}"],
            iterate_over = "system_include_paths",
        ),
        flag_group(
            flags = ["-isystem", "%{external_include_paths}"],
            iterate_over = "external_include_paths",
            expand_if_available = "external_include_paths",
        ),
        flag_group(
            flags = ["%{user_compile_flags}"],
            iterate_over = "user_compile_flags",
            expand_if_available = "user_compile_flags",
        ),
        flag_group(
            flags = ["-c", "%{source_file}"],
            expand_if_available = "source_file",
        ),
        flag_group(
            flags = ["-o", "%{output_file}"],
            expand_if_available = "output_file",
        ),
    ],
)

def compile_action_configs(
        clang,
        target,
        builtin_include_directories,
        builtin_framework_directories,
        compile_flags,
        dbg_compile_flags,
        fastbuild_compile_flags,
        opt_compile_flags,
        remap_path_prefix):
    builtin_include_directory_compile_flags = []
    for builtin_include_directory in builtin_include_directories:
        builtin_include_directory_compile_flags += ["-isystem", builtin_include_directory]

    builtin_framework_directory_compile_flags = []
    for builtin_framework_directory in builtin_framework_directories:
        builtin_framework_directory_compile_flags += ["-iframework", builtin_framework_directory]

    required_compile_flags = ([
                                  "--target={}".format(target),
                                  "-nostdinc",

                                  # `unix_cc_toolchain_config`
                                  "-Wno-builtin-macro-redefined",
                                  "-D__DATE__=\"redacted\"",
                                  "-D__TIMESTAMP__=\"redacted\"",
                                  "-D__TIME__=\"redacted\"",
                                  "-fdebug-prefix-map=${{pwd}}={}".format(remap_path_prefix),
                              ] +
                              builtin_include_directory_compile_flags +
                              builtin_framework_directory_compile_flags)
    required_compile_flag_set = flag_set(
        flag_groups = ([
            flag_group(flags = required_compile_flags),
        ] if required_compile_flags else []),
    )

    compile_flag_set = flag_set(
        flag_groups = ([
            flag_group(flags = compile_flags),
        ] if compile_flags else []),
    )

    dbg_compile_flag_set = flag_set(
        flag_groups = ([
            flag_group(flags = dbg_compile_flags),
        ] if dbg_compile_flags else []),
        with_features = [with_feature_set(features = ["dbg"])],
    )

    fastbuild_compile_flag_set = flag_set(
        flag_groups = ([
            flag_group(flags = fastbuild_compile_flags),
        ] if fastbuild_compile_flags else []),
        with_features = [with_feature_set(features = ["fastbuild"])],
    )

    opt_compile_flag_set = flag_set(
        flag_groups = ([
            flag_group(flags = opt_compile_flags),
        ] if opt_compile_flags else []),
        with_features = [with_feature_set(features = ["opt"])],
    )

    return [
        action_config(
            action_name = ACTION_NAMES.assemble,
            tools = [tool(path = "{}/bin/clang".format(clang))],
            flag_sets = [
                required_compile_flag_set,
                compile_flag_set,
                dbg_compile_flag_set,
                fastbuild_compile_flag_set,
                opt_compile_flag_set,
                BAZEL_COMPILE_FLAG_SET,
            ],
        ),
        action_config(
            action_name = ACTION_NAMES.preprocess_assemble,
            tools = [tool(path = "{}/bin/clang".format(clang))],
            flag_sets = [
                required_compile_flag_set,
                compile_flag_set,
                dbg_compile_flag_set,
                fastbuild_compile_flag_set,
                opt_compile_flag_set,
                BAZEL_COMPILE_FLAG_SET,
            ],
        ),
        action_config(
            action_name = ACTION_NAMES.c_compile,
            tools = [tool(path = "{}/bin/clang".format(clang))],
            flag_sets = [
                required_compile_flag_set,
                compile_flag_set,
                dbg_compile_flag_set,
                fastbuild_compile_flag_set,
                opt_compile_flag_set,
                BAZEL_COMPILE_FLAG_SET,
            ],
        ),
        action_config(
            action_name = ACTION_NAMES.cpp_compile,
            tools = [tool(path = "{}/bin/clang".format(clang))],
            flag_sets = [
                required_compile_flag_set,
                compile_flag_set,
                dbg_compile_flag_set,
                fastbuild_compile_flag_set,
                opt_compile_flag_set,
                BAZEL_COMPILE_FLAG_SET,
            ],
        ),
        action_config(
            action_name = ACTION_NAMES.cpp_header_parsing,
            tools = [tool(path = "{}/bin/clang".format(clang))],
            flag_sets = [
                required_compile_flag_set,
                compile_flag_set,
                dbg_compile_flag_set,
                fastbuild_compile_flag_set,
                opt_compile_flag_set,
                BAZEL_COMPILE_FLAG_SET,
            ],
        ),
    ]
