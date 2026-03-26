import type { Metadata } from 'next';

export const metadata: Metadata = {
  title: 'Términos y Condiciones — Agendity',
};

export default function TermsPage() {
  return (
    <div className="mx-auto max-w-3xl px-6 py-12">
      <h1 className="mb-8 text-3xl font-bold text-gray-900">Términos y Condiciones</h1>
      <div className="prose prose-gray max-w-none">
        <p className="text-gray-500">Última actualización: Marzo 2026</p>
        <p>Al usar Agendity, aceptas estos términos y condiciones que regulan el uso de nuestra plataforma.</p>
        <h2>1. Definiciones</h2>
        <p><strong>Agendity</strong> es una plataforma SaaS de gestión de citas. <strong>Cliente</strong> se refiere al negocio que contrata el servicio. <strong>Usuario final</strong> es la persona que reserva citas.</p>
        <h2>2. Uso del servicio</h2>
        <p>El servicio está disponible para negocios que trabajan con citas en Colombia. El cliente es responsable de la información que publica.</p>
        <h2>3. Periodo de prueba</h2>
        <p>Agendity ofrece 25 días de prueba gratuita con acceso completo. Al finalizar, el cliente debe elegir un plan de pago para continuar.</p>
        <h2>4. Pagos y suscripciones</h2>
        <p>Los pagos se realizan mediante transferencia bancaria. Las suscripciones son mensuales y se renuevan manualmente.</p>
        <h2>5. Cancelación</h2>
        <p>El cliente puede cancelar su suscripción en cualquier momento. No se realizan reembolsos por periodos parciales.</p>
        <h2>6. Protección de datos</h2>
        <p>Agendity cumple con la Ley 1581 de 2012 de Colombia sobre protección de datos personales. Ver nuestra <a href="/privacy" className="text-violet-600 hover:underline">Política de Privacidad</a> para más detalles.</p>
        <h2>7. Limitación de responsabilidad</h2>
        <p>Agendity no es responsable por pérdidas derivadas del uso de la plataforma. El servicio se ofrece &quot;tal cual&quot;.</p>
        <h2>8. Modificaciones</h2>
        <p>Nos reservamos el derecho de modificar estos términos. Los cambios serán notificados por email.</p>
        <h2>9. Jurisdicción</h2>
        <p>Estos términos se rigen por las leyes de la República de Colombia. Cualquier disputa se resolverá en los tribunales de Barranquilla.</p>
      </div>
    </div>
  );
}
