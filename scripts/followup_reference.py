"""Independent follow-up oracles over synthetic deterministic inputs."""
import collections,copy,hashlib,json,math,random,subprocess
from pathlib import Path
root=Path(__file__).resolve().parents[1]
random.seed(20261018)
def run(request, error=False):
    result=subprocess.run(['node',str(root/'_build/js/debug/build/cmd/main/main.js'),'-'],input=json.dumps(request),capture_output=True,text=True,encoding='utf-8',timeout=60)
    if error:
        assert result.returncode==1,(result.returncode,result.stdout); return
    assert result.returncode in (0,2),(result.returncode,result.stdout,result.stderr)
    return json.loads(result.stdout)

for _ in range(20):
    rows=[{'n':random.randrange(5),'kind':random.choice(['a','b']),'flag':random.choice([True,False])} for _ in range(40)]
    condition={'any':[{'all':[{'field':'n','op':'ge','value':2},{'not':{'field':'kind','value':'b'}}]},{'field':'flag','value':True}]}
    report=run({'rows':rows,'filter':condition})
    assert report['rows']==[r for r in rows if (r['n']>=2 and r['kind']!='b') or r['flag']]
    assert report['audit']['conserved']
print('Composite filtering: 20 randomized independent truth sets passed')
