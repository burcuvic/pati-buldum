begin;
create schema if not exists pawlo_private;
revoke all on schema pawlo_private from public, anon, authenticated;

create table public.profiles (
  user_id uuid primary key references auth.users(id) on delete cascade,
  full_name text not null check (length(trim(full_name)) between 1 and 60),
  show_name boolean not null default true,
  created_at timestamptz not null default now()
);
create table public.heroes (
  user_id uuid primary key references auth.users(id) on delete cascade,
  display_name text not null,
  report_count integer not null default 0 check(report_count >= 0)
);
create table public.lost_pets (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references auth.users(id) on delete cascade,
  pet_name text not null check(length(trim(pet_name)) between 1 and 60),
  breed text not null default 'Köpek' check(length(breed)<=100),
  front_path text not null,
  side_path text not null,
  latitude double precision not null check(latitude between -90 and 90),
  longitude double precision not null check(longitude between -180 and 180),
  reward numeric(12,2) not null default 0 check(reward between 0 and 10000000),
  status text not null default 'lost' check(status in ('lost','reunited','withdrawn')),
  last_seen_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  check(front_path like owner_id::text || '/%'),
  check(side_path like owner_id::text || '/%')
);
create table public.sightings (
  id uuid primary key default gen_random_uuid(),
  request_id uuid not null unique,
  pet_id uuid not null references public.lost_pets(id) on delete cascade,
  reporter_id uuid not null references auth.users(id) on delete cascade,
  latitude double precision not null check(latitude between -90 and 90),
  longitude double precision not null check(longitude between -180 and 180),
  accuracy integer check(accuracy is null or accuracy between 0 and 100000),
  location_source text not null check(location_source in ('gps','manual')),
  photo_path text not null,
  seen_at timestamptz not null default now() check(seen_at <= now()+interval '5 minutes'),
  created_at timestamptz not null default now(),
  check(photo_path like reporter_id::text || '/%')
);
create table public.notifications (
  id uuid primary key default gen_random_uuid(),
  recipient_id uuid not null references auth.users(id) on delete cascade,
  sighting_id uuid not null unique references public.sightings(id) on delete cascade,
  is_read boolean not null default false,
  created_at timestamptz not null default now()
);
create table public.content_reports (
  id uuid primary key default gen_random_uuid(),
  reporter_id uuid not null references auth.users(id) on delete cascade,
  pet_id uuid not null references public.lost_pets(id) on delete cascade,
  reason text not null check(length(trim(reason)) between 3 and 1000),
  created_at timestamptz not null default now()
);
create table public.user_blocks (
  user_id uuid not null references auth.users(id) on delete cascade,
  blocked_id uuid not null references auth.users(id) on delete cascade,
  primary key(user_id,blocked_id),
  check(user_id<>blocked_id)
);
create index lost_pets_status_created on public.lost_pets(status,created_at desc);
create index lost_pets_owner on public.lost_pets(owner_id);
create index sightings_pet_seen on public.sightings(pet_id,seen_at desc);
create index sightings_reporter on public.sightings(reporter_id);
create index notifications_recipient on public.notifications(recipient_id,created_at desc);
create index content_reports_reporter on public.content_reports(reporter_id);
create index content_reports_pet on public.content_reports(pet_id);
create index blocks_blocked on public.user_blocks(blocked_id);

alter table public.profiles enable row level security;
alter table public.heroes enable row level security;
alter table public.lost_pets enable row level security;
alter table public.sightings enable row level security;
alter table public.notifications enable row level security;
alter table public.content_reports enable row level security;
alter table public.user_blocks enable row level security;

revoke all on public.profiles,public.heroes,public.lost_pets,public.sightings,public.notifications,public.content_reports,public.user_blocks from anon,authenticated;
grant select,insert,update on public.profiles to authenticated;
create policy profiles_own_select on public.profiles for select to authenticated using(user_id=(select auth.uid()));
create policy profiles_own_insert on public.profiles for insert to authenticated with check(user_id=(select auth.uid()));
create policy profiles_own_update on public.profiles for update to authenticated using(user_id=(select auth.uid())) with check(user_id=(select auth.uid()));
grant select on public.heroes to anon,authenticated;
create policy heroes_read on public.heroes for select to anon,authenticated using(true);
grant select on public.lost_pets to anon,authenticated;
grant insert,update on public.lost_pets to authenticated;
create policy pets_read on public.lost_pets for select to anon,authenticated using((status='lost' or owner_id=(select auth.uid())) and not exists(select 1 from public.user_blocks b where b.user_id=(select auth.uid()) and b.blocked_id=owner_id));
create policy pets_insert on public.lost_pets for insert to authenticated with check(owner_id=(select auth.uid()));
create policy pets_update on public.lost_pets for update to authenticated using(owner_id=(select auth.uid())) with check(owner_id=(select auth.uid()));
grant select on public.sightings to anon,authenticated;
grant insert(request_id,pet_id,reporter_id,latitude,longitude,accuracy,location_source,photo_path,seen_at) on public.sightings to authenticated;
create policy sightings_read on public.sightings for select to anon,authenticated using(exists(select 1 from public.lost_pets p where p.id=pet_id));
create policy sightings_insert on public.sightings for insert to authenticated with check(reporter_id=(select auth.uid()) and exists(select 1 from public.lost_pets p where p.id=pet_id and p.status='lost' and p.owner_id<>(select auth.uid())));
grant select,update(is_read) on public.notifications to authenticated;
create policy notifications_read on public.notifications for select to authenticated using(recipient_id=(select auth.uid()));
create policy notifications_update on public.notifications for update to authenticated using(recipient_id=(select auth.uid())) with check(recipient_id=(select auth.uid()));
grant select,insert on public.content_reports to authenticated;
create policy reports_read on public.content_reports for select to authenticated using(reporter_id=(select auth.uid()));
create policy reports_insert on public.content_reports for insert to authenticated with check(reporter_id=(select auth.uid()));
grant select,insert,delete on public.user_blocks to authenticated;
create policy blocks_own on public.user_blocks for all to authenticated using(user_id=(select auth.uid())) with check(user_id=(select auth.uid()));
grant select on public.user_blocks to anon;
create policy blocks_anon_none on public.user_blocks for select to anon using(false);

-- Internal trigger authority is limited to maintaining sanitized names, counts, and owner alerts.
create function pawlo_private.sync_hero() returns trigger language plpgsql security definer set search_path='' as $$
begin
  insert into public.heroes(user_id,display_name) values(new.user_id,case when new.show_name then new.full_name else 'Gizli kahraman' end)
  on conflict(user_id) do update set display_name=excluded.display_name;
  return new;
end;$$;
revoke all on function pawlo_private.sync_hero() from public,anon,authenticated;
create trigger profile_sync after insert or update on public.profiles for each row execute function pawlo_private.sync_hero();
create function pawlo_private.record_sighting() returns trigger language plpgsql security definer set search_path='' as $$
begin
  if tg_op='INSERT' then
    update public.heroes set report_count=report_count+1 where user_id=new.reporter_id;
    insert into public.notifications(recipient_id,sighting_id) select owner_id,new.id from public.lost_pets where id=new.pet_id;
    return new;
  end if;
  update public.heroes set report_count=greatest(0,report_count-1) where user_id=old.reporter_id;
  return old;
end;$$;
revoke all on function pawlo_private.record_sighting() from public,anon,authenticated;
create trigger sighting_insert after insert on public.sightings for each row execute function pawlo_private.record_sighting();
create trigger sighting_delete after delete on public.sightings for each row execute function pawlo_private.record_sighting();

insert into storage.buckets(id,name,public,file_size_limit,allowed_mime_types) values
('pet-photos','pet-photos',true,12582912,array['image/jpeg','image/png','image/webp']),
('sighting-photos','sighting-photos',false,12582912,array['image/jpeg','image/png','image/webp']);
create policy photos_insert on storage.objects for insert to authenticated with check(bucket_id in('pet-photos','sighting-photos') and (storage.foldername(name))[1]=(select auth.uid())::text and exists(select 1 from public.profiles where user_id=(select auth.uid())));
create policy photos_delete on storage.objects for delete to authenticated using(bucket_id in('pet-photos','sighting-photos') and (storage.foldername(name))[1]=(select auth.uid())::text);
create policy photos_read_owner on storage.objects for select to authenticated using(bucket_id in('pet-photos','sighting-photos') and (storage.foldername(name))[1]=(select auth.uid())::text);
create policy sightings_photo_read_pet_owner on storage.objects for select to authenticated using(bucket_id='sighting-photos' and exists(select 1 from public.sightings s join public.lost_pets p on p.id=s.pet_id where s.photo_path=name and p.owner_id=(select auth.uid())));
commit;
