create function public.list_public_needs(p_query text default '',p_category text default null,p_offset int default 0,p_limit int default 26)
returns setof jsonb language sql stable security invoker set search_path='' as $$
select jsonb_build_object('id',n.id,'title',n.title,'description',n.description,'banner_path',n.banner_path,
'organizations',jsonb_build_object('name',o.name),'collection_points',jsonb_build_object('name',p.name),
'need_items',(select jsonb_agg(jsonb_build_object('id',i.id,'category',i.category,'size_code',i.size_code,'age_group',i.age_group,'requested_qty',i.requested_qty) order by i.id) from public.need_items i where i.need_id=n.id))
from public.needs n join public.organizations o on o.id=n.organization_id join public.collection_points p on p.id=n.point_id
where n.status='open' and n.deadline_at>now() and o.verified and o.active
and strpos(lower(n.title||' '||coalesce(n.description,'')||' '||o.name||' '||p.name),lower(coalesce(p_query,'')))>0
and exists(select 1 from public.need_items i where i.need_id=n.id and (p_category is null or
case when i.category='seragam' then 'schoolUniform' when i.category in ('batik','formal') then 'batikFormal' when i.age_group in ('anak','children') then 'children' else 'adults' end=p_category))
order by n.created_at desc,n.id offset greatest(p_offset,0) limit least(greatest(p_limit,1),101)
$$;
revoke all on function public.list_public_needs(text,text,int,int) from public,anon;
grant execute on function public.list_public_needs(text,text,int,int) to authenticated;
