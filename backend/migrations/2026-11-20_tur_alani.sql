-- PAWLO · Kedi desteği için "tür" alanı
-- Bu dosya YALNIZCA bu değişikliği yapar. schema.sql'i yeniden çalıştırmaz.
-- Güvenli: mevcut ilanlar silinmez; hepsi 'dog' (köpek) olarak işaretlenir,
-- çünkü uygulama şimdiye kadar yalnızca köpek ilanı alıyordu.
-- Tekrar çalıştırılırsa hata vermez (if not exists).

begin;

alter table public.lost_pets
  add column if not exists species text not null default 'dog';

do $$
begin
  if not exists (select 1 from pg_constraint where conname = 'lost_pets_species_check') then
    alter table public.lost_pets
      add constraint lost_pets_species_check check (species in ('dog','cat','other'));
  end if;
end $$;

-- "Cinsi" artık zorunlu değil; boş bırakılırsa bu değer yazılır.
alter table public.lost_pets alter column breed set default 'Belirtilmedi';

-- Tür ve duruma göre hızlı listeleme
create index if not exists lost_pets_species_status on public.lost_pets(species, status, created_at desc);

commit;

-- Kontrol (isteğe bağlı): select species, count(*) from public.lost_pets group by species;
-- Geri alma (gerekirse):
--   drop index if exists public.lost_pets_species_status;
--   alter table public.lost_pets drop constraint if exists lost_pets_species_check;
--   alter table public.lost_pets drop column if exists species;
--   alter table public.lost_pets alter column breed set default 'Köpek';
