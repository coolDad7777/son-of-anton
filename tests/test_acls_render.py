"""Render salt/samba/acls.sls and lock the ownership contract.

Dataset roots must be owned by the matching Samba user (mode 0755, no
recursion) and must not be applied before the ZFS dataset exists.
"""

import pathlib
import unittest

import yaml
from jinja2 import Environment, FileSystemLoader, StrictUndefined


ROOT = pathlib.Path(__file__).resolve().parents[1]


def _args(spec):
    """Flatten Salt's list-of-single-key-dicts state arguments."""
    merged = {}
    for item in spec:
        merged.update(item)
    return merged


def render(pillar):
    env = Environment(
        loader=FileSystemLoader(str(ROOT)),
        undefined=StrictUndefined,
        keep_trailing_newline=True,
    )
    text = env.get_template("salt/samba/acls.sls").render(pillar=pillar)
    parsed = yaml.safe_load(text) or {}
    states = {sid: _args(body["file.directory"]) for sid, body in parsed.items()}
    return text, states


PILLAR = {
    "zfs": {"datasets": {"tank": ["photos", "docs"]}},
    "samba": {
        "shares": [
            {"name": "photos", "path": "/tank/photos/", "valid_users": "alice"},
            {"name": "bad", "path": "/tank/docs", "valid_users": ["alice", "bob"]},
        ]
    },
}


class AclRenderTest(unittest.TestCase):
    def setUp(self):
        self.text, self.states = render(PILLAR)

    def test_share_user_owns_dataset_root_without_recursion(self):
        spec = self.states["tank_photos_ownership"]
        self.assertEqual(spec["name"], "/tank/photos")
        self.assertEqual(spec["user"], "alice")
        self.assertEqual(spec["group"], "alice")
        self.assertEqual(str(spec["mode"]), "0755")
        self.assertNotIn("recurse", spec)
        self.assertNotIn("recurse:", self.text)
        self.assertIn({"cmd": "ensure_tank_photos"}, spec["require"])
        self.assertIn({"user": "samba_user_alice"}, spec["require"])

    def test_non_string_owner_stays_root_and_waits_for_dataset(self):
        spec = self.states["tank_docs_ownership"]
        self.assertEqual(spec["user"], "root")
        self.assertEqual(spec["group"], "root")
        self.assertNotIn("recurse", spec)
        self.assertEqual(spec["require"], [{"cmd": "ensure_tank_docs"}])
        self.assertNotIn("samba_user_alice", self.text.split("tank_docs_ownership")[1])

    def test_no_datasets_renders_no_states(self):
        text, states = render({"zfs": {"datasets": {}}, "samba": {"shares": []}})
        self.assertEqual(text.strip(), "")
        self.assertEqual(states, {})


if __name__ == "__main__":
    unittest.main()
