# Copyright 2023 The Bazel Authors. All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

"""Utility for restricting Java APIs."""

load("@rules_java//java:defs.bzl", "java_library")

# Drop in replacement for java_library that builds the library at Java language level 11.
def java_11_library(**attrs):
    javacopts = attrs.pop("javacopts", [])
    java_library(
        javacopts = javacopts + ["-source 11", "-target 11"],
        **attrs
    )

_java_language_version_8_transition = transition(
    implementation = lambda settings, attr: {
        "//command_line_option:java_language_version": "8",
    },
    inputs = [],
    outputs = ["//command_line_option:java_language_version"],
)

def _transition_java_language_8_archive_impl(ctx):
    archive_zip = ctx.files.archive_zip[0]

    outfile = ctx.actions.declare_file(ctx.label.name)

    ctx.actions.run_shell(
        inputs = [archive_zip],
        outputs = [outfile],
        command = "cp %s %s" % (archive_zip.path, outfile.path),
    )
    return [
        DefaultInfo(
            files = depset([outfile]),
        ),
    ]

_transitioned_java_8_archive = rule(
    implementation = _transition_java_language_8_archive_impl,
    attrs = {
        "archive_zip": attr.label(
            allow_files = True,
            cfg = _java_language_version_8_transition,
            mandatory = True,
        ),
    },
)

# Used to transition the zip file generated by release_archive to compile at Java language 8.
def transition_java_language_8_archive(name, archive_zip, visibility):
    _transitioned_java_8_archive(
        name = name,
        archive_zip = archive_zip,
        visibility = visibility,
    )
