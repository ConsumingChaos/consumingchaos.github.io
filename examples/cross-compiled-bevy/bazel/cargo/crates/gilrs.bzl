""" Crate Annotation for gilrs """

load("@rules_rust//crate_universe:defs.bzl", "crate")

_ADDITIVE_BUILD_FILE_CONTENT = """
load("@//bazel/rules:directorygroup.bzl", "directorygroup")

directorygroup(
    name = "out_dir",
    srcs = {
        "SDL_GameControllerDB/gamecontrollerdb.txt": "gamecontrollerdb.txt",
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
    rustc_flags = [
        "--cfg=path_separator=\"slash\"",
    ],
)
