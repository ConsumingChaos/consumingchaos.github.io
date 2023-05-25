""" Crate Annotation for windows_x86_64-msvc (0.42.2) """

load("@rules_rust//crate_universe:defs.bzl", "crate")

_ADDITIVE_BUILD_FILE_CONTENT = """
cc_library(
    name = "windows_lib",
    srcs = ["lib/windows.lib"],
    linkstatic = True,
)
"""

ANNOTATION = crate.annotation(
    version = "0.42.2",
    deps = [":windows_lib"],
    additive_build_file_content = _ADDITIVE_BUILD_FILE_CONTENT,
)
