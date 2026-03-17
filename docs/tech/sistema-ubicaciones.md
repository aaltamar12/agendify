# Sistema de Ubicaciones Geográficas

> Última actualización: 2026-03-17

## Resumen

Sistema de selección jerárquica de ubicación (País → Estado/Departamento → Ciudad) usando la gema `city-state` que provee datos de **251 países** con sus estados y ciudades vía la base de datos MaxMind.

## Stack

| Componente | Tecnología |
|---|---|
| Datos geográficos | Gema `city-state` v1.1.0 (MaxMind DB) |
| API | `LocationsController` (3 endpoints públicos) |
| Frontend | Hook `use-locations.ts` (TanStack Query) |
| ActiveAdmin | JavaScript con cascading selects + Select2 |

## Convención de almacenamiento

Los negocios almacenan ubicación con esta convención:

| Campo | Formato | Ejemplo |
|---|---|---|
| `country` | Código ISO 2 letras | `"CO"` |
| `state` | Código del gem city-state | `"ATL"`, `"DC"`, `"ANT"` |
| `city` | Nombre completo | `"Barranquilla"`, `"Medellín"` |

> **Importante:** country y state son **códigos**, city es **nombre**. Esto permite lookup eficiente en el gem sin depender de acentos o variaciones de escritura.

## API Endpoints

Los 3 endpoints son **públicos** (sin autenticación). El controller hereda de `ApiController`, no de `BaseController`.

### GET /api/v1/locations/countries

Lista todos los países.

```bash
curl http://localhost:3001/api/v1/locations/countries
```

```json
{
  "data": [
    { "code": "AF", "name": "Afghanistan" },
    { "code": "CO", "name": "Colombia" },
    ...
  ]
}
```

### GET /api/v1/locations/states?country=CO

Lista estados/departamentos de un país. Los nombres se limpian automáticamente (ej: "Departamento de Bolívar" → "Bolivar").

```bash
curl "http://localhost:3001/api/v1/locations/states?country=CO"
```

```json
{
  "data": [
    { "code": "AMA", "name": "Amazonas" },
    { "code": "ANT", "name": "Antioquia" },
    { "code": "ATL", "name": "Atlántico" },
    { "code": "DC", "name": "Bogota D.C." },
    ...
  ]
}
```

### GET /api/v1/locations/cities?country=CO&state=ATL

Lista ciudades de un estado.

```bash
curl "http://localhost:3001/api/v1/locations/cities?country=CO&state=ATL"
```

```json
{
  "data": [
    { "name": "Baranoa" },
    { "name": "Barranquilla" },
    { "name": "Soledad" },
    ...
  ]
}
```

## Archivos clave

### Backend

| Archivo | Descripción |
|---|---|
| `config/initializers/city_state.rb` | Require de la gema (necesario porque no autoload) |
| `app/controllers/api/v1/locations_controller.rb` | Controller con 3 endpoints |
| `config/routes.rb` | Rutas bajo `api/v1/locations/*` |
| `app/admin/businesses.rb` | JavaScript inline para cascading selects en ActiveAdmin |

### Frontend

| Archivo | Descripción |
|---|---|
| `src/lib/hooks/use-locations.ts` | Hooks `useCountries()`, `useStates(country)`, `useCities(country, state)` |
| `src/lib/api/endpoints.ts` | `ENDPOINTS.LOCATIONS.*` |
| `src/app/dashboard/settings/page.tsx` | Selects en cascada en ProfileSection |
| `src/components/onboarding/step-business-profile.tsx` | Selects en cascada en onboarding |

## Frontend — Patrón de selects en cascada

Los selects tienen un problema de timing: el form se monta con `defaultValues` antes de que las opciones async carguen. Se resuelve con `key` prop:

```tsx
<Select
  key={`country-${countriesData?.data?.length ?? 0}`}
  options={[
    { value: '', label: 'Seleccionar país...' },
    ...(countriesData?.data?.map((c) => ({ value: c.code!, label: c.name })) ?? []),
  ]}
  {...register('country', {
    onChange: () => { setValue('state', ''); setValue('city', ''); },
  })}
/>
```

El `key` cambia cuando las opciones pasan de 0 a N, forzando un re-mount del `<select>`. Al re-montarse, react-hook-form re-registra el ref con el valor del form state ("CO"), y ahora sí hay un `<option value="CO">` disponible.

Los hooks usan `staleTime: Infinity` porque los datos geográficos no cambian.

## ActiveAdmin — Cascading selects con Select2

El form de Business en ActiveAdmin usa JavaScript inline que:

1. Espera a que Select2 se inicialice (`$(document).ready + setTimeout`)
2. Escucha cambios con `$(el).on('change')` (compatible con Select2)
3. Hace `fetch()` al API de locations
4. Destruye Select2, repopula opciones, re-crea Select2

```js
// Patrón: destroy → populate → re-init
function refreshSelect(el, items, placeholder, selectedValue) {
  var $el = $(el);
  try { $el.select2('destroy'); } catch(e) {}
  el.innerHTML = '<option value="">' + placeholder + '</option>';
  items.forEach(function(item) { ... });
  $el.select2({ allowClear: true, placeholder: placeholder });
}
```

## Datos disponibles para Colombia

La gema incluye los 32 departamentos de Colombia + Bogotá D.C.:

| Código | Departamento |
|---|---|
| ATL | Atlántico |
| ANT | Antioquia |
| DC | Bogota D.C. |
| BOL | Bolivar |
| VAC | Valle del Cauca |
| SAN | Santander |
| ... | (32 total) |

Cada departamento incluye sus ciudades principales (ej: ATL tiene 17 ciudades incluyendo Barranquilla, Soledad, Malambo).
