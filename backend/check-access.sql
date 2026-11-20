begin;
insert into auth.users(id,email) values('11111111-1111-4111-8111-111111111101','pawlo-owner@example.invalid'),('11111111-1111-4111-8111-111111111102','pawlo-reporter@example.invalid');
set local role authenticated;
select set_config('request.jwt.claims','{"sub":"11111111-1111-4111-8111-111111111101","role":"authenticated"}',true);
insert into public.profiles(user_id,full_name,show_name) values('11111111-1111-4111-8111-111111111101','Private Owner',false);
insert into public.lost_pets(id,owner_id,pet_name,front_path,side_path,latitude,longitude) values('22222222-2222-4222-8222-222222222201','11111111-1111-4111-8111-111111111101','Access Test','11111111-1111-4111-8111-111111111101/front.jpg','11111111-1111-4111-8111-111111111101/side.jpg',40.43,29.15);
select set_config('request.jwt.claims','{"sub":"11111111-1111-4111-8111-111111111102","role":"authenticated"}',true);
insert into public.profiles(user_id,full_name,show_name) values('11111111-1111-4111-8111-111111111102','Reporter',true);
do $$begin
 if exists(select 1 from public.profiles where user_id='11111111-1111-4111-8111-111111111101') then raise exception 'Profile isolation failed'; end if;
 if not exists(select 1 from public.heroes where user_id='11111111-1111-4111-8111-111111111101' and display_name='Gizli kahraman') then raise exception 'Name masking failed'; end if;
 begin update public.heroes set report_count=999; raise exception 'Count is writable'; exception when insufficient_privilege then null; end;
end;$$;
insert into public.sightings(request_id,pet_id,reporter_id,latitude,longitude,location_source,photo_path) values('33333333-3333-4333-8333-333333333301','22222222-2222-4222-8222-222222222201','11111111-1111-4111-8111-111111111102',40.431,29.157,'manual','11111111-1111-4111-8111-111111111102/found.jpg');
do $$begin
 if (select report_count from public.heroes where user_id='11111111-1111-4111-8111-111111111102')<>1 then raise exception 'Server count failed'; end if;
 if exists(select 1 from public.notifications) then raise exception 'Notification isolation failed'; end if;
end;$$;
select set_config('request.jwt.claims','{"sub":"11111111-1111-4111-8111-111111111101","role":"authenticated"}',true);
do $$begin
 if (select count(*) from public.notifications)<>1 then raise exception 'Owner notification failed'; end if;
 begin insert into public.sightings(request_id,pet_id,reporter_id,latitude,longitude,location_source,photo_path) values(gen_random_uuid(),'22222222-2222-4222-8222-222222222201','11111111-1111-4111-8111-111111111101',40.431,29.157,'manual','11111111-1111-4111-8111-111111111101/found.jpg');raise exception 'Owner can self-award';exception when insufficient_privilege then null;end;
end;$$;
set local role anon;
select set_config('request.jwt.claims','{"role":"anon"}',true);
do $$begin
 if (select count(*) from public.lost_pets where pet_name='Access Test')<>1 then raise exception 'Public listings failed'; end if;
 begin perform * from public.profiles;raise exception 'Anonymous profile access';exception when insufficient_privilege then null;end;
 begin perform * from public.notifications;raise exception 'Anonymous notification access';exception when insufficient_privilege then null;end;
end;$$;
set local role authenticated;
select set_config('request.jwt.claims','{"sub":"11111111-1111-4111-8111-111111111102","role":"authenticated"}',true);
insert into public.user_blocks(user_id,blocked_id) values('11111111-1111-4111-8111-111111111102','11111111-1111-4111-8111-111111111101');
do $$begin if exists(select 1 from public.lost_pets where id='22222222-2222-4222-8222-222222222201') then raise exception 'Block failed';end if;end;$$;
reset role;
select 'PASS: private profiles, masked names, server counts, owner alerts, no self-awards, anonymous access, user blocking' as access_checks;
rollback;
