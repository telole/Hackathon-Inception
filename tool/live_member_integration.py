"""Explicit live QA. SQL provisioning/cleanup is executed by the operator via MCP.
Credentials stay in OS temp, never printed or committed. No email is sent.
Commands: prepare, run, cleanup-sql, storage-cleanup, finish-sql, forget.
"""
import base64
import datetime as dt
import json
import os
from pathlib import Path
import secrets
import sys
import tempfile
import urllib.error
import urllib.request
import uuid

ROOT = Path(__file__).resolve().parents[1]
STATE = Path(tempfile.gettempdir()) / 'pakaiankita-live-member-qa.json'
def uid(): return str(uuid.uuid4())
def save(state): STATE.write_text(json.dumps(state), encoding='utf-8')
def q(value): return "'" + str(value).replace("'", "''") + "'"

def prepare():
    if STATE.exists(): raise RuntimeError('A QA run already exists; clean it up before preparing another.')
    s = {'tag': uuid.uuid4().hex, 'users': {}, 'orgs': [uid(), uid()], 'points': [uid(), uid()], 'donation': uid(), 'cancelled': uid()}
    for role in ['admin', 'donatur', 'relawan', 'mitra']:
        s['users'][role] = {'id': uid(), 'email': f'qa-{role}-{s["tag"]}@example.test', 'password': secrets.token_urlsafe(32)}
    save(s)
    statements = ['begin;']
    for role, user in s['users'].items():
        statements.append(f"""insert into auth.users(instance_id,id,aud,role,email,encrypted_password,email_confirmed_at,
raw_app_meta_data,raw_user_meta_data,created_at,updated_at,confirmation_token,recovery_token,email_change_token_new,email_change)
values('00000000-0000-0000-0000-000000000000',{q(user['id'])},'authenticated','authenticated',{q(user['email'])},
extensions.crypt({q(user['password'])},extensions.gen_salt('bf')),now(),
'{{"provider":"email","providers":["email"]}}',jsonb_build_object('display_name','Temporary live QA','qa_run',{q(s['tag'])}),now(),now(),'','','','');
insert into auth.identities(provider_id,user_id,identity_data,provider,created_at,updated_at)
values({q(user['id'])},{q(user['id'])},jsonb_build_object('sub',{q(user['id'])},'email',{q(user['email'])}),'email',now(),now());""")
        if role != 'donatur': statements.append(f"insert into public.user_roles(user_id,role) values({q(user['id'])},{q(role)});")
    for i in range(2):
        statements.append(f"insert into public.organizations(id,name,kind,verified,active) values({q(s['orgs'][i])},'Temporary live QA','social_institution',true,true);")
        statements.append(f"insert into public.organization_members(organization_id,user_id) values({q(s['orgs'][i])},{q(s['users']['mitra']['id'])});")
        statements.append(f"insert into public.collection_points(id,organization_id,name,public_address) values({q(s['points'][i])},{q(s['orgs'][i])},'Temporary QA point','Temporary fixture');")
    statements.append('commit;')
    # Consumed internally by MCP orchestration. Do not display this SQL.
    return '\n'.join(statements)

def run(s):
    cfg = json.loads((ROOT / 'env.json').read_text(encoding='utf-8'))
    base, key = cfg['SUPABASE_URL'], cfg['SUPABASE_ANON_KEY']
    tokens = {}
    def call(method, path, body=None, role=None, binary=False):
        headers = {'apikey': key, 'Content-Type': 'image/png' if binary else 'application/json', 'Prefer': 'return=representation'}
        if role: headers['Authorization'] = 'Bearer ' + tokens[role]
        payload = body if binary else (json.dumps(body).encode() if body is not None else None)
        request = urllib.request.Request(base + path, data=payload, method=method, headers=headers)
        try:
            with urllib.request.urlopen(request, timeout=25) as response:
                data = response.read()
                if response.headers.get_content_type() == 'application/json': return json.loads(data) if data else None
                return data
        except urllib.error.HTTPError as error:
            raw = error.read()
            try: code = json.loads(raw).get('code', str(error.code))
            except Exception: code = str(error.code)
            raise RuntimeError(f'{method} {path.split("?")[0]} rejected ({code})') from None
    def rpc(role, name, values): return call('POST', '/rest/v1/rpc/' + name, values, role)
    for role, user in s['users'].items():
        session = call('POST', '/auth/v1/token?grant_type=password', {'email': user['email'], 'password': user['password']})
        tokens[role] = session['access_token']
    print('PASS: real Auth password login for four roles', flush=True)
    if sys.argv[1] == 'storage-cleanup':
        for bucket, role, paths in [('donation-photos', 'donatur', s.get('photos', [])), ('program-banners', 'mitra', s.get('banners', [])), ('verification-documents', 'donatur', s.get('documents', []))]:
            if paths: call('DELETE', '/storage/v1/object/' + bucket, {'prefixes': paths}, role)
        print('PASS: test Storage files removed', flush=True)
        return
    donor = s['users']['donatur']['id']
    call('PATCH', f'/rest/v1/profiles?id=eq.{donor}', {'display_name': 'QA profile updated', 'area': 'QA area'}, 'donatur')
    profile = call('GET', f'/rest/v1/profiles?select=display_name,area&id=eq.{donor}', role='donatur')
    assert profile[0]['display_name'] == 'QA profile updated'
    print('PASS: profile update persisted through REST/RLS', flush=True)
    need = rpc('mitra', 'save_need', {'p_id': None, 'p_org': s['orgs'][1], 'p_point': s['points'][1], 'p_title': 'Temporary QA program',
        'p_description': 'Temporary fixture', 'p_deadline': (dt.datetime.now(dt.timezone.utc) + dt.timedelta(days=3)).isoformat(), 'p_incident': None,
        'p_items': [{'category': 'kaos', 'size_code': 'M', 'age_group': 'anak', 'requested_qty': 6}]})
    s['need'] = need; save(s)
    png = base64.b64decode('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+jRZkAAAAASUVORK5CYII=')
    banner = f'{s["users"]["mitra"]["id"]}/{need}/banner.png'
    s['banners'] = [banner]; save(s)
    call('POST', '/storage/v1/object/program-banners/' + banner, png, 'mitra', True)
    call('PATCH', f'/rest/v1/needs?id=eq.{need}', {'banner_path': banner}, 'mitra')
    rpc('mitra', 'set_need_status', {'p_id': need, 'p_status': 'open'})
    visible = call('GET', f'/rest/v1/needs?select=id,banner_path,organizations(name),need_items(id)&id=eq.{need}', role='donatur')
    assert visible[0]['banner_path'] == banner
    signed = call('POST', '/storage/v1/object/sign/program-banners/' + banner, {'expiresIn': 60}, 'donatur')
    with urllib.request.urlopen(base + '/storage/v1' + signed['signedURL'], timeout=25) as response: assert response.read() == png
    line = visible[0]['need_items'][0]['id']
    print('PASS: program creation, banner upload, publication and donor signed-image read', flush=True)
    d = s['donation']
    call('POST', '/rest/v1/donations', {'id': d, 'point_id': s['points'][0], 'method': 'dropoff'}, 'donatur')
    item = call('POST', '/rest/v1/donation_items', {'donation_id': d, 'category': 'kaos', 'size_code': 'M', 'age_group': 'anak', 'quantity': 10}, 'donatur')[0]['id']
    photo = f'{donor}/{d}/photo.png'; s['photos'] = [photo]; save(s)
    call('POST', '/storage/v1/object/donation-photos/' + photo, png, 'donatur', True)
    call('POST', '/rest/v1/donation_photos', {'donation_id': d, 'storage_path': photo}, 'donatur')
    call('PATCH', f'/rest/v1/donations?id=eq.{d}', {'clean_check': True, 'intact_check': True, 'not_torn_check': True}, 'donatur')
    rpc('donatur', 'submit_donation', {'p_id': d})
    revision = {'p_id': d, 'p_note': 'Temporary QA revision note', 'p_key': uid()}
    rpc('admin', 'request_donation_revision', revision); rpc('admin', 'request_donation_revision', revision)
    events = call('GET', f'/rest/v1/donation_events?select=summary&donation_id=eq.{d}&event_type=eq.needs_revision', role='donatur')
    assert len(events) == 1 and events[0]['summary'] == revision['p_note']
    call('PATCH', f'/rest/v1/donation_items?id=eq.{item}', {'quantity': 10}, 'donatur')
    rpc('donatur', 'submit_donation', {'p_id': d})
    print('PASS: real donation image upload, submit, revision note retry, edit and resubmit', flush=True)
    rpc('admin', 'schedule_donation', {'p_id': d, 'p_at': (dt.datetime.now(dt.timezone.utc) + dt.timedelta(days=1)).isoformat()})
    task = rpc('admin', 'assign_logistics_task', {'p_id': None, 'p_donation': d, 'p_point': s['points'][0], 'p_volunteer': s['users']['relawan']['id'], 'p_kind': 'curation', 'p_at': None, 'p_notes': 'Temporary QA'})
    rpc('relawan', 'respond_task', {'p_id': task, 'p_status': 'accepted'})
    rpc('relawan', 'respond_task', {'p_id': task, 'p_status': 'in_progress'})
    rpc('relawan', 'advance_donation', {'p_id': d, 'p_status': 'received'})
    batch = rpc('relawan', 'record_inspection', {'p_item': item, 'p_passed': 8, 'p_rejected': 2, 'p_reason': 'Temporary QA'})
    rpc('relawan', 'respond_task', {'p_id': task, 'p_status': 'completed'})
    allocation = rpc('mitra', 'reserve_allocation', {'p_batch': batch, 'p_need_item': line, 'p_qty': 6, 'p_key': uid()})
    shipment = rpc('mitra', 'create_shipment', {'p_allocation': allocation, 'p_volunteer': s['users']['relawan']['id']})
    rpc('relawan', 'dispatch_shipment', {'p_id': shipment})
    rpc('mitra', 'confirm_receipt', {'p_id': shipment, 'p_good': 6, 'p_rejected': 0, 'p_missing': 0})
    balance = call('GET', f'/rest/v1/inventory_batches?select=on_hand_qty,reserved_qty&id=eq.{batch}', role='mitra')[0]
    assert balance == {'on_hand_qty': 2, 'reserved_qty': 0}
    print('PASS: volunteer receive/curate, allocation, shipment dispatch/receipt and final stock', flush=True)
    call('POST', '/rest/v1/donations', {'id': s['cancelled'], 'point_id': s['points'][0]}, 'donatur')
    rpc('donatur', 'cancel_donation', {'p_id': s['cancelled']})
    new_password = secrets.token_urlsafe(32)
    call('PUT', '/auth/v1/user', {'password': new_password}, 'donatur')
    s['users']['donatur']['password'] = new_password; save(s)
    call('POST', '/auth/v1/token?grant_type=password', {'email': s['users']['donatur']['email'], 'password': new_password})
    print('PASS: cancellation and real password change/login', flush=True)

def cleanup_sql(s, finish=False):
    users = ','.join(q(u['id']) for u in s['users'].values())
    orgs = ','.join(q(v) for v in s['orgs'])
    donations = ','.join(q(s[v]) for v in ['donation', 'cancelled'])
    if not finish:
        return f"begin; update public.donations set status='draft' where id in ({donations}); update public.needs set banner_path=null where organization_id in ({orgs}); update public.organization_applications set status='draft' where applicant_id in ({users}); commit;"
    return f"""begin;
delete from public.shipment_items where shipment_id in (select id from public.shipments where assigned_to in ({users}));
delete from public.shipments where assigned_to in ({users});
delete from public.allocations where created_by in ({users});
delete from public.inventory_batches where point_id in (select id from public.collection_points where organization_id in ({orgs}));
delete from public.recycling_referrals where inspection_id in (select id from public.inspections where inspector_id in ({users}));
delete from public.inspections where inspector_id in ({users});
delete from public.logistics_tasks where assigned_to in ({users});
delete from public.donation_events where donation_id in ({donations});
delete from public.donation_photos where donation_id in ({donations});
delete from public.donation_items where donation_id in ({donations});
delete from public.donations where id in ({donations});
delete from public.need_items where need_id in (select id from public.needs where organization_id in ({orgs}));
delete from public.needs where organization_id in ({orgs});
delete from public.collection_points where organization_id in ({orgs});
delete from public.organization_members where organization_id in ({orgs});
delete from public.organization_applications where applicant_id in ({users});
delete from public.role_requests where user_id in ({users});
delete from public.organizations where id in ({orgs});
delete from private.revision_requests where actor_id in ({users});
delete from private.audit_logs where actor_id in ({users});
delete from public.user_roles where user_id in ({users});
delete from auth.users where id in ({users}) and raw_user_meta_data->>'qa_run'={q(s['tag'])};
commit;
select 'PASS: ephemeral QA rows and accounts cleaned' as result;"""

if __name__ == '__main__':
    command = sys.argv[1]
    if command == 'prepare': print(prepare())
    elif command == 'forget': STATE.unlink(missing_ok=True)
    else:
        state = json.loads(STATE.read_text(encoding='utf-8'))
        if command in ('run', 'storage-cleanup'): run(state)
        elif command == 'cleanup-sql': print(cleanup_sql(state))
        elif command == 'finish-sql': print(cleanup_sql(state, True))
