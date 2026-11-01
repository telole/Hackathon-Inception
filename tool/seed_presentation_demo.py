"""Persistent presentation seed. Secrets/IDs are kept outside the Git workspace.
prepare emits provisioning SQL for internal MCP execution; upload uses real Storage;
finalize emits actual workflow RPC calls. No existing account is overwritten.
"""
import io
import json
from pathlib import Path
import secrets
import sys
import urllib.error
import urllib.request
import uuid
from PIL import Image, ImageDraw, ImageFont

ROOT=Path(__file__).resolve().parents[1]
MANIFEST=Path('D:/PakaianKita_Demo_Manifest.json')
CREDENTIALS=Path('D:/PakaianKita_Demo_Akun.md')
ASSETS=Path('D:/PakaianKita_Demo_Assets')
TAG='pakaiankita-hackathon-v1'
def uid():return str(uuid.uuid4())
def q(v):return "'"+str(v).replace("'","''")+"'"
def prepare():
    if MANIFEST.exists():raise RuntimeError('Demo manifest exists. Resume upload/finalize; do not overwrite demo progress.')
    s={'tag':TAG,'password':'PkDemo!'+secrets.token_hex(4),'users':{},'orgs':[uid(),uid()],'points':[uid(),uid()],
       'needs':[uid() for _ in range(3)],'lines':[uid() for _ in range(3)],'donations':[uid() for _ in range(8)],'items':[uid() for _ in range(8)],
       'organization_application':uid(),'role_request':uid()}
    names={'admin':'Farid - Admin Demo','donatur':'Nadia - Donatur Demo','relawan':'Rina - Relawan Demo','mitra':'Ayu - Mitra Demo','pemohon':'Bima - Pemohon Demo'}
    for role in names:s['users'][role]={'id':uid(),'email':role+'.demo@pakaiankita.test','name':names[role]}
    MANIFEST.write_text(json.dumps(s,indent=2),encoding='utf-8')
    credentials=['# Akun presentasi PakaianKita','',f'Password semua akun: `{s["password"]}`','', '| Peran | Email |','|---|---|']
    credentials += [f'| {role} | {user["email"]} |' for role,user in s['users'].items()]
    credentials += ['','Akun sudah dikonfirmasi dan dapat login tanpa email. Akun pemohon dipakai untuk menunjukkan pengajuan relawan/lembaga.','Jangan commit file ini atau membagikan akun admin di luar tim.']
    CREDENTIALS.write_text('\n'.join(credentials)+'\n',encoding='utf-8')
    sql=['begin;']
    for role,user in s['users'].items():
        sql.append(f"""insert into auth.users(instance_id,id,aud,role,email,encrypted_password,email_confirmed_at,raw_app_meta_data,raw_user_meta_data,
created_at,updated_at,confirmation_token,recovery_token,email_change_token_new,email_change)
values('00000000-0000-0000-0000-000000000000',{q(user['id'])},'authenticated','authenticated',{q(user['email'])},
extensions.crypt({q(s['password'])},extensions.gen_salt('bf')),now(),'{{"provider":"email","providers":["email"]}}',
jsonb_build_object('display_name',{q(user['name'])},'demo_seed',{q(TAG)}),now(),now(),'','','','');
insert into auth.identities(provider_id,user_id,identity_data,provider,created_at,updated_at)
values({q(user['id'])},{q(user['id'])},jsonb_build_object('sub',{q(user['id'])},'email',{q(user['email'])}),'email',now(),now());
update public.profiles set area='Bandung (data simulasi)' where id={q(user['id'])};""")
        if role in ('admin','relawan','mitra'):sql.append(f"insert into public.user_roles(user_id,role) values({q(user['id'])},{q(role)});")
    for i,name in enumerate(['[DEMO] Rumah Sandang Bandung','[DEMO] Yayasan Pelita Anak']):
        sql.append(f"insert into public.organizations(id,name,kind,area,verified,active) values({q(s['orgs'][i])},{q(name)},'social_institution','Bandung - simulasi',true,true);")
        sql.append(f"insert into public.organization_members(organization_id,user_id,active,member_role) values({q(s['orgs'][i])},{q(s['users']['mitra']['id'])},true,'manager');")
        sql.append(f"insert into public.collection_points(id,organization_id,name,public_address,opening_hours) values({q(s['points'][i])},{q(s['orgs'][i])},{q('Titik Demo '+('Pengumpulan Dago' if i==0 else 'Penyaluran Cianjur'))},'Alamat simulasi untuk presentasi','Senin-Sabtu, 09.00-16.00');")
    programs=[('Kaos anak untuk kembali bermain','kaos','M','anak',50),('Seragam sekolah, semangat baru','seragam','M','anak',30),('Pakaian hangat untuk keluarga','kemeja','L','dewasa',40)]
    for i,(title,category,size,age,qty) in enumerate(programs):
        sql.append(f"insert into public.needs(id,organization_id,point_id,title,description,deadline_at) values({q(s['needs'][i])},{q(s['orgs'][1])},{q(s['points'][1])},{q('[DEMO] '+title)},'Program simulasi hackathon. Pakaian akan diperiksa relawan dan disalurkan sesuai ukuran serta kebutuhan.',now()+interval '30 days');")
        sql.append(f"insert into public.need_items(id,need_id,category,size_code,age_group,requested_qty) values({q(s['lines'][i])},{q(s['needs'][i])},{q(category)},{q(size)},{q(age)},{qty});")
    quantities=[10,6,8,12,20,16,10,4]
    for i in range(8):
        program=1 if i==1 else 0
        category='seragam' if i==1 else 'kaos'
        sql.append(f"insert into public.donations(id,donor_id,tracking_code,point_id,preferred_need_id,method,clean_check,intact_check,not_torn_check) values({q(s['donations'][i])},{q(s['users']['donatur']['id'])},{q('PK-DEMO-'+str(i+1).zfill(3))},{q(s['points'][0])},{q(s['needs'][program])},{q('pickup' if i==2 else 'dropoff')},true,true,true);")
        sql.append(f"insert into public.donation_items(id,donation_id,category,size_code,age_group,quantity) values({q(s['items'][i])},{q(s['donations'][i])},{q(category)},'M','anak',{quantities[i]});")
    applicant=s['users']['pemohon']['id']
    sql.append(f"insert into public.organization_applications(id,applicant_id,name,kind,area,contact_name,contact_phone) values({q(s['organization_application'])},{q(applicant)},'[DEMO] Komunitas Sandang Bersama','social_institution','Bandung - simulasi','Bima - Pemohon Demo','0800000000');")
    sql.append('commit;')
    return '\n'.join(sql)

def font(size,bold=False):return ImageFont.truetype(str(ROOT/'assets/fonts'/('Poppins-Bold.ttf' if bold else 'Poppins-Regular.ttf')),size)
def assets():
    ASSETS.mkdir(exist_ok=True)
    titles=[('KAOS ANAK','Kembali bermain, kembali percaya diri.'),('SERAGAM SEKOLAH','Satu seragam. Banyak harapan.'),('PAKAIAN HANGAT','Rasa hangat untuk keluarga.')]
    palette=['#1D9E75','#C48243','#316C79']
    for i,(title,subtitle) in enumerate(titles):
        im=Image.new('RGB',(1000,560),'#F5F1E8');d=ImageDraw.Draw(im)
        d.rounded_rectangle((35,35,965,525),radius=28,fill='#085041')
        d.text((70,70),'PakaianKita / PROGRAM DEMO',font=font(20),fill='#CDE5D8')
        words=title.split(' ')
        for j,word in enumerate(words):d.text((70,145+j*66),word,font=font(54,True),fill='#F5F1E8')
        d.text((70,400),subtitle,font=font(21),fill='#F5F1E8');d.text((70,455),'Yayasan Pelita Anak - simulasi hackathon',font=font(16),fill='#CDE5D8')
        d.polygon([(665,140),(710,120),(780,120),(825,140),(890,205),(845,250),(815,220),(815,360),(675,360),(675,220),(645,250),(600,205)],fill=palette[i])
        d.arc((708,98,784,159),0,180,fill='#F5F1E8',width=5)
        d.line((697,338,794,338),fill='#D7E5DC',width=3)
        im.save(ASSETS/f'banner-{i}.png')
    im=Image.new('RGB',(900,700),'#F5F1E8');d=ImageDraw.Draw(im)
    for i,c in enumerate(['#D4A977','#A9BBA8','#5D8F85']):
        y=200+i*85;d.rounded_rectangle((240,y,660,y+160),radius=22,fill=c,outline='#085041',width=4)
        d.arc((395,y-20,505,y+65),0,180,fill='#085041',width=5)
        d.line((450,y+50,450,y+135),fill='#085041',width=3)
    d.text((55,45),'FOTO PAKAIAN - ILUSTRASI DEMO',font=font(28,True),fill='#085041')
    d.text((55,610),'Data simulasi presentasi / bukan donasi nyata',font=font(21),fill='#085041')
    im.save(ASSETS/'donation.png')
    im=Image.new('RGB',(850,1100),'white');d=ImageDraw.Draw(im)
    for y,text in [(60,'DOKUMEN SIMULASI DEMO'),(150,'Komunitas Sandang Bersama'),(230,'Penanggung jawab: Bima - Pemohon Demo'),(290,'Wilayah: Bandung (simulasi)'),(400,'Dokumen ini dibuat untuk demonstrasi'),(450,'alur verifikasi lembaga di PakaianKita.'),(560,'Bukan dokumen legal lembaga nyata.')]:
        d.text((55,y),text,font=font(24,y==60),fill='#085041')
    im.save(ASSETS/'verification.pdf','PDF',resolution=100)

def upload(s):
    assets();cfg=json.loads((ROOT/'env.json').read_text(encoding='utf-8'));tokens={}
    def call(method,path,body=None,role=None,mime='application/json'):
        headers={'apikey':cfg['SUPABASE_ANON_KEY'],'Content-Type':mime,'Prefer':'return=representation'}
        if role:headers['Authorization']='Bearer '+tokens[role]
        data=body if isinstance(body,bytes) else json.dumps(body).encode() if body is not None else None
        try:
            with urllib.request.urlopen(urllib.request.Request(cfg['SUPABASE_URL']+path,data=data,headers=headers,method=method),timeout=35) as r:
                raw=r.read();return json.loads(raw) if raw and r.headers.get_content_type()=='application/json' else raw
        except urllib.error.HTTPError as e:
            e.read()
            if e.code==409:return None
            raise RuntimeError(f'{method} {path.split("?")[0]} failed ({e.code})') from None
    for role,u in s['users'].items():
        auth=call('POST','/auth/v1/token?grant_type=password',{'email':u['email'],'password':s['password']});tokens[role]=auth['access_token']
        print(f'PASS: login {role}',flush=True)
    for i in range(3):
        path=f'{s["users"]["mitra"]["id"]}/{s["needs"][i]}/banner.png'
        call('POST','/storage/v1/object/program-banners/'+path,(ASSETS/f'banner-{i}.png').read_bytes(),'mitra','image/png')
    print('PASS: three real program banners uploaded',flush=True)
    photos=[]
    for i,donation in enumerate(s['donations']):
        path=f'{s["users"]["donatur"]["id"]}/{donation}/demo.png'
        call('POST','/storage/v1/object/donation-photos/'+path,(ASSETS/'donation.png').read_bytes(),'donatur','image/png')
        photos.append({'id':s['items'][i],'donation_id':donation,'storage_path':path})
    existing=call('GET','/rest/v1/donation_photos?select=donation_id',role='donatur')
    present={p['donation_id'] for p in existing};photos=[p for p in photos if p['donation_id'] not in present]
    if photos:call('POST','/rest/v1/donation_photos',photos,'donatur')
    path=f'{s["users"]["pemohon"]["id"]}/{s["organization_application"]}/verification.pdf'
    call('POST','/storage/v1/object/verification-documents/'+path,(ASSETS/'verification.pdf').read_bytes(),'pemohon','application/pdf')
    print('PASS: eight donation images and verification PDF uploaded',flush=True)

def claims(s,role):
    user=s['users'][role]['id'];return f"perform set_config('request.jwt.claim.sub',{q(user)},true);perform set_config('request.jwt.claims',jsonb_build_object('sub',{q(user)},'role','authenticated')::text,true);"
def finalize(s):
    sql=['begin;','do $$ declare task uuid;batch uuid;allocation uuid;shipment uuid;begin',"perform set_config('role','authenticated',true);",claims(s,'mitra')]
    for i,need in enumerate(s['needs']):
        path=f'{s["users"]["mitra"]["id"]}/{need}/banner.png'
        sql.append(f"update public.needs set banner_path={q(path)} where id={q(need)};perform public.set_need_status({q(need)},'open');")
    sql.append(claims(s,'donatur'))
    sql.append(f"perform public.save_donation_contact({q(s['donations'][2])},'Alamat penjemputan simulasi, Bandung','Nadia - Donatur Demo','0800000000');")
    for donation in s['donations'][:7]:sql.append(f"perform public.submit_donation({q(donation)});")
    sql.append(f"perform public.cancel_donation({q(s['donations'][7])});")
    sql += [claims(s,'admin'),f"perform public.request_donation_revision({q(s['donations'][1])},'Mohon foto seragam ditampilkan lebih jelas dan pastikan ukuran sudah sesuai. Catatan simulasi demo.',gen_random_uuid());",
      f"perform public.schedule_donation({q(s['donations'][2])},now()+interval '1 day');",
      f"perform public.assign_logistics_task(null,{q(s['donations'][2])},{q(s['points'][0])},{q(s['users']['relawan']['id'])},'pickup',now()+interval '1 day','DEMO: terima tugas dan catat pakaian diterima.');",
      f"perform public.advance_donation({q(s['donations'][3])},'received');",
      f"perform public.assign_logistics_task(null,{q(s['donations'][3])},{q(s['points'][0])},{q(s['users']['relawan']['id'])},'curation',null,'DEMO: periksa 12 potong pakaian dan catat hasil kurasi.');"]
    for i,passed,rejected,reserved in [(4,18,2,6),(5,14,2,8),(6,10,0,6)]:
        d=s['donations'][i]
        sql += [claims(s,'admin'),f"task:=public.assign_logistics_task(null,{q(d)},{q(s['points'][0])},{q(s['users']['relawan']['id'])},'curation',null,'Riwayat simulasi selesai kurasi');",
          f"perform public.advance_donation({q(d)},'received');",claims(s,'relawan'),"perform public.respond_task(task,'accepted');perform public.respond_task(task,'in_progress');",
          f"batch:=public.record_inspection({q(s['items'][i])},{passed},{rejected},'Hasil pemeriksaan simulasi demo');perform public.respond_task(task,'completed');",claims(s,'mitra'),
          f"allocation:=public.reserve_allocation(batch,{q(s['lines'][0])},{reserved},gen_random_uuid());shipment:=public.create_shipment(allocation,{q(s['users']['relawan']['id'])});"]
        if i>=5:sql += [claims(s,'relawan'),"perform public.dispatch_shipment(shipment);"]
        if i==6:sql += [claims(s,'mitra'),"perform public.confirm_receipt(shipment,6,0,0);"]
    path=f'{s["users"]["pemohon"]["id"]}/{s["organization_application"]}/verification.pdf'
    sql += [claims(s,'pemohon'),f"perform public.apply_volunteer({q(s['role_request'])},'Saya ingin membantu penjemputan dan kurasi pakaian di Bandung. Tersedia pada akhir pekan. Pengajuan simulasi demo.');",
      f"perform public.submit_organization_application({q(s['organization_application'])},{q(path)});", "perform set_config('role','postgres',true);end $$;commit;",
      "select 'Presentation demo ready: 5 accounts, 3 programs, 8 donations, 3 shipment stages, 2 pending applications' as result;"]
    return '\n'.join(sql)

if __name__=='__main__':
    command=sys.argv[1]
    if command=='prepare':print(prepare())
    else:
        state=json.loads(MANIFEST.read_text(encoding='utf-8'))
        if command=='upload':upload(state)
        elif command=='finalize':print(finalize(state))
