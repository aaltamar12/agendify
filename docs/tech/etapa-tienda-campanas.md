# Etapa: Tienda de Productos + Campanas de Cumpleanos

> Fecha: 2026-03-23
> Estado: Planificacion
> Disponible desde: Plan Profesional+

---

## 1. Tienda de Productos

### Concepto

Los negocios pueden vender productos relacionados a sus servicios (shampoo, cera, aceites, cremas, cepillos, etc.). Los productos se muestran durante el flujo de reserva para compra adicional, y tambien en una seccion del perfil publico del negocio.

**No es:** Una tienda general (no gaseosas, snacks, etc.). Son productos del rubro del negocio que complementan los servicios.

### Modelos de datos

```sql
-- Categorias de productos (por negocio)
CREATE TABLE product_categories (
  id bigint PRIMARY KEY,
  business_id bigint NOT NULL REFERENCES businesses(id),
  name varchar NOT NULL,
  sort_order integer DEFAULT 0,
  active boolean DEFAULT true,
  timestamps
);

-- Productos
CREATE TABLE products (
  id bigint PRIMARY KEY,
  business_id bigint NOT NULL REFERENCES businesses(id),
  product_category_id bigint REFERENCES product_categories(id),
  name varchar NOT NULL,
  description text,
  price decimal(12,2) NOT NULL,
  stock integer DEFAULT 0,           -- 0 = sin control de stock
  track_stock boolean DEFAULT false,  -- true = descuenta al vender
  active boolean DEFAULT true,
  timestamps
);
-- ActiveStorage: has_many_attached :images (max 3 por producto, max 5MB cada una)

-- Items vendidos (vinculados a cita o venta directa)
CREATE TABLE product_sales (
  id bigint PRIMARY KEY,
  business_id bigint NOT NULL REFERENCES businesses(id),
  product_id bigint NOT NULL REFERENCES products(id),
  appointment_id bigint REFERENCES appointments(id),  -- null si es venta directa
  customer_id bigint REFERENCES customers(id),
  employee_id bigint REFERENCES employees(id),        -- quien vendio
  quantity integer DEFAULT 1,
  unit_price decimal(12,2) NOT NULL,
  total_price decimal(12,2) NOT NULL,
  sold_at timestamp NOT NULL,
  timestamps
);
```

### Relaciones

```
Business --o{ ProductCategory --o{ Product (has_many_attached :images)
Business --o{ ProductSale
Appointment --o{ ProductSale (productos comprados al reservar)
Customer --o{ ProductSale
Employee --o{ ProductSale (quien vendio/recomendo)
```

### Flujos

**A. Compra durante reserva (flujo de booking):**
1. Usuario selecciona servicio + empleado + fecha/hora
2. Paso adicional: "Productos recomendados" (lista de productos del negocio)
3. Usuario agrega productos al carrito
4. Confirmacion muestra: servicio + productos + total
5. Al confirmar, se crean ProductSale vinculados a la cita

**B. Venta directa (desde dashboard del negocio):**
1. Negocio abre seccion "Productos" → "Registrar venta"
2. Selecciona producto, cantidad, cliente (opcional), empleado
3. Se crea ProductSale sin appointment_id

**C. Catalogo publico:**
1. Pagina publica del negocio muestra seccion "Productos"
2. Solo informativo (precio, foto, descripcion)
3. Para comprar, debe reservar o ir al negocio

### Impacto en storage

| Concepto | Calculo | Storage |
|----------|---------|---------|
| Imagenes por producto | Max 3 fotos × 5 MB = 15 MB | Fijo por producto |
| Productos por negocio (estimado) | 10-30 productos | 150-450 MB por negocio |
| 30 negocios × 20 productos × 2 fotos × 3 MB | 3,600 MB | ~3.6 GB (fijo, no acumulativo) |
| 300 negocios × 20 productos × 2 fotos × 3 MB | 36,000 MB | ~36 GB (fijo) |
| DB records (product_sales) | ~50 bytes por registro | Despreciable |

**Nota:** Las imagenes de productos son fijas (no acumulativas como comprobantes). Se suben una vez y se reemplazan ocasionalmente. El impacto principal es storage fijo, no crecimiento mensual.

### Impacto en costos operativos

| Escala | Storage adicional (fijo) | Emails adicionales/mes | WhatsApp adicional | Costo adicional/mes |
|--------|------------------------|----------------------|-------------------|-------------------|
| 30 negocios | +3.6 GB | ~0 (ya incluido en confirmacion) | ~0 | **$0** |
| 300 negocios | +36 GB | ~0 | ~0 | **$0** (si cabe en disco) |

Los productos no generan notificaciones adicionales — la confirmacion de reserva ya incluye el detalle de lo comprado. El unico costo es storage.

### Impacto en cierre de caja

ProductSale se integra con CashRegisterClose:
- Resumen del dia incluye: ingresos por servicios + ingresos por productos
- Comisiones de empleados pueden incluir ventas de productos (configurable)
- Reportes: top productos vendidos, ingresos por categoria

### Restriccion de plan

| Plan | Productos | Categorias | Imagenes por producto |
|------|-----------|------------|----------------------|
| Basico | No disponible | — | — |
| Profesional | Hasta 30 | Hasta 5 | Hasta 3 |
| Inteligente | Ilimitados | Ilimitadas | Hasta 5 |

### Endpoints API

```
GET    /api/v1/products                    # Listar productos del negocio
POST   /api/v1/products                    # Crear producto
PATCH  /api/v1/products/:id                # Actualizar
DELETE /api/v1/products/:id                # Eliminar
POST   /api/v1/products/:id/upload_image   # Subir imagen
DELETE /api/v1/products/:id/delete_image   # Eliminar imagen

GET    /api/v1/product_categories           # Listar categorias
POST   /api/v1/product_categories           # Crear
PATCH  /api/v1/product_categories/:id       # Actualizar
DELETE /api/v1/product_categories/:id       # Eliminar

POST   /api/v1/product_sales               # Registrar venta
GET    /api/v1/product_sales               # Historial de ventas

GET    /api/v1/public/:slug/products       # Catalogo publico del negocio
```

### Frontend

| Pagina | Descripcion |
|--------|-------------|
| `/dashboard/products` | CRUD de productos con categorias, imagenes, stock |
| `/dashboard/products/sales` | Historial de ventas con filtros |
| `/[slug]` | Seccion "Productos" en perfil publico |
| Flujo de reserva (paso adicional) | "Agregar productos" entre datos del cliente y confirmacion |
| Cierre de caja | Ingresos por productos incluidos en resumen |

---

## 2. Campanas de Cumpleanos

### Concepto

El sistema envia automaticamente una felicitacion + descuento al usuario final el dia de su cumpleanos. Esto incentiva que vuelva a reservar.

### Requisito previo

Agregar campo `birth_date` al modelo Customer:

```sql
ALTER TABLE customers ADD COLUMN birth_date date;
```

Se captura opcionalmente en el formulario de reserva (campo "Fecha de nacimiento" no obligatorio).

### Flujo

```
BirthdayCampaignJob (cron diario 8am)
  |
  → Busca customers con birth_date.day == hoy.day && birth_date.month == hoy.month
  → Para cada customer con citas en negocios Pro+:
      |
      → Genera codigo de descuento temporal (24-48h de vigencia)
      → MultiChannelService:
          - Email: "Feliz cumpleanos! Tu descuento de X% te espera en {business}"
          - WhatsApp (Pro+): template birthday_greeting
      → Crea Notification in-app para el negocio: "Hoy es cumpleanos de {customer}"
```

### Modelo de datos

```sql
-- Codigos de descuento (tambien usable para promos futuras)
CREATE TABLE discount_codes (
  id bigint PRIMARY KEY,
  business_id bigint NOT NULL REFERENCES businesses(id),
  customer_id bigint REFERENCES customers(id),  -- null = para todos
  code varchar NOT NULL,
  discount_type integer DEFAULT 0,  -- 0=percentage, 1=fixed_amount
  discount_value decimal(12,2) NOT NULL,
  min_purchase decimal(12,2) DEFAULT 0,
  max_uses integer DEFAULT 1,
  uses_count integer DEFAULT 0,
  valid_from timestamp,
  valid_until timestamp,
  active boolean DEFAULT true,
  source varchar DEFAULT 'manual',  -- 'birthday', 'campaign', 'manual', 'referral'
  timestamps
);
CREATE UNIQUE INDEX ON discount_codes(business_id, code);
```

### Configuracion por negocio

```sql
-- En tabla businesses (o business_settings):
birthday_campaign_enabled boolean DEFAULT false
birthday_discount_pct decimal(5,2) DEFAULT 10  -- 10% descuento de cumpleanos
```

El negocio activa/desactiva la campana desde Settings. El SuperAdmin puede configurar defaults por plan.

### Impacto en costos

| Concepto | Calculo | Costo |
|----------|---------|-------|
| Email por cumpleanos | 1 email por customer/ano | Despreciable (Spacemail) |
| WhatsApp por cumpleanos (Pro+) | 1 MARKETING conversation | $0.0164 (Colombia) |
| Notificacion in-app al negocio | 1 insert DB | $0 |

**Estimacion por escala:**

| Negocios | Customers con birth_date (~30%) | Cumpleanos/mes | Emails | WhatsApp (60% Pro+) | Costo WA/mes |
|----------|---------------------------------|----------------|--------|---------------------|-------------|
| 30 | ~2,000 | ~170 | 170 | ~100 | $1.64 |
| 300 | ~20,000 | ~1,700 | 1,700 | ~1,000 | $16.40 |
| 5,000 | ~330,000 | ~28,000 | 28,000 | ~17,000 | $278.80 |

**Costo mensual adicional: despreciable.** ~$1.6/mes a 30 negocios, ~$16/mes a 300. Es una feature de alto valor percibido con costo minimo.

### Templates WhatsApp

```
Template: birthday_greeting (MARKETING)
Idioma: es
Cuerpo:
  Feliz cumpleanos {{1}}! 🎂

  {{2}} te regala un {{3}}% de descuento en tu proximo servicio.

  Usa el codigo {{4}} antes del {{5}}.

  Reserva aqui: {{6}}

Variables:
  {{1}} = customer.name
  {{2}} = business.name
  {{3}} = discount_pct
  {{4}} = discount_code
  {{5}} = valid_until (formato fecha)
  {{6}} = booking_url
```

### Endpoints API

```
GET  /api/v1/campaigns/birthdays          # Lista de cumpleanos del mes (para el negocio)
POST /api/v1/settings/birthday_campaign   # Activar/desactivar + configurar %

# Discount codes (reutilizable para promos futuras)
GET  /api/v1/discount_codes               # Listar codigos del negocio
POST /api/v1/discount_codes               # Crear codigo manual
GET  /api/v1/public/:slug/validate_code   # Validar codigo al reservar
```

### Restriccion de plan

| Plan | Campana cumpleanos | Codigos descuento |
|------|-------------------|------------------|
| Basico | No | No |
| Profesional | Si (email) | Hasta 10 activos |
| Inteligente | Si (email + WhatsApp) | Ilimitados |

---

## 3. Resumen de impacto operativo conjunto

### Storage adicional (productos + campanas)

| Escala | Productos (fijo) | Campanas (DB) | Total adicional |
|--------|-----------------|---------------|-----------------|
| 30 negocios | +3.6 GB | Despreciable | +3.6 GB |
| 300 negocios | +36 GB | Despreciable | +36 GB |

A 300 negocios con VPS de 200 GB: 36 GB de productos + storage actual (~60 GB acumulado) = ~96 GB de 185 GB disponibles. **Cabe sin Supabase.**

### Costo operativo adicional mensual

| Escala | WhatsApp cumpleanos | Email cumpleanos | Storage | Total adicional |
|--------|-------------------|-----------------|---------|----------------|
| 30 negocios | +$1.64 | $0 (Spacemail) | $0 | **+$1.64** |
| 300 negocios | +$16.40 | $0 | $0 | **+$16.40** |
| 5,000 negocios | +$278.80 | Incluido en SES | $0-25 | **+$278-304** |

### Costo total actualizado con tienda + campanas

| Escala | Antes | Despues | Diferencia |
|--------|-------|---------|------------|
| 30 negocios (con WA) | $161/mes | **$163/mes** | +$2 |
| 300 negocios | $1,465/mes | **$1,481/mes** | +$16 |
| 5,000 LATAM | $32,412/mes | **$32,690/mes** | +$278 |

**Conclusion:** El impacto en costos es minimo. La tienda es puro storage fijo (imagenes de productos) y la campana de cumpleanos es ~$0.016 por felicitacion. Son features de alto valor percibido con costo casi cero.

---

## 4. Orden de implementacion sugerido

**Etapa A — Campanas de cumpleanos + codigos de descuento:**
1. Migracion: `birth_date` en customers
2. Modelo DiscountCode (reutilizable para todo)
3. BirthdayCampaignJob (cron diario)
4. MultiChannel template birthday_greeting
5. Settings UI para activar/desactivar
6. Validacion de codigo en flujo de reserva
7. Specs:
   - Model specs: DiscountCode (validaciones, scopes, vigencia, usos)
   - Service specs: aplicacion de codigo sobre subtotal con tarifa dinamica
   - Job specs: BirthdayCampaignJob (genera codigo, envia MultiChannel)
   - Request specs: validate_code endpoint, crear/listar codigos
   - Integracion: tarifa dinamica + descuento + creditos (las 3 capas juntas)

**Etapa B — Tienda de productos:**
1. Modelos: ProductCategory, Product, ProductSale
2. ActiveStorage: images en Product (validaciones de tamano/tipo)
3. CRUD dashboard
4. Catalogo publico
5. Integracion con flujo de reserva (paso adicional)
6. Integracion con cierre de caja
7. Reportes de ventas
8. Specs:
   - Model specs: Product (validaciones, stock, categorias), ProductSale (calculos)
   - Request specs: CRUD productos, upload imagenes, registrar venta, catalogo publico
   - Service specs: venta con descuento de stock, integracion con cierre de caja
   - Integracion: reserva con productos + tarifa dinamica + descuento + creditos

---

## 5. Orden de aplicacion de descuentos

Las tarifas dinamicas, codigos de descuento y creditos conviven como capas independientes:

```
Precio base del servicio (ej: $25,000)
  |
  1. Tarifa dinamica (automatica, del negocio/IA, sobre precio base)
  |   → -15% = -$3,750
  |   Subtotal: $21,250
  |
  2. Codigo de descuento (manual, del usuario, sobre subtotal)
  |   → -10% = -$2,125
  |   Subtotal: $19,125
  |
  3. Creditos/cashback (opcional, del usuario, sobre total)
  |   → -$5,000 de saldo
  |   Total a pagar: $14,125
```

| Capa | Quien la define | Cuando aplica | Sobre que | Acumulable |
|------|----------------|---------------|-----------|------------|
| Tarifa dinamica | Negocio/IA (por dia/hora) | Automatico segun reglas | Precio base del servicio | Si |
| Codigo de descuento | Campana/manual | Usuario ingresa codigo | Subtotal despues de tarifa | Si |
| Creditos/cashback | Sistema | Usuario elige aplicar | Total despues de descuento | Si |

**Las 3 capas se acumulan.** Un usuario de cumpleanos en hora valle con creditos acumulados puede beneficiarse de las 3.

**Specs obligatorios para esta interaccion:**
- Caso: tarifa dinamica -15% + codigo cumpleanos -10% + creditos $5,000 = total correcto
- Caso: tarifa dinamica +20% (hora pico) + codigo descuento -10% = total correcto
- Caso: solo codigo sin tarifa dinamica
- Caso: solo creditos sin codigo ni tarifa
- Caso: codigo expirado o ya usado → rechazado
- Caso: creditos insuficientes → aplica parcial
