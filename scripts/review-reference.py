"""Independent Python sorting and typed-scaling regression oracle."""
import json,random,subprocess
from pathlib import Path
root=Path(__file__).resolve().parents[1]
def run(request):
 r=subprocess.run(['node',str(root/'_build/js/debug/build/cmd/main/main.js'),'-'],input=json.dumps(request),capture_output=True,text=True,encoding='utf8',timeout=30)
 assert r.returncode==0,r.stdout+r.stderr
 return json.loads(r.stdout)
rng=random.Random(20261022)
for i in range(20):
 values=[''.join(rng.choice('abc中') for _ in range(rng.randint(1,6))) for _ in range(25)]
 report=run({'rows':[{'s':v} for v in values],'sort':'s'})
 assert [row['s'] for row in report['rows']]==sorted(values)
 nums=[rng.randint(-10,10) for _ in range(25)]
 report=run({'rows':[{'n':v} for v in nums],'columns':[{'source':'n','type':'integer','scale':.5}]})
 expected=[{'n':v/2} for v in nums if v%2==0]
 assert report['rows']==expected
 assert report['audit']['rejected']==len(nums)-len(expected)
 assert report['audit']['conserved']
print(json.dumps({'seed':20261022,'pipelines':40,'checked_rows':1000}))
