'use client';

import Link from 'next/link';
import { useSearchParams } from 'next/navigation';

export function RegisterLink({
  children,
  className,
}: {
  children: React.ReactNode;
  className?: string;
}) {
  const searchParams = useSearchParams();
  const ref = searchParams.get('ref');
  const href = ref ? `/register?ref=${ref}` : '/register';

  return (
    <Link href={href} className={className}>
      {children}
    </Link>
  );
}
