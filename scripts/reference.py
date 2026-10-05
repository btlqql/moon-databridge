"""Independent Python standard library oracles; deterministic synthetic data."""
import csv, datetime, hashlib, heapq, io, json, math, random, subprocess
from pathlib import Path
root = Path(__file__).resolve().parents[1]
random.seed(20261005)
def run(request):
    result = subprocess.run(['node',str(root/'_build/js/debug/build/cmd/main/main.js'),'-'],
        input=json.dumps(request),capture_output=True,text=True,encoding='utf-8',timeout=30)
    if result.returncode: raise RuntimeError(result.stdout or result.stderr)
    return json.loads(result.stdout)

rows = [{'id':str(i),'text':random.choice(['x,y','a"b','line1\nline2','中文',''])} for i in range(80)]
stream = io.StringIO(newline='')
writer = csv.DictWriter(stream,fieldnames=['id','text'],lineterminator='\r\n'); writer.writeheader(); writer.writerows(rows)
result = run({'format':'csv','text':stream.getvalue(),'export_columns':['id','text']})
assert result['rows'] == rows
assert list(csv.DictReader(io.StringIO(result['csv'],newline=''))) == rows
print('Python csv oracle: 80 quoted/Unicode/multiline records and exported round trip passed')
