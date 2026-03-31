'use client';

import Link from 'next/link';

export function RegisterLink({
  children,
  className,
}: {
  children: React.ReactNode;
  className?: string;
}) {
  return (
    <Link href="/register" className={className}>
      {children}
    </Link>
  );
}
