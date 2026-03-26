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
        <p>
          Al acceder o utilizar la plataforma Agendity, usted acepta quedar vinculado por
          los presentes Términos y Condiciones. Si no está de acuerdo con alguna de estas
          condiciones, no utilice el servicio.
        </p>

        <h2>1. Definiciones</h2>
        <ul>
          <li>
            <strong>Agendity:</strong> plataforma SaaS de gestión de citas y reservas
            desarrollada y operada desde Barranquilla, Colombia.
          </li>
          <li>
            <strong>Cliente:</strong> el negocio (persona natural o jurídica) que se
            registra en Agendity y contrata un plan de suscripción para gestionar su
            operación.
          </li>
          <li>
            <strong>Usuario final:</strong> la persona que utiliza la plataforma para
            reservar citas en un negocio registrado. El usuario final no paga suscripción
            ni necesita crear una cuenta.
          </li>
        </ul>

        <h2>2. Uso del servicio</h2>
        <p>
          Agendity está disponible para negocios que trabajan con citas en Colombia y
          Latinoamérica. El Cliente es el único responsable de la veracidad y legalidad de
          la información que publica en la plataforma, incluyendo pero no limitado a:
          servicios ofrecidos, precios, horarios y datos de contacto.
        </p>
        <p>
          El Cliente se compromete a no utilizar la plataforma para fines ilícitos, fraudulentos
          o que violen los derechos de terceros. Agendity se reserva el derecho de suspender o
          cancelar cuentas que incumplan estas condiciones sin previo aviso.
        </p>

        <h2>3. Periodo de prueba</h2>
        <p>
          Agendity ofrece un periodo de prueba gratuita de <strong>25 días calendario</strong> con
          acceso completo a todas las funcionalidades del plan contratado. Al finalizar el periodo
          de prueba, el Cliente debe activar un plan de pago para continuar utilizando el servicio.
        </p>
        <p>
          Si el Cliente no activa un plan al vencer la prueba, su cuenta será suspendida
          progresivamente conforme al siguiente esquema: notificación previa, suspensión parcial y,
          finalmente, desactivación total de la cuenta.
        </p>

        <h2>4. Planes y pagos</h2>
        <p>
          Las suscripciones se facturan de forma <strong>mensual</strong> y se renuevan manualmente.
          Los pagos se realizan exclusivamente mediante <strong>transferencia bancaria</strong> a las
          cuentas indicadas por Agendity (Nequi, Bancolombia, Daviplata u otros medios habilitados).
        </p>
        <p>
          Los precios de los planes están expresados en pesos colombianos (COP) e incluyen IVA cuando
          aplique. Agendity se reserva el derecho de modificar los precios con previo aviso de al menos
          30 días calendario. Los cambios de precio aplicarán a partir de la siguiente renovación de la
          suscripción.
        </p>
        <p>
          <strong>No se realizan reembolsos</strong> por periodos parciales, cancelaciones anticipadas ni
          por funcionalidades no utilizadas durante el periodo de suscripción activo.
        </p>

        <h2>5. Cancelación</h2>
        <p>
          El Cliente puede cancelar su suscripción en cualquier momento desde el panel de
          configuración de su cuenta o contactando a soporte. La cancelación se hará efectiva
          al finalizar el periodo de facturación vigente, manteniéndose el acceso hasta esa fecha.
        </p>
        <p>
          Agendity puede cancelar o suspender la cuenta de un Cliente en caso de: incumplimiento
          de estos Términos, falta de pago, uso fraudulento de la plataforma o por requerimiento
          de autoridad competente.
        </p>

        <h2>6. Protección de datos personales</h2>
        <p>
          Agendity cumple con la <strong>Ley 1581 de 2012</strong> y el{' '}
          <strong>Decreto 1377 de 2013</strong> de Colombia sobre protección de datos
          personales. El tratamiento de datos personales se realiza conforme a nuestra{' '}
          <a href="/privacy" className="text-violet-600 hover:underline">
            Política de Privacidad
          </a>
          , la cual forma parte integral de estos Términos.
        </p>
        <p>
          El Cliente es responsable del tratamiento de los datos personales de sus usuarios
          finales y clientes, y debe contar con las autorizaciones correspondientes conforme
          a la normativa colombiana vigente.
        </p>

        <h2>7. Propiedad intelectual</h2>
        <p>
          Todos los derechos de propiedad intelectual sobre la plataforma Agendity, incluyendo
          pero no limitado a: código fuente, diseño, marca, logotipos, textos, gráficos e
          interfaces, son propiedad exclusiva de Agendity.
        </p>
        <p>
          El Cliente conserva todos los derechos sobre el contenido que suba a la plataforma
          (logotipos, fotografías, descripciones). Al utilizar el servicio, el Cliente otorga a
          Agendity una licencia limitada y no exclusiva para mostrar dicho contenido en la
          plataforma con el fin de prestar el servicio contratado.
        </p>

        <h2>8. Limitación de responsabilidad</h2>
        <p>
          Agendity se proporciona <strong>&quot;tal cual&quot;</strong> y{' '}
          <strong>&quot;según disponibilidad&quot;</strong>. No garantizamos que el servicio sea
          ininterrumpido, libre de errores o completamente seguro.
        </p>
        <p>
          Agendity no será responsable por: (a) pérdidas económicas derivadas del uso o
          imposibilidad de uso de la plataforma; (b) daños indirectos, incidentales o
          consecuentes; (c) pérdida de datos causada por factores fuera de nuestro control;
          (d) actuaciones de terceros, incluyendo proveedores de servicios de internet o hosting.
        </p>
        <p>
          En todo caso, la responsabilidad máxima de Agendity estará limitada al valor pagado
          por el Cliente en los últimos 3 meses de suscripción.
        </p>

        <h2>9. Modificaciones a estos Términos</h2>
        <p>
          Agendity se reserva el derecho de modificar estos Términos y Condiciones en cualquier
          momento. Los cambios serán notificados por correo electrónico al menos 15 días antes
          de su entrada en vigencia. El uso continuado de la plataforma después de la fecha
          efectiva de los cambios constituye aceptación de los nuevos términos.
        </p>

        <h2>10. Ley aplicable y jurisdicción</h2>
        <p>
          Estos Términos se rigen por las leyes de la <strong>República de Colombia</strong>.
          Para la resolución de cualquier controversia derivada de estos Términos, las partes
          se someten a la jurisdicción de los tribunales competentes de la ciudad de{' '}
          <strong>Barranquilla, Atlántico, Colombia</strong>.
        </p>

        <h2>11. Contacto</h2>
        <p>
          Para preguntas o inquietudes sobre estos Términos y Condiciones, puede contactarnos en:
        </p>
        <ul>
          <li>
            Correo electrónico:{' '}
            <a href="mailto:soporte@agendity.com" className="text-violet-600 hover:underline">
              soporte@agendity.com
            </a>
          </li>
          <li>Domicilio: Barranquilla, Atlántico, Colombia</li>
        </ul>
      </div>
    </div>
  );
}
