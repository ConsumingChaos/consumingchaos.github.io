""" Crate Annotation for x11-dl """

load("@rules_rust//crate_universe:defs.bzl", "crate")

_ADDITIVE_BUILD_FILE_CONTENT = """
load("@//bazel/rules:directorygroup.bzl", "directorygroup")

directorygroup(
    name = "out_dir",
    srcs = {
        "@//bazel/cargo/crates/x11-dl:config.rs": "config.rs",
    }
)
"""

ANNOTATION = crate.annotation(
    additive_build_file_content = _ADDITIVE_BUILD_FILE_CONTENT,
    compile_data = [
        ":out_dir",
    ],
    rustc_env = {
        "OUT_DIR": "$(location :out_dir)",
    },
)
