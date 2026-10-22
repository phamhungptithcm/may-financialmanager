"""Self-contained fixtures; does NOT audit the real owner's FigJam or prototype."""
import base64
import importlib.util
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import unittest

KIT=Path(__file__).resolve().parents[1]
PNG=base64.b64decode('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+jR5gAAAAASUVORK5CYII=')

class ReferenceGuardTests(unittest.TestCase):
    def setUp(self):
        self.temp=tempfile.TemporaryDirectory()
        self.root=Path(self.temp.name)/'May';self.root.mkdir()
        for rel in ('scripts/reference_preflight.py','scripts/register_flow_export.py','.claude/hooks/pre_tool_guard.py'):
            f=self.root/rel;f.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(KIT/rel,f)
        module_file=self.root/'scripts/reference_preflight.py'
        spec=importlib.util.spec_from_file_location('preflight_test_fixture',module_file)
        module=importlib.util.module_from_spec(spec);spec.loader.exec_module(module)
        docs=self.root/'docs'
        for rel in module.REQUIRED:
            f=docs/rel;f.parent.mkdir(parents=True,exist_ok=True);f.write_text('required spec fixture','utf8')
        (docs/'schemas').mkdir()
        (docs/'schemas/test.schema.json').write_text('{}','utf8')
        (docs/'FamilyClanMockupFullFlow.html').write_text('<html><body>Finance budget and income</body></html>','utf8')
        (docs/'Family Finance — End-to-end UX Flow.jam').write_bytes(b'original FigJam bytes')
        (docs/'qa/design-references').mkdir(exist_ok=True)
    def tearDown(self): self.temp.cleanup()
    def run_preflight(self,*args):
        return subprocess.run([sys.executable,str(self.root/'scripts/reference_preflight.py'),'--strict',*args],cwd=self.root,text=True,capture_output=True)
    def export(self):
        exp=self.root/'docs/qa/design-references/ux-flow.png';exp.write_bytes(PNG)
        proc=subprocess.run([sys.executable,str(self.root/'scripts/register_flow_export.py'),'--export',str(exp)],cwd=self.root,capture_output=True,text=True)
        self.assertEqual(proc.returncode,0,proc.stderr)
        return self.root/'docs/qa/design-references/flow-export-manifest.json'
    def approve(self,manifest):
        obj=json.loads(manifest.read_text())
        obj.update(review_status='APPROVED',reviewer='fixture reviewer',reviewed_at='2026-10-21')
        manifest.write_text(json.dumps(obj),'utf8')
    def test_originals_present(self):
        self.assertEqual(self.run_preflight().returncode,0)
        self.assertEqual(self.run_preflight('--require-flow-export').returncode,2)
    def test_export_must_be_approved(self):
        mf=self.export()
        self.assertEqual(json.loads(mf.read_text())['review_status'],'PENDING_REVIEW')
        self.assertEqual(self.run_preflight('--require-flow-export').returncode,2)
        self.approve(mf)
        self.assertEqual(self.run_preflight('--require-flow-export').returncode,0)
    def test_lock_invalidates_on_source_change(self):
        mf=self.export();self.approve(mf)
        self.assertEqual(self.run_preflight('--require-flow-export','--write-lock').returncode,0)
        self.assertEqual(self.run_preflight('--require-flow-export','--lock-check').returncode,0)
        (self.root/'docs/Family Finance — End-to-end UX Flow.jam').write_bytes(b'new source')
        self.assertEqual(self.run_preflight('--require-flow-export','--lock-check').returncode,2)
    def test_hook_protects_original(self):
        obj={'tool_name':'Edit','tool_input':{'file_path':str(self.root/'docs/FamilyClanMockupFullFlow.html')}}
        env={**os.environ,'CLAUDE_PROJECT_DIR':str(self.root)}
        p=subprocess.run([sys.executable,str(self.root/'.claude/hooks/pre_tool_guard.py')],input=json.dumps(obj),text=True,capture_output=True,env=env)
        self.assertEqual(json.loads(p.stdout)['hookSpecificOutput']['permissionDecision'],'deny')
    def test_jam_not_decoded_as_png(self):
        obj=json.loads(self.run_preflight('--json').stdout)
        self.assertEqual(obj['references']['figjam']['path'],'docs/Family Finance — End-to-end UX Flow.jam')
        self.assertTrue(obj['ok'])

if __name__=='__main__':unittest.main()
