load(
    "@nix_config//:config.bzl",
    "CLANG_LIB",
    "CLANG_LIB_VERSION",
    "SDK_UNIVERSAL_APPLE_DARWIN",
    "SDK_UNIVERSAL_APPLE_IOS",
)
load("@rules_rust//rust:defs.bzl", "rust_library")
load("@workspace_root//:workspace_root.bzl", "WORKSPACE_ROOT")

# Copied from toolchains.
_CLANG_TOOLCHAIN_FLAGS = select({
    "@rules_rust//rust/platform:aarch64-apple-darwin": [
        "--target=aarch64-apple-darwin",
        "--sysroot={}".format(SDK_UNIVERSAL_APPLE_DARWIN),
        "-isystem",
        "{}/usr/include/c++/v1".format(SDK_UNIVERSAL_APPLE_DARWIN),
        "-isystem",
        "{}/lib/clang/{}/include".format(CLANG_LIB, CLANG_LIB_VERSION),
        "-isystem",
        "{}/usr/include".format(SDK_UNIVERSAL_APPLE_DARWIN),
        "-iframework",
        "{}/System/Library/Frameworks".format(SDK_UNIVERSAL_APPLE_DARWIN),
    ],
    "@rules_rust//rust/platform:aarch64-apple-ios": [
        "--target=aarch64-apple-ios",
        "--sysroot={}".format(SDK_UNIVERSAL_APPLE_IOS),
        "-isystem",
        "{}/usr/include/c++/v1".format(SDK_UNIVERSAL_APPLE_IOS),
        "-isystem",
        "{}/lib/clang/{}/include".format(CLANG_LIB, CLANG_LIB_VERSION),
        "-isystem",
        "{}/usr/include".format(SDK_UNIVERSAL_APPLE_IOS),
        "-iframework",
        "{}/System/Library/Frameworks".format(SDK_UNIVERSAL_APPLE_IOS),
    ],
    "@rules_rust//rust/platform:x86_64-apple-darwin": [
        "--target=x86_64-apple-darwin",
        "--sysroot={}".format(SDK_UNIVERSAL_APPLE_DARWIN),
        "-isystem",
        "{}/usr/include/c++/v1".format(SDK_UNIVERSAL_APPLE_DARWIN),
        "-isystem",
        "{}/lib/clang/{}/include".format(CLANG_LIB, CLANG_LIB_VERSION),
        "-isystem",
        "{}/usr/include".format(SDK_UNIVERSAL_APPLE_DARWIN),
        "-iframework",
        "{}/System/Library/Frameworks".format(SDK_UNIVERSAL_APPLE_DARWIN),
    ],
})

def _rust_bindgen_impl(ctx):
    bindgen = ctx.actions.declare_file("{}.rs".format(ctx.attr.out_name))

    args = ctx.actions.args()
    args.add_all([
        "--rustfmt-configuration-file",
        "{}/{}".format(WORKSPACE_ROOT, ctx.file._rustfmt_config.path),
        "--output",
        bindgen,
        ctx.file.header,
    ])
    args.add_all(ctx.attr.bindgen_flags if ctx.attr.bindgen_flags else [])
    args.add("--")  # Clang options
    args.add_all(ctx.attr.clang_toolchain_flags)
    args.add_all(ctx.attr.clang_flags if ctx.attr.clang_flags else [])

    env = {
        "LIBCLANG_PATH": "{}/lib".format(CLANG_LIB),
        "RUSTFMT": ctx.executable._rustfmt.path,
    }

    ctx.actions.run(
        outputs = [bindgen],
        inputs = [
            ctx.file.header,
            ctx.file._rustfmt_config,
        ],
        executable = ctx.executable._rust_bindgen,
        tools = [
            ctx.executable._rustfmt,
        ],
        arguments = [args],
        env = env,
        mnemonic = "RustBindgen",
        progress_message = "Generating bindings for {}...".format(ctx.file.header.path),
    )
    return DefaultInfo(files = depset([bindgen]))

_rust_bindgen = rule(
    implementation = _rust_bindgen_impl,
    attrs = {
        "header": attr.label(
            allow_single_file = [".h"],
            mandatory = True,
        ),
        "out_name": attr.string(
            mandatory = True,
        ),
        "bindgen_flags": attr.string_list(),
        "clang_flags": attr.string_list(),
        "clang_toolchain_flags": attr.string_list(),
        "_rust_bindgen": attr.label(
            default = "@nix_utils//:bin/bindgen",
            allow_single_file = True,
            executable = True,
            cfg = "exec",
        ),
        "_rustfmt": attr.label(
            default = "@nix_rust//:rustfmt",
            executable = True,
            cfg = "exec",
        ),
        "_rustfmt_config": attr.label(
            default = "//:.rustfmt.toml",
            allow_single_file = True,
        ),
    },
)

def rust_bindgen(name, header, out_name = None, bindgen_flags = None, clang_flags = None, target_compatible_with = []):
    _rust_bindgen(
        name = name,
        header = header,
        out_name = out_name or name,
        bindgen_flags = bindgen_flags,
        clang_flags = clang_flags,
        clang_toolchain_flags = _CLANG_TOOLCHAIN_FLAGS,
        target_compatible_with = target_compatible_with,
        tags = ["manual"],
    )

def rust_bindgen_library(name, header, out_name = None, bindgen_flags = None, clang_flags = None, target_compatible_with = [], **kwargs):
    tags = kwargs.get("tags") or []
    if "tags" in kwargs:
        kwargs.pop("tags")

    rust_bindgen(
        name = "{}_bindgen".format(name),
        header = header,
        out_name = out_name,
        bindgen_flags = bindgen_flags,
        clang_flags = clang_flags,
        target_compatible_with = target_compatible_with,
    )

    rust_library(
        name = name,
        srcs = [":{}_bindgen".format(name)],
        tags = tags + ["__bindgen", "noclippy"],
        target_compatible_with = target_compatible_with,
        **kwargs
    )
