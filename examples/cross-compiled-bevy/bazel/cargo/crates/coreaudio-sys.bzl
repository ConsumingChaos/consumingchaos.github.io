""" Crate Annotation for coreaudio-sys """

load("@rules_rust//crate_universe:defs.bzl", "crate")

_ADDITIVE_BUILD_FILE_CONTENT = """
load("@//bazel/rules:directorygroup.bzl", "directorygroup")

directorygroup(
    name = "out_dir",
    srcs = {
        "@//bazel/cargo/crates/coreaudio-sys:coreaudio_sys_bindgen": "coreaudio.rs",
    }
)
"""

ANNOTATION = crate.annotation(
    additive_build_file_content = _ADDITIVE_BUILD_FILE_CONTENT,
    compile_data = [
        ":out_dir",
    ],
    deps = [
        "@//bazel/platforms/apple:AudioToolbox",
        "@//bazel/platforms/apple:AudioUnit",
        "@//bazel/platforms/apple:CoreAudio",
    ],
    rustc_env = {
        "OUT_DIR": "$(location :out_dir)",
    },
)
