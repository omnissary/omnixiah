import json
from pathlib import Path
import runpy
import sys
import tempfile
import unittest
from unittest.mock import patch


build = runpy.run_path(sys.argv.pop(1))


class OverridesTest(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)

    def write(self, name, value):
        (self.root / name).write_text(json.dumps(value))

    def node(self, url, **extra):
        return {"original": {"url": url}, "locked": {"rev": "abc123"}, **extra}

    def test_absent_and_empty_config_need_no_lock(self):
        self.assertEqual(build["override_args"](self.root), [])
        self.write(".input-overrides.json", {})
        self.assertEqual(build["override_args"](self.root), [])

    def test_graph(self):
        self.write(".input-overrides.json", {"git.tatikoma.dev": "github:omnissary"})
        self.write("flake.lock", {"root": "root", "nodes": {
            "root": {"inputs": {"alias": "parent", "other": "other", "follow": ["alias"]}},
            "parent": self.node(
                "https://git.tatikoma.dev/user/actual-name/archive/branch.tar.gz",
                inputs={"child": "child", "root": [], "self": "parent"}),
            "child": self.node("ssh://git@git.tatikoma.dev:2222/team/child.git", flake=False),
            "other": self.node("https://elsewhere.test/team/parent", inputs={"shared": "child"}),
        }})
        before = (self.root / "flake.lock").read_bytes()
        self.assertEqual(build["override_args"](self.root), [
            "--no-write-lock-file",
            "--override-input", "alias", "github:omnissary/actual-name/abc123",
            "--override-input", "alias/child", "github:omnissary/child/abc123",
            "--override-input", "other/shared", "github:omnissary/child/abc123",
        ])
        self.assertEqual((self.root / "flake.lock").read_bytes(), before)

    def test_api_url_and_subdirectory(self):
        self.write(".input-overrides.json", {"git.tatikoma.dev": "github:omnissary"})
        node = self.node("https://git.tatikoma.dev/api/v1/repos/user/repo/archive/abc123.tar.gz")
        node["original"]["dir"] = "sub dir"
        self.write("flake.lock", {"root": "root", "nodes": {
            "root": {"inputs": {"repo": "repo"}}, "repo": node,
        }})
        self.assertEqual(build["override_args"](self.root)[-1],
                         "github:omnissary/repo/abc123?dir=sub+dir")
        del node["locked"]["rev"]
        self.write("flake.lock", {"root": "root", "nodes": {
            "root": {"inputs": {"repo": "repo"}}, "repo": node,
        }})
        with self.assertRaisesRegex(ValueError, "no locked Git revision"):
            build["override_args"](self.root)

    def test_invalid_config(self):
        for value in ([], {"git.tatikoma.dev": "https://github.com/omnissary"}):
            self.write(".input-overrides.json", value)
            with self.assertRaises(ValueError):
                build["override_args"](self.root)

    def test_build_command(self):
        overrides = ["--no-write-lock-file", "--override-input", "a/b", "github:omnissary/b/rev"]
        scope = build["main"].__globals__
        for args in ([], ["--dry-run"], [".#one", ".#two", "--no-link"],
                     ["--option", "key", "value with spaces"], ["--", ".#microvm"]):
            with self.subTest(args=args), \
                 patch.dict(scope, {"override_args": lambda root: overrides}), \
                 patch.object(sys, "argv", ["build", *args]), \
                 patch("os.chdir"), patch("os.execvp") as execute:
                build["main"]()
            execute.assert_called_once_with("nix", ["nix", "build", *overrides, *args])


unittest.main()
