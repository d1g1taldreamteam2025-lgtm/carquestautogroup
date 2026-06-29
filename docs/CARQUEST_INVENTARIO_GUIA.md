# CarQuest Auto Group — Inventario + Panel de Admin
## Guía de implementación (basada en el sistema de Promax Auto Broker)

> **Para:** el Claude / desarrollador que construirá esto.
> **Contexto:** la web ya existe en WordPress (https://carquestautogroup.com). Hay que
> agregarle una sección de **Inventario de autos** con los **colores de la marca** y un
> **panel de administración** donde el cliente sube/edita sus autos él mismo.
> **Deadline:** mañana al mediodía (el banco revisa esta sección para dar crédito).
> **Regla de oro:** NO tocar el tema ni los plugins de WordPress. Todo se agrega como
> bloque HTML / iframe → riesgo cero para la web actual.

---

## 1. Arquitectura recomendada (la misma que ya funciona en Promax)

```
[ Panel Admin (HTML, con login) ]  --escribe-->  [ Supabase: tabla carquest_inventory ]
                                                         |
                                                         | lee (REST, anon key)
                                                         v
[ Widget de Inventario (HTML+CSS+JS) ]  <--incrustado-->  [ Página de WordPress ]
```

Tres piezas, todas independientes de WordPress:

1. **Base de datos — Supabase.** Ya existe la infraestructura de UCallNow (`db.ucallnow.fun`).
   Solo se crea una tabla nueva `carquest_inventory`. (Misma Supabase que Promax, tabla aparte.)
2. **Panel de admin** — una página HTML autocontenida, protegida con login, que hace
   crear / editar / borrar autos. Se aloja en Vercel (igual que `/admin/` de Promax) o subdominio.
3. **Widget de inventario** — un bloque HTML+CSS+JS autocontenido que lee de Supabase y
   muestra la grilla con filtros, orden y galería, en los **colores de CarQuest**. Se incrusta
   en una página de WordPress con un bloque **"HTML personalizado"** o un **iframe** a una
   página alojada en Vercel.

**Por qué así:** no se modifica WordPress (ni tema ni plugins), el cliente sube autos sin
entrar a WordPress, y es el mismo patrón ya probado en producción en Promax → escalable.

---

## 2. Esquema de la tabla en Supabase (SQL — copiar/pegar en el SQL Editor)

```sql
create table if not exists carquest_inventory (
  id              text primary key,          -- slug único estable, ej: ford-f150-xlt-2022
  stock           text,
  vin             text,
  year            int,
  make            text,
  model           text,
  trim            text,
  body_type       text,                      -- SUV, Sedan, Truck, Van...
  price           numeric,
  msrp            numeric,
  mileage         int,
  fuel            text,
  transmission    text,
  drivetrain      text,                      -- FWD, AWD, RWD, 4WD
  exterior_color  text,
  interior_color  text,
  badge           text,                      -- "Oferta", "Recién llegado"...
  featured        boolean default false,
  cover_image     text,                      -- URL de la foto principal
  gallery         jsonb   default '[]',      -- array de URLs de fotos
  features        jsonb   default '[]',      -- array de strings
  description     text,
  status          text    default 'available', -- available | sold | hidden
  created_at      timestamptz default now()
);

-- Seguridad (RLS): el público SOLO lee autos disponibles; escribir requiere login.
alter table carquest_inventory enable row level security;

create policy "lectura publica disponibles"
  on carquest_inventory for select
  using (status = 'available');

create policy "escritura solo autenticado"
  on carquest_inventory for all
  to authenticated
  using (true) with check (true);
```

---

## 3. Cómo lee/escribe la data (patrón exacto de Promax)

**Leer (widget público, con anon key):**
```
GET https://db.ucallnow.fun/rest/v1/carquest_inventory?select=*&status=eq.available&order=created_at.desc
Headers:
  apikey: <ANON_KEY>
  Authorization: Bearer <ANON_KEY>
```
> Si la tabla está vacía o falla, hacer fallback a un `inventory.json` local (como en Promax)
> para que el widget nunca se vea roto.

**Escribir (panel admin, usuario autenticado):**
- `POST` para crear, `PATCH ?id=eq.<id>` para editar, `DELETE ?id=eq.<id>` para borrar.
- Las fotos: subirlas a **Supabase Storage** (bucket `carquest`) y guardar las URLs en
  `cover_image` + `gallery`, **o** permitir pegar URLs (Cloudinary, etc.) si se quiere ir más rápido.

---

## 4. Pasos para el Claude que lo construya

1. **Colores de marca:** abrir https://carquestautogroup.com, extraer la paleta real
   (logo, header, botones) y definir variables CSS `--brand`, `--brand-2`, `--ink`, `--bg`.
   No inventar colores: tomarlos de la web.
2. **Supabase:** crear la tabla con el SQL de arriba + activar RLS. Crear un usuario admin
   (Supabase Auth, email/clave) para el login del panel.
3. **Panel admin** (1 archivo HTML): pantalla de login (Supabase Auth) → formulario para
   cargar un auto (campos de la tabla + subir varias fotos) → lista de autos con botones
   Editar / Borrar / Marcar vendido. Estética limpia y bonita (mejor que la de Promax).
4. **Widget inventario** (1 archivo HTML): `fetch` a Supabase → render de tarjetas con
   foto, precio, año, millaje, badge; filtros (marca / precio / año / tipo) y orden;
   responsive; modal o página de detalle con galería. Todo en los colores de CarQuest.
5. **Alojar** ambos en Vercel (deploy estático) o el hosting que usen.
6. **Incrustar en WordPress:** editar la página destino → agregar bloque **"HTML personalizado"**
   con el widget (o un `<iframe>` a la página de Vercel, con `width:100%` y alto generoso).
7. **Cargar 6–12 autos reales** para la revisión del banco.

---

## 5. Fast-track si el tiempo aprieta (para tener algo al mediodía)

El banco quiere **VER** la sección de inventario funcionando. Orden sugerido:

1. **Primero el WIDGET con autos reales** (la grilla bonita) — incrustado en WordPress.
   Para ir más rápido, los primeros autos pueden ir en un `inventory.json` o array fijo;
   se ve profesional y carga al instante. **Esto es lo que el banco necesita ver.**
2. **Después** el panel de admin self-service (Supabase + login). Se conecta sin tocar el widget.

Así se entrega algo sólido a tiempo y el autoservicio llega enseguida.

---

## 6. Seguridad (importante)

- Las credenciales de WordPress y las API keys van **solo** al desarrollador / sesión de
  confianza. Recomiendo **cambiar la contraseña de WordPress** al terminar el proyecto.
- El panel de admin **debe** tener login real (Supabase Auth) y las escrituras protegidas
  por RLS — nunca dejar una service-role key dentro de una página pública.
- El widget público usa solo la **anon key** (de solo lectura por RLS): seguro de exponer.

---

## 7. Brief listo para pegarle al otro Claude

```
Necesito agregar a una web WordPress existente (carquestautogroup.com) una sección de
INVENTARIO DE AUTOS con los colores de la marca, más un PANEL DE ADMIN donde el dueño
sube/edita sus autos. NO debes modificar el tema ni los plugins de WordPress: el inventario
se incrusta como bloque "HTML personalizado" o iframe.

Arquitectura (reutiliza un patrón ya probado):
1) Supabase (db.ucallnow.fun) con una tabla nueva `carquest_inventory` + RLS (lectura
   pública de status='available'; escritura solo autenticado).
2) Panel admin = 1 archivo HTML con login (Supabase Auth) que hace CRUD sobre la tabla,
   incluyendo subir varias fotos por auto (Supabase Storage o URLs).
3) Widget inventario = 1 archivo HTML+CSS+JS que lee la tabla por REST (anon key) y muestra
   grilla con filtros (marca/precio/año/tipo), orden, badges y galería, responsive, en los
   colores de CarQuest (extráelos de la web real). Fallback a inventory.json si la tabla
   está vacía.
Aloja ambos en Vercel e incrústalos en WordPress. Carga 6–12 autos reales.

Te paso el esquema SQL de la tabla, el patrón de lectura/escritura de Supabase y los pasos.
Prioriza tener el WIDGET con autos reales listo primero (el banco revisa esa sección mañana
al mediodía); el panel self-service puede ir justo después.
```
```
(El esquema SQL y los patrones REST están en las secciones 2 y 3 de este documento — pásaselos también.)
```
```
```
