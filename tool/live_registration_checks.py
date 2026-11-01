"""Run only with the temporary fixtures from live_member_integration.py prepare.
No email or push messages are sent. Cleanup uses the same fixture state.
"""
import json
import urllib.error
import urllib.request
from live_member_integration import ROOT, STATE, save, uid

s=json.loads(STATE.read_text(encoding='utf-8'))
cfg=json.loads((ROOT/'env.json').read_text(encoding='utf-8'))
tokens={}
def call(method,path,body=None,role=None,mime='application/json'):
    headers={'apikey':cfg['SUPABASE_ANON_KEY'],'Content-Type':mime,'Prefer':'return=representation'}
    if role: headers['Authorization']='Bearer '+tokens[role]
    data=body if isinstance(body,bytes) else json.dumps(body).encode() if body is not None else None
    try:
        with urllib.request.urlopen(urllib.request.Request(cfg['SUPABASE_URL']+path,data=data,headers=headers,method=method),timeout=25) as r:
            raw=r.read()
            return json.loads(raw) if raw and r.headers.get_content_type()=='application/json' else raw
    except urllib.error.HTTPError as e:
        e.read()
        raise RuntimeError(f'{method} {path.split("?")[0]} rejected ({e.code})') from None
def rpc(role,name,body):return call('POST','/rest/v1/rpc/'+name,body,role)
for role,u in s['users'].items():
    tokens[role]=call('POST','/auth/v1/token?grant_type=password',{'email':u['email'],'password':u['password']})['access_token']
access=rpc('donatur','my_access',{})
if 'relawan' not in access['roles']:
    request=uid()
    rpc('donatur','apply_volunteer',{'p_id':request,'p_message':'Temporary HTTP registration verification'})
    rpc('admin','review_registration',{'p_type':'volunteer','p_id':request,'p_approve':True,'p_reason':'QA approved'})
    access=rpc('donatur','my_access',{})
assert 'relawan' in access['roles']
print('PASS: volunteer request and admin approval grant real role',flush=True)
application=s.get('documents',[None])[0].split('/')[1] if s.get('documents') else uid()
rpc('donatur','save_organization_application',{'p_id':application,'p_payload':{'name':'Temporary application QA','kind':'social_institution','area':'QA area','contact_name':'QA applicant','contact_phone':'0800000000'}})
path=f'{s["users"]["donatur"]["id"]}/{application}/proof.pdf'
s['documents']=[path];save(s)
pdf=b'%PDF-1.4\n% temporary verification fixture\n%%EOF'
call('POST','/storage/v1/object/verification-documents/'+path,pdf,'donatur','application/pdf')
rpc('donatur','submit_organization_application',{'p_id':application,'p_document':path})
denied=False
try:call('POST','/storage/v1/object/sign/verification-documents/'+path,{'expiresIn':60},'mitra')
except RuntimeError:denied=True
assert denied,'Unrelated partner must not read verification documents'
signed=call('POST','/storage/v1/object/sign/verification-documents/'+path,{'expiresIn':60},'admin')
with urllib.request.urlopen(cfg['SUPABASE_URL']+'/storage/v1'+signed['signedURL'],timeout=25) as response:assert response.read()==pdf
print('PASS: real PDF upload, admin signed read, unrelated partner denied',flush=True)
rpc('admin','review_registration',{'p_type':'organization','p_id':application,'p_approve':True,'p_reason':'QA approved'})
app=call('GET',f'/rest/v1/organization_applications?select=organization_id&id=eq.{application}',role='donatur')[0]
org=app['organization_id'];s['orgs'].append(org);save(s)
access=rpc('donatur','my_access',{});assert 'mitra' in access['roles']
rpc('donatur','manage_organization_member',{'p_org':org,'p_email':s['users']['mitra']['email'],'p_user':None,'p_active':True})
point=rpc('donatur','save_collection_point',{'p_id':None,'p_org':org,'p_name':'QA point','p_address':'Temporary QA address','p_hours':'09.00-16.00','p_active':True})
assert point
members=rpc('donatur','list_organization_members',{'p_org':org,'p_offset':0,'p_limit':26})
assert len(members)==2
count=rpc('donatur','notification_unread_count',{})
assert count>0
call('PATCH',f'/rest/v1/notifications?user_id=eq.{s["users"]["donatur"]["id"]}&read_at=is.null',{'read_at':'2026-11-01T00:00:00Z'},'donatur')
assert rpc('donatur','notification_unread_count',{})==0
print('PASS: approved organization, manager membership/point, inbox read updates',flush=True)
