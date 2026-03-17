export default function AuthLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <div className="flex min-h-screen items-center justify-center bg-gray-50 px-4">
      <div className="w-full max-w-md">
        <div className="mb-8 text-center">
          <h1 className="text-3xl font-bold text-violet-600">Agendity</h1>
          <p className="mt-1 text-sm text-gray-500">
            Gestiona tu negocio, simplifica tus citas
          </p>
        </div>
        {children}
      </div>
    </div>
  );
}
