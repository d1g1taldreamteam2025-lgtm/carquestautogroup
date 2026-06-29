-- =============================================================================
-- CarQuest Auto Group — Esquema Supabase
-- Pega TODO esto en: Supabase -> SQL Editor -> New query -> Run
-- (Mismo Supabase que Promax; esta es una tabla aparte: no afecta nada existente.)
-- =============================================================================

-- 1) TABLA DE INVENTARIO ------------------------------------------------------
create table if not exists carquest_inventory (
  id              text primary key,            -- slug único estable, ej: ford-f150-xlt-2022
  stock           text,
  vin             text,
  year            int,
  make            text,
  model           text,
  trim            text,
  body_type       text,                        -- SUV, Sedan, Truck, Van...
  price           numeric,
  msrp            numeric,
  mileage         int,
  fuel            text,
  transmission    text,
  drivetrain      text,                        -- FWD, AWD, RWD, 4WD
  exterior_color  text,
  interior_color  text,
  badge           text,                        -- "Oferta", "Recién llegado"...
  featured        boolean      default false,
  cover_image     text,                        -- URL de la foto principal
  gallery         jsonb        default '[]',   -- array de URLs de fotos
  features        jsonb        default '[]',   -- array de strings
  description     text,
  status          text         default 'available',  -- available | sold | hidden
  created_at      timestamptz  default now(),
  updated_at      timestamptz  default now()
);

-- Índices para que los filtros del widget sean rápidos
create index if not exists idx_carquest_status   on carquest_inventory (status);
create index if not exists idx_carquest_make     on carquest_inventory (make);
create index if not exists idx_carquest_body     on carquest_inventory (body_type);
create index if not exists idx_carquest_price    on carquest_inventory (price);
create index if not exists idx_carquest_featured on carquest_inventory (featured);
create index if not exists idx_carquest_created  on carquest_inventory (created_at desc);

-- Mantener updated_at al día
create or replace function carquest_touch_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end $$;

drop trigger if exists trg_carquest_touch on carquest_inventory;
create trigger trg_carquest_touch
  before update on carquest_inventory
  for each row execute function carquest_touch_updated_at();

-- 2) SEGURIDAD (RLS) ----------------------------------------------------------
-- El público SOLO lee autos disponibles; cualquier escritura exige login.
alter table carquest_inventory enable row level security;

drop policy if exists "lectura publica disponibles" on carquest_inventory;
create policy "lectura publica disponibles"
  on carquest_inventory for select
  to anon, authenticated
  using (status = 'available');

drop policy if exists "lectura total autenticado" on carquest_inventory;
create policy "lectura total autenticado"          -- el admin ve también sold/hidden
  on carquest_inventory for select
  to authenticated
  using (true);

drop policy if exists "escritura solo autenticado" on carquest_inventory;
create policy "escritura solo autenticado"
  on carquest_inventory for all
  to authenticated
  using (true) with check (true);

-- 3) STORAGE PARA LAS FOTOS ---------------------------------------------------
-- Bucket público de lectura; subir/borrar solo autenticado.
insert into storage.buckets (id, name, public)
values ('carquest', 'carquest', true)
on conflict (id) do update set public = true;

drop policy if exists "carquest fotos lectura publica" on storage.objects;
create policy "carquest fotos lectura publica"
  on storage.objects for select
  to anon, authenticated
  using (bucket_id = 'carquest');

drop policy if exists "carquest fotos subir autenticado" on storage.objects;
create policy "carquest fotos subir autenticado"
  on storage.objects for insert
  to authenticated
  with check (bucket_id = 'carquest');

drop policy if exists "carquest fotos editar autenticado" on storage.objects;
create policy "carquest fotos editar autenticado"
  on storage.objects for update
  to authenticated
  using (bucket_id = 'carquest') with check (bucket_id = 'carquest');

drop policy if exists "carquest fotos borrar autenticado" on storage.objects;
create policy "carquest fotos borrar autenticado"
  on storage.objects for delete
  to authenticated
  using (bucket_id = 'carquest');

-- 4) USUARIO ADMIN ------------------------------------------------------------
-- Crea el usuario del panel en: Supabase -> Authentication -> Users -> Add user
-- (email + contraseña). Con eso entra a admin.html. No hace falta SQL para esto.
