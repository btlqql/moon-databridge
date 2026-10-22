"""Read public GitHub data; no stored tokens, mutation or private credentials required."""
import argparse,datetime,json,urllib.request
parser=argparse.ArgumentParser();parser.add_argument('--since',default='2026-09-01T00:00:00Z');args=parser.parse_args()
def fetch(path):
    request=urllib.request.Request('https://api.github.com/repos/btlqql/moon-databridge'+path,headers={'User-Agent':'databridge-public-evidence','Accept':'application/vnd.github+json'})
    with urllib.request.urlopen(request,timeout=45) as response:return json.load(response)
repo=fetch('');branch=repo['default_branch'];head=fetch('/commits/'+branch)['sha'];commits=[];page=1
while True:
    batch=fetch('/commits?sha='+head+'&since='+args.since+'&per_page=100&page='+str(page));commits+=batch
    if len(batch)<100:break
    page+=1
    if page>100:raise RuntimeError('Evidence pagination limit exceeded')
result={'observed_at':datetime.datetime.now(datetime.timezone.utc).isoformat(),'repository':repo['html_url'],'public':not repo['private'],'branch':branch,'head':head,'since':args.since,'commit_count':len(commits),'commits':[{'sha':c['sha'],'url':c['html_url'],'author':c['author']['login'] if c['author'] else c['commit']['author']['name'],'authored_at':c['commit']['author']['date'],'committed_at':c['commit']['committer']['date'],'subject':c['commit']['message'].splitlines()[0]} for c in commits]}
print(json.dumps(result,ensure_ascii=False,indent=2))
