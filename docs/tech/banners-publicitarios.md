# Banners Publicitarios (Ad Banners)

## Descripcion

Sistema de banners publicitarios que se muestran en la pagina publica de Explore. Gestionados desde ActiveAdmin con tracking de impresiones y clicks.

## Modelo

```ruby
# app/models/ad_banner.rb
class AdBanner < ApplicationRecord
  # Campos: title, image_url, link_url, position, active,
  #         impressions_count, clicks_count, starts_at, ends_at

  has_one_attached :image

  scope :active_now, -> {
    where(active: true)
      .where("starts_at <= ? OR starts_at IS NULL", Time.current)
      .where("ends_at >= ? OR ends_at IS NULL", Time.current)
  }
end
```

## Endpoints (publicos, sin auth)

```
GET  /api/v1/public/ad_banners              # Listar banners activos
POST /api/v1/public/ad_banners/:id/impression  # Registrar impresion
POST /api/v1/public/ad_banners/:id/click       # Registrar click
```

## Gestion desde ActiveAdmin

1. ActiveAdmin > Ad Banners
2. Crear banner: titulo, imagen, URL de destino, posicion, fechas de vigencia
3. Ver metricas: impresiones, clicks, CTR

## Frontend

Los banners se muestran en la pagina `/explore` entre los resultados de busqueda.

## Archivos clave

- `app/models/ad_banner.rb`
- `app/controllers/api/v1/public/ad_banners_controller.rb`
- `app/admin/ad_banners.rb`
- `agendity-web/src/app/explore/page.tsx`
