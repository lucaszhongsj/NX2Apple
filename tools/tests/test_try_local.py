"""tools/try-local: its cache key and version string, and that its Info.plist has not drifted from the workflow's."""
import hashlib
import os
import re
import subprocess
import sys
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
SCRIPT = ROOT / 'tools' / 'try-local'
WORKFLOW = ROOT / '.github' / 'workflows' / 'build-mac-app.yml'


def run(*args, env=None):
    e = {**os.environ, **env} if env else None
    return subprocess.run([str(SCRIPT), *args], capture_output=True, text=True, check=True, env=e).stdout.strip()


def plist_keys(text):
    return [re.sub(r'\$\{\{ steps\.ver\.outputs\.version \}\}', '$V', l.strip()) for l in text.splitlines() if l.strip().startswith('<key>')]


class TryLocal(unittest.TestCase):
    def display_version(self):
        """appVersion and the fork mark, read the way the script reads them."""
        text = (ROOT / 'frontend/Sources/NXModel/AppUpdateStore.swift').read_text()   # appVersion and forkMark
        src = re.search(r'static let appVersion = "(.*)"', text).group(1)
        mark = re.search(r'static let forkMark = "(.*)"', text).group(1)
        self.assertTrue(mark.startswith('-'), 'the mark separates from the release number')
        return src + mark

    def test_version_is_the_display_version_plus_local(self):
        self.assertEqual(run('--print-version'), self.display_version() + '-local')

    def test_the_version_suffix_can_be_changed(self):
        self.assertEqual(run('--print-version', env={'NX2APPLE_TRY_LOCAL_SUFFIX': 'modified'}), self.display_version() + '-modified')

    def test_cache_key_follows_the_script_and_its_pins(self):
        key = run('--print-cache-key')
        self.assertRegex(key, r'^[0-9a-f]{16}$')
        self.assertEqual(key, run('--print-cache-key'))
        h = hashlib.sha256()
        for p in ('frontend/tools/bundle_tools.sh', 'frontend/bundled-python/requirements.txt'):
            h.update((ROOT / p).read_bytes())
        h.update(subprocess.run(['uname', '-m'], capture_output=True, check=True).stdout)
        self.assertEqual(key, h.hexdigest()[:16])

    def test_info_plist_matches_the_workflow(self):
        """try-local mirrors the step 'Assemble the bundle': a key added there must be added here."""
        mine = SCRIPT.read_text().split("<<PLIST\n", 1)[1].split("\nPLIST\n", 1)[0]
        theirs = WORKFLOW.read_text().split("<<PLIST\n", 1)[1].split("\n          PLIST\n", 1)[0]
        self.assertEqual(plist_keys(mine), plist_keys(theirs))

    def test_it_never_signs_or_publishes(self):
        text = SCRIPT.read_text()
        for word in ('release_manifest.py', 'gh release', 'git tag', 'git push', 'ENGINE_SIGNING_KEY'):
            self.assertNotIn(word, re.sub(r'(?m)^#.*$', '', text))


if __name__ == '__main__':
    unittest.main()
