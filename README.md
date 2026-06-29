# CarQuest Auto Group — Inventario + Panel de Admin

Sección de **inventario de autos** con los colores de la marca **CarQuest** + un **panel de
administración** donde el cliente sube/edita sus autos él mismo. Mismo patrón que ya funciona
en Promax (Supabase + widget + panel), pero independiente de WordPress: **no se toca el tema ni
los plugins** del sitio actual. El inventario se incrusta como bloque "HTML personalizado" o
`<iframe>` → riesgo cero para `carquestautogroup.com`.

```
[ admin.html (login + CRUD) ] --escribe--> [ Supabase: carquest_inventory ]
                                                   |  lee (REST, anon key)
                                                   v
[ index.html (widget grilla) ] <--iframe/HTML--> [ Página de WordPress ]
        |  fallback si Supabase está vacío
        v
   inventory.json
```

## Archivos

| Archivo           | Qué es                                                                    |
|-------------------|---------------------------------------------------------------------------|
| `index.html`      | **Widget público** del inventario (grilla, filtros, orden, galería). Lo que revisa el banco. |
| `admin.html`      | **Panel de admin** con login (Supabase Auth) y CRUD + subida de fotos.    |
| `config.js`       | **Único archivo a editar.** Pegas aquí la ANON KEY de Supabase. Colores y contactos de la marca. |
| `inventory.json`  | Autos de respaldo: el widget los muestra mientras Supabase no esté conectado (nunca se ve roto). |
| `schema.sql`      | SQL para crear la tabla + seguridad (RLS) + bucket de fotos. Copiar/pegar en Supabase. |
| `vercel.json`     | Config de hosting estático (headers, permite el iframe solo desde el dominio de CarQuest). |

Los colores se tomaron del sitio real: naranja `#ff4605`, header navy/negro `#0b0f1a`, tipografía
Mulish (equivalente a la "Muli" del sitio).

---

## Inicio rápido (ya funciona sin Supabase)

El widget arranca solo con `inventory.json`. Para verlo en local:

```bash
# desde la carpeta del proyecto
python3 -m http.server 8080
# abre http://localhost:8080/index.html
```

> Ábrelo con un servidor (no con doble-clic `file://`), porque `fetch('inventory.json')`
> necesita HTTP. Cualquier server estático sirve.

---

## Conectar Supabase (autoservicio del cliente)

1. **Crear la tabla y la seguridad.** Supabase → **SQL Editor** → pega TODO `schema.sql` → **Run**.
   Crea la tabla `carquest_inventory`, activa RLS (lectura pública solo de `status='available'`,
   escritura solo autenticado) y el bucket de fotos `carquest`.
2. **Crear el usuario admin.** Supabase → **Authentication → Users → Add user** (email + contraseña).
   Con eso entra el cliente a `admin.html`.
3. **Pegar la ANON KEY.** Supabase → **Project Settings → API** → copia el **anon public** key.
   Pégalo en `config.js`:
   ```js
   supabase: { url:"https://db.ucallnow.fun", anonKey:"PEGA_AQUI_LA_ANON_KEY", ... }
   ```
   - Con la key puesta, el widget lee de Supabase; el panel lee/escribe.
   - **La anon key es de solo lectura por RLS: es seguro exponerla.**
   - **NUNCA** pongas la `service_role` key aquí ni en ninguna página pública.

Si la tabla está vacía o falla la conexión, el widget cae a `inventory.json` automáticamente.

---

## Subir a Vercel (deploy estático)

No requiere build. Opciones:

- **Vercel CLI:** `npm i -g vercel` → `vercel` (en esta carpeta) → `vercel --prod`.
- **Vercel web:** importa el repo de GitHub; framework = *Other*; sin comando de build; output = raíz.

Quedan dos URLs públicas:
- `https://carquestautogroup.vercel.app/`            → widget de inventario
- `https://carquestautogroup.vercel.app/admin.html`  → panel de admin (login)

---

## Incrustar en WordPress (sin tocar tema ni plugins)

Edita la página destino (por ej. una nueva "Inventory") → agrega un bloque **"HTML personalizado"**
y pega esto (cambia la URL por la de tu Vercel). Incluye auto-ajuste de alto, sin scroll interno:

```html
<iframe id="cqInventory"
        src="https://carquestautogroup.vercel.app/"
        title="CarQuest Inventory"
        style="width:100%;border:0;display:block;min-height:1400px"
        loading="lazy"></iframe>
<script>
  window.addEventListener("message", function (e) {
    if (e.data && e.data.cqInventoryHeight) {
      document.getElementById("cqInventory").style.height = e.data.cqInventoryHeight + "px";
    }
  });
</script>
```

El widget le avisa al iframe su alto real (`postMessage`), así no quedan scrollbars feos.
`vercel.json` ya limita el iframe a los dominios de CarQuest (`frame-ancestors`).

> ¿Prefieres sin iframe? También puedes pegar el contenido de `index.html` dentro de un bloque
> "HTML personalizado", pero entonces hay que apuntar `config.js` e `inventory.json` a URLs
> absolutas de Vercel. El **iframe es lo más simple y limpio** (igual que en Promax).

Agrega "Car Finder"/"Inventory" al menú de WordPress apuntando a esa página.

---

## Usar el panel (`admin.html`)

- **Entrar:** email + contraseña del usuario que creaste en Supabase Auth.
- **Agregar auto:** botón *Agregar auto* → llena los datos → sube varias fotos (a Supabase Storage)
  o pega URLs → la primera foto es la portada (★ para cambiarla) → *Guardar*.
- **Editar / Vendido / Ocultar / Borrar:** botones de cada fila.
  - *Disponible* = visible en el widget. *Vendido* y *Oculto* = no aparecen al público.
  - *Destacar* (★) lo manda al inicio de la grilla.
- El ID/slug se autogenera de año-marca-modelo (botón *Generar*); es estable y único.

---

## Seguridad (importante)

- El **widget público** usa solo la **anon key** (solo-lectura por RLS): seguro de exponer.
- El **panel** exige login real (Supabase Auth); toda escritura está protegida por RLS.
- **Nunca** pongas la `service_role` key en `config.js` ni en ninguna página del cliente.
- `admin.html` lleva `noindex,nofollow` y `Cache-Control: no-store`. No lo enlaces público;
  compártelo solo con quien administra.
- Al terminar el proyecto, **cambia la contraseña de WordPress** y rota cualquier credencial
  que se haya compartido durante el desarrollo.

---

## Personalizar

Todo lo editable de marca/contacto/taxonomías está en `config.js`:
`brand` (colores, logo), `contact` (teléfono, email, dirección, links a aplicar crédito),
`taxonomy` (marcas, tipos de carrocería, combustibles, transmisiones, tracciones, asesores).
