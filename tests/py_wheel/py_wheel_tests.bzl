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
"""Test for py_wheel."""

load("@rules_testing//lib:analysis_test.bzl", "analysis_test", "test_suite")
load("@rules_testing//lib:truth.bzl", "matching")
load("@rules_testing//lib:util.bzl", rt_util = "util")
load("//python:packaging.bzl", "py_wheel")

_basic_tests = []
_tests = []

def _test_metadata(name):
    rt_util.helper_target(
        py_wheel,
        name = name + "_subject",
        distribution = "mydist_" + name,
        version = "0.0.0",
    )
    analysis_test(
        name = name,
        impl = _test_metadata_impl,
        target = name + "_subject",
    )

def _test_metadata_impl(env, target):
    action = env.expect.that_target(target).action_generating(
        "{package}/{name}.metadata.txt",
    )
    action.content().split("\n").contains_exactly([
        env.expect.meta.format_str("Name: mydist_{test_name}"),
        "Metadata-Version: 2.1",
        "",
    ])

_tests.append(_test_metadata)

def _test_data(name):
    rt_util.helper_target(
        py_wheel,
        name = name + "_data",
        distribution = "mydist_" + name,
        version = "0.0.0",
        data_files = {
            "source_name": "scripts/wheel_name",
        },
    )
    analysis_test(
        name = name,
        impl = _test_data_impl,
        target = name + "_data",
    )

def _test_data_impl(env, target):
    action = env.expect.that_target(target).action_named(
        "PyWheel",
    )
    action.contains_at_least_args(["--data_files", "scripts/wheel_name;tests/py_wheel/source_name"])
    action.contains_at_least_inputs(["tests/py_wheel/source_name"])

_tests.append(_test_data)

def _test_data_bad_path(name):
    rt_util.helper_target(
        py_wheel,
        name = name + "_data",
        distribution = "mydist_" + name,
        version = "0.0.0",
        data_files = {
            "source_name": "unsupported_path/wheel_name",
        },
    )
    analysis_test(
        name = name,
        impl = _test_data_bad_path_impl,
        target = name + "_data",
        expect_failure = True,
    )

def _test_data_bad_path_impl(env, target):
    env.expect.that_target(target).failures().contains_predicate(
        matching.str_matches("target data file must start with"),
    )

_tests.append(_test_data_bad_path)

def _test_data_bad_path_but_right_prefix(name):
    rt_util.helper_target(
        py_wheel,
        name = name + "_data",
        distribution = "mydist_" + name,
        version = "0.0.0",
        data_files = {
            "source_name": "scripts2/wheel_name",
        },
    )
    analysis_test(
        name = name,
        impl = _test_data_bad_path_but_right_prefix_impl,
        target = name + "_data",
        expect_failure = True,
    )

def _test_data_bad_path_but_right_prefix_impl(env, target):
    env.expect.that_target(target).failures().contains_predicate(
        matching.str_matches("target data file must start with"),
    )

_tests.append(_test_data_bad_path_but_right_prefix)

def _test_content_type_from_attr(name):
    rt_util.helper_target(
        py_wheel,
        name = name + "_subject",
        distribution = "mydist_" + name,
        version = "0.0.0",
        description_content_type = "text/x-rst",
    )
    analysis_test(
        name = name,
        impl = _test_content_type_from_attr_impl,
        target = name + "_subject",
    )

def _test_content_type_from_attr_impl(env, target):
    action = env.expect.that_target(target).action_generating(
        "{package}/{name}.metadata.txt",
    )
    action.content().split("\n").contains(
        "Description-Content-Type: text/x-rst",
    )

_tests.append(_test_content_type_from_attr)

def _test_content_type_from_description(name):
    rt_util.helper_target(
        py_wheel,
        name = name + "_subject",
        distribution = "mydist_" + name,
        version = "0.0.0",
        description_file = "desc.md",
    )
    analysis_test(
        name = name,
        impl = _test_content_type_from_description_impl,
        target = name + "_subject",
    )

def _test_content_type_from_description_impl(env, target):
    action = env.expect.that_target(target).action_generating(
        "{package}/{name}.metadata.txt",
    )
    action.content().split("\n").contains(
        "Description-Content-Type: text/markdown",
    )

_tests.append(_test_content_type_from_description)

def py_wheel_test_suite(name):
    test_suite(
        name = name,
        basic_tests = _basic_tests,
        tests = _tests,
    )
