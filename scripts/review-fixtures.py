import json
from pathlib import Path
root=Path(__file__).resolve().parents[1];file=root/'tests/cases.json';all_cases=json.loads(file.read_text(encoding='utf8'))
cases=[]
def add(name,request,expected=None,error=False):cases.append(dict(name=name,request=request,expected=expected or {},error=error))
add('review lexical sort',{'rows':[{'s':'b'},{'s':'aa'},{'s':'a'}],'sort':'s'},{'rows':[{'s':'a'},{'s':'aa'},{'s':'b'}]})
add('review lexical filter',{'rows':[{'s':'b'},{'s':'aa'}],'filter':{'field':'s','op':'gt','value':'aa'}},{'rows':[{'s':'b'}]})
add('review integer scale preserves type',{'rows':[{'n':3},{'n':4}],'columns':[{'source':'n','type':'integer','scale':0.5}],'quality_gate':{'max_rejected':0}},{'rows':[{'n':2}],'audit/rejected':1,'audit/conserved':True,'quality_gate/passed':False})
for name,extra in [
 ('unknown request',{'typo':True}),
 ('unknown column',{'columns':[{'source':'n','required_typo':True}]}),
 ('unknown leaf condition',{'filter':{'field':'n','operator_typo':'gt'}}),
 ('invalid empty join flag',{'join':{'rows':[],'left_key':'id','right_key':'id','inner':'false'}}),
 ('empty join key',{'join':{'rows':[],'left_key':'','right_key':'id'}}),
 ('empty group value',{'group':{'keys':[],'value':''}}),
 ('duplicate group key',{'group':{'keys':['id','id'],'value':'n'}}),
 ('duplicate export key',{'export_columns':['id','id']}),
 ('empty export key',{'export_columns':[]}),
 ('duplicate dedup key',{'deduplicate':['id','id']}),
 ('unknown join property',{'join':{'rows':[],'left_key':'id','right_key':'id','innre':True}}),
]:add('review '+name,{'rows':[],**extra},error=True)
all_cases=[c for c in all_cases if not c['name'].startswith('review ')]+cases
file.write_text(json.dumps(all_cases,ensure_ascii=False,indent=2)+'\n',encoding='utf8')
literal=lambda v:json.dumps(json.dumps(v,separators=(',',':'),ensure_ascii=False),ensure_ascii=False)
code=''
for case in cases:
 code+='\n///|\ntest '+json.dumps(case['name'])+' {\n'
 expr='run(parse_value('+literal(case['request'])+'))'
 if case['error']:code+='let mut rejected=false\ntry {ignore('+expr+')} catch {_=>rejected=true}\nassert_true(rejected)\n'
 else:
  code+='let result='+expr+'\n'
  for key,value in case['expected'].items():code+='assert_eq(test_at(result,'+json.dumps(key.split('/'))+'),parse_value('+literal(value)+'))\n'
 code+='}\n'
(root/'review_wbtest.mbt').write_text(code,encoding='utf8');print(len(cases),'new cases;',len(all_cases),'total API fixtures')
