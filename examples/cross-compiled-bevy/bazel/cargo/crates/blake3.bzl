""" Crate Annotation for blake3 """

load("@rules_rust//crate_universe:defs.bzl", "crate")

_ADDITIVE_BUILD_FILE_CONTENT = """
cc_library(
    name = "blake3_neon",
    srcs = [
        "c/blake3.h",
        "c/blake3_impl.h",
        "c/blake3_neon.c",
    ],
    target_compatible_with = select({
        "@platforms//cpu:aarch64": [],
        "//conditions:default": ["@platforms//:incompatible"],
    }),
)

cc_library(
    name = "blake3_sse2_sse41_avx2_assembly",
    # Always use "unix" ASM files for Clang.
    srcs = [
        "c/blake3_sse2_x86-64_unix.S",
        "c/blake3_sse41_x86-64_unix.S",
        "c/blake3_avx2_x86-64_unix.S",
    ],
    target_compatible_with = select({
        "@platforms//cpu:x86_64": [],
        "//conditions:default": ["@platforms//:incompatible"],
    }),
)

cc_library(
    name = "blake3_avx512_assembly",
    # Always use "unix" ASM files for Clang.
    srcs = [
        "c/blake3_avx512_x86-64_unix.S",
    ],
    target_compatible_with = select({
        "@platforms//cpu:x86_64": [],
        "//conditions:default": ["@platforms//:incompatible"],
    }),
)
"""

ANNOTATION = crate.annotation(
    additive_build_file_content = _ADDITIVE_BUILD_FILE_CONTENT,
    deps = crate.select([], {
        "@platforms//cpu:aarch64": [
            ":blake3_neon",
        ],
        "@platforms//cpu:x86_64": [
            ":blake3_sse2_sse41_avx2_assembly",
            ":blake3_avx512_assembly",
        ],
    }),
    rustc_flags = crate.select([], {
        "@platforms//cpu:aarch64": [
            "--cfg=blake3_neon",
        ],
        "@platforms//cpu:x86_64": [
            "--cfg=blake3_sse2_ffi",
            "--cfg=blake3_sse41_ffi",
            "--cfg=blake3_avx2_ffi",
            "--cfg=blake3_avx512_ffi",
        ],
    }),
)
