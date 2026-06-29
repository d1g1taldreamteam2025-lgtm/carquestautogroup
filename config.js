/* =============================================================================
 * CarQuest Auto Group — Configuración compartida
 * -----------------------------------------------------------------------------
 * Este es el ÚNICO archivo que necesitas editar para conectar Supabase.
 * Lo usan tanto el widget público (index.html) como el panel admin (admin.html).
 *
 * 1) Pega tu ANON KEY de Supabase abajo (supabase.anonKey).
 *    - Mientras esté vacía (""), el widget muestra los autos de inventory.json.
 *    - Apenas la pongas, el widget y el panel leen/escriben en Supabase.
 * 2) La ANON KEY es de solo lectura (protegida por RLS): es SEGURO exponerla.
 *    NUNCA pongas la service_role key aquí ni en ninguna página pública.
 * ===========================================================================*/
window.CARQUEST = {
  supabase: {
    url:     "https://db.ucallnow.fun",
    anonKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9.CRXP1A7WOeoJeXxjNni43kdQwgnWNReilDMblYTn_I0",  // ANON KEY (role:anon, solo-lectura por RLS)
    table:   "carquest_inventory",
    bucket:  "carquest"                // bucket de Supabase Storage para fotos
  },

  /* Datos a falta de Supabase: el widget cae a este archivo y nunca se ve roto */
  fallbackJson: "inventory.json",

  /* Colores reales de la marca (extraídos de carquestautogroup.com) */
  brand: {
    name:         "CarQuest Auto Group",
    primary:      "#ff4605",   // naranja CarQuest
    primaryDark:  "#e23d02",
    primaryLight: "#fff0eb",
    nav:          "#0b0f1a",   // navy/negro del header
    navSoft:      "#121829",
    ink:          "#0e1320",
    logo:         "https://carquestautogroup.com/wp-content/uploads/2023/09/cq-logo.png",
    font:         "'Muli','Mulish',-apple-system,BlinkMacSystemFont,'Segoe UI',Arial,Helvetica,sans-serif"
  },

  contact: {
    phone:     "(714) 583-0908",
    phoneHref: "tel:+17145830908",
    email:     "customerservice@carquestautogroup.com",
    address:   "12235 Beach Blvd STE 104C, Stanton, CA 90680",
    mapUrl:    "https://maps.google.com/?q=12235+Beach+Blvd+STE+104C,+Stanton,+CA+90680",
    site:      "https://carquestautogroup.com",
    applyUrl:  "https://carquestautogroup.com/online-credit-application/",
    contactUrl:"https://carquestautogroup.com/contact-us/",
    facebook:  "https://www.facebook.com/carquestautogroup",
    instagram: "https://www.instagram.com/carquestautogroup/"
  },

  /* Taxonomías (tomadas del formulario real del sitio) */
  taxonomy: {
    makes: [
      "Acura","Alfa Romeo","Aston Martin","Audi","Bentley","BMW","Bugatti","Buick",
      "Cadillac","Chevrolet","Chrysler","Dodge","Ferrari","Fiat","Ford","Genesis","GMC",
      "Honda","Hyundai","Infiniti","Jaguar","Jeep","Kia","Lamborghini","Land Rover",
      "Lexus","Lincoln","Lotus","Maserati","Mazda","Mercedes-Benz","Mini","Mitsubishi",
      "Nissan","Porsche","Ram","Rolls-Royce","Smart","Subaru","Tesla","Toyota",
      "Volkswagen","Volvo"
    ],
    bodyTypes:     ["Sedan","SUV","Truck","Coupe","Hatchback","Convertible","Van","Minivan","Wagon"],
    fuels:         ["Gasoline","Hybrid","Electric","Diesel","Plug-in Hybrid"],
    transmissions: ["Automatic","Manual","CVT","Dual-Clutch"],
    drivetrains:   ["FWD","RWD","AWD","4WD"],
    advisors: [
      "Jerry Barcenas","Eddie Espana","Clinton Holland III","Erik Molina",
      "Tony Tapia","Mayra Torres","Arturo Valdovinos"
    ]
  }
};
