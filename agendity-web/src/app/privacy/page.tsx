import type { Metadata } from 'next';

export const metadata: Metadata = {
  title: 'Política de Privacidad — Agendity',
};

export default function PrivacyPage() {
  return (
    <div className="mx-auto max-w-3xl px-6 py-12">
      <h1 className="mb-8 text-3xl font-bold text-gray-900">Política de Privacidad</h1>
      <div className="prose prose-gray max-w-none">
        <p className="text-gray-500">Última actualización: Marzo 2026</p>
        <p>En cumplimiento de la Ley 1581 de 2012 y el Decreto 1377 de 2013 de Colombia, Agendity informa sobre el tratamiento de datos personales.</p>
        <h2>1. Responsable del tratamiento</h2>
        <p>Agendity, con domicilio en Barranquilla, Colombia. Contacto: soporte@agendity.com</p>
        <h2>2. Datos que recopilamos</h2>
        <p><strong>Clientes (negocios):</strong> Nombre, email, teléfono, dirección del negocio, datos de pago (encriptados), información fiscal.</p>
        <p><strong>Usuarios finales:</strong> Nombre, email, teléfono, fecha de nacimiento (opcional), historial de citas.</p>
        <h2>3. Finalidad del tratamiento</h2>
        <p>Gestión de citas y reservas, comunicaciones transaccionales (confirmaciones, recordatorios), análisis estadístico del negocio, cumplimiento de obligaciones legales.</p>
        <h2>4. Derechos del titular (ARCO)</h2>
        <p>Tienes derecho a: <strong>Acceder</strong> a tus datos, <strong>Rectificarlos</strong>, <strong>Cancelar</strong> su uso, y <strong>Oponerte</strong> al tratamiento. Para ejercer estos derechos, escríbenos a soporte@agendity.com</p>
        <h2>5. Seguridad</h2>
        <p>Los datos de pago se almacenan con encriptación AES-256. Las comunicaciones usan HTTPS/TLS. Acceso restringido por roles y autenticación JWT.</p>
        <h2>6. Transferencia de datos</h2>
        <p>Los datos pueden transferirse a proveedores de servicios (email, hosting) ubicados fuera de Colombia, cumpliendo con las garantías de la Ley 1581.</p>
        <h2>7. Cookies</h2>
        <p>Usamos cookies esenciales para autenticación y preferencias. No usamos cookies de tracking publicitario.</p>
        <h2>8. Retención de datos</h2>
        <p>Los datos se conservan mientras la cuenta esté activa. Al cancelar, se eliminan en un plazo de 30 días, salvo obligación legal de conservación.</p>
        <h2>9. Notificaciones (WhatsApp/Email)</h2>
        <p>Al usar el servicio, el usuario final acepta recibir notificaciones transaccionales. Las notificaciones de marketing requieren consentimiento explícito (opt-in).</p>
        <h2>10. Contacto</h2>
        <p>Para consultas sobre privacidad: soporte@agendity.com</p>
      </div>
    </div>
  );
}
