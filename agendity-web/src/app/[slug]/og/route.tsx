import { ImageResponse } from 'next/og';

export const runtime = 'edge';

const API_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:3001';

const BUSINESS_TYPE_LABELS: Record<string, string> = {
  barbershop: 'Barbería',
  salon: 'Salón de belleza',
  spa: 'Spa',
  nails: 'Uñas',
  other: 'Servicios profesionales',
};

export async function GET(
  _request: Request,
  { params }: { params: Promise<{ slug: string }> }
) {
  const { slug } = await params;

  let business: {
    name: string;
    logo_url?: string;
    cover_url?: string;
    business_type?: string;
    city?: string;
    description?: string;
  } | null = null;

  try {
    const res = await fetch(`${API_URL}/api/v1/public/${slug}`, {
      next: { revalidate: 3600 },
    });
    if (res.ok) {
      const json = await res.json();
      business = json.data;
    }
  } catch {
    // fallback to generic
  }

  if (!business) {
    return new ImageResponse(
      (
        <div
          style={{
            background: '#1A1A2E',
            width: '100%',
            height: '100%',
            display: 'flex',
            flexDirection: 'column',
            alignItems: 'center',
            justifyContent: 'center',
          }}
        >
          <div style={{ fontSize: 48, fontWeight: 700, color: '#7c3aed' }}>
            Agendity
          </div>
          <div style={{ fontSize: 24, color: '#9ca3af', marginTop: 12 }}>
            Reserva tu cita online
          </div>
        </div>
      ),
      { width: 1200, height: 630 }
    );
  }

  const typeLabel = BUSINESS_TYPE_LABELS[business.business_type || 'other'] || 'Servicios profesionales';
  const hasCover = !!business.cover_url;
  const hasLogo = !!business.logo_url;

  return new ImageResponse(
    (
      <div
        style={{
          width: '100%',
          height: '100%',
          display: 'flex',
          flexDirection: 'column',
          position: 'relative',
          background: '#1A1A2E',
        }}
      >
        {/* Cover image as background */}
        {hasCover && (
          <img
            src={business.cover_url}
            style={{
              position: 'absolute',
              top: 0,
              left: 0,
              width: '100%',
              height: '100%',
              objectFit: 'cover',
              opacity: 0.3,
            }}
          />
        )}

        {/* Gradient overlay */}
        <div
          style={{
            position: 'absolute',
            top: 0,
            left: 0,
            width: '100%',
            height: '100%',
            background: hasCover
              ? 'linear-gradient(to top, rgba(26,26,46,0.95) 40%, rgba(26,26,46,0.7) 100%)'
              : 'linear-gradient(135deg, #1A1A2E 0%, #2D1B69 50%, #1A1A2E 100%)',
            display: 'flex',
          }}
        />

        {/* Content */}
        <div
          style={{
            position: 'relative',
            width: '100%',
            height: '100%',
            display: 'flex',
            flexDirection: 'column',
            alignItems: 'center',
            justifyContent: 'center',
            padding: 60,
          }}
        >
          {/* Logo */}
          {hasLogo ? (
            <img
              src={business.logo_url}
              style={{
                width: 120,
                height: 120,
                borderRadius: '50%',
                border: '4px solid rgba(124, 58, 237, 0.5)',
                objectFit: 'cover',
              }}
            />
          ) : (
            <div
              style={{
                width: 120,
                height: 120,
                borderRadius: '50%',
                background: '#7c3aed',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
                fontSize: 48,
                fontWeight: 700,
                color: 'white',
              }}
            >
              {business.name.charAt(0).toUpperCase()}
            </div>
          )}

          {/* Business name */}
          <div
            style={{
              fontSize: 56,
              fontWeight: 700,
              color: 'white',
              marginTop: 24,
              textAlign: 'center',
              lineHeight: 1.1,
              maxWidth: 900,
            }}
          >
            {business.name}
          </div>

          {/* Type + City */}
          <div
            style={{
              fontSize: 24,
              color: '#c4b5fd',
              marginTop: 12,
              display: 'flex',
              alignItems: 'center',
              gap: 8,
            }}
          >
            {typeLabel}
            {business.city && (
              <>
                <span style={{ color: '#6b7280' }}>·</span>
                <span>{business.city}</span>
              </>
            )}
          </div>

          {/* CTA */}
          <div
            style={{
              marginTop: 32,
              background: '#7c3aed',
              borderRadius: 12,
              padding: '14px 36px',
              fontSize: 22,
              fontWeight: 600,
              color: 'white',
            }}
          >
            Reserva tu cita online
          </div>

          {/* Agendity branding */}
          <div
            style={{
              position: 'absolute',
              bottom: 30,
              right: 40,
              display: 'flex',
              alignItems: 'center',
              gap: 8,
            }}
          >
            <div
              style={{
                width: 28,
                height: 28,
                borderRadius: '50%',
                background: '#7c3aed',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
                fontSize: 14,
                fontWeight: 700,
                color: 'white',
              }}
            >
              A
            </div>
            <span style={{ fontSize: 18, fontWeight: 600, color: '#7c3aed' }}>
              agendity.co
            </span>
          </div>
        </div>
      </div>
    ),
    { width: 1200, height: 630 }
  );
}
