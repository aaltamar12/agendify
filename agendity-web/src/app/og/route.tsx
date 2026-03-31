import { ImageResponse } from 'next/og';

export const runtime = 'edge';

export async function GET() {
  return new ImageResponse(
    (
      <div
        style={{
          width: '100%',
          height: '100%',
          display: 'flex',
          flexDirection: 'column',
          alignItems: 'center',
          justifyContent: 'center',
          background: 'linear-gradient(135deg, #1A1A2E 0%, #2D1B69 40%, #1A1A2E 100%)',
          position: 'relative',
        }}
      >
        {/* Glow effect */}
        <div
          style={{
            position: 'absolute',
            top: '50%',
            left: '50%',
            transform: 'translate(-50%, -60%)',
            width: 400,
            height: 400,
            borderRadius: '50%',
            background: 'radial-gradient(circle, rgba(124,58,237,0.3) 0%, transparent 70%)',
          }}
        />

        {/* Logo "a" */}
        <div
          style={{
            width: 120,
            height: 120,
            borderRadius: '50%',
            background: 'linear-gradient(135deg, #7c3aed 0%, #6C3BF5 100%)',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            fontSize: 64,
            fontWeight: 700,
            color: 'white',
            boxShadow: '0 0 60px rgba(124,58,237,0.4)',
          }}
        >
          a
        </div>

        {/* Brand name */}
        <div
          style={{
            fontSize: 72,
            fontWeight: 700,
            color: 'white',
            marginTop: 20,
            letterSpacing: -1,
          }}
        >
          Agendity
        </div>

        {/* Tagline */}
        <div
          style={{
            fontSize: 28,
            color: '#c4b5fd',
            marginTop: 8,
          }}
        >
          Reservas online para tu negocio de servicios
        </div>

        {/* Features row */}
        <div
          style={{
            display: 'flex',
            gap: 32,
            marginTop: 40,
            fontSize: 18,
            color: '#9ca3af',
          }}
        >
          <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
            <div style={{ color: '#7c3aed', fontSize: 20 }}>✓</div>
            Citas y empleados
          </div>
          <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
            <div style={{ color: '#7c3aed', fontSize: 20 }}>✓</div>
            Pagos y reportes
          </div>
          <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
            <div style={{ color: '#7c3aed', fontSize: 20 }}>✓</div>
            WhatsApp automático
          </div>
        </div>

        {/* CTA */}
        <div
          style={{
            marginTop: 36,
            background: '#7c3aed',
            borderRadius: 12,
            padding: '14px 40px',
            fontSize: 22,
            fontWeight: 600,
            color: 'white',
          }}
        >
          Empieza gratis → agendity.co
        </div>

        {/* Bottom bar */}
        <div
          style={{
            position: 'absolute',
            bottom: 0,
            left: 0,
            right: 0,
            height: 4,
            background: 'linear-gradient(90deg, #7c3aed, #6C3BF5, #7c3aed)',
          }}
        />
      </div>
    ),
    { width: 1200, height: 630 }
  );
}
