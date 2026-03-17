"use client";

import { useEffect, useState } from "react";
import { createPortal } from "react-dom";
import { CheckCircle, XCircle, Info, AlertTriangle, X } from "lucide-react";
import { cn } from "@/lib/utils/cn";
import { useUIStore, type Toast } from "@/lib/stores/ui-store";

type ToastType = Toast["type"];

const variantConfig: Record<
  ToastType,
  { icon: typeof CheckCircle; bg: string; iconColor: string }
> = {
  success: {
    icon: CheckCircle,
    bg: "bg-green-50 border-green-200",
    iconColor: "text-green-600",
  },
  error: {
    icon: XCircle,
    bg: "bg-red-50 border-red-200",
    iconColor: "text-red-600",
  },
  info: {
    icon: Info,
    bg: "bg-blue-50 border-blue-200",
    iconColor: "text-blue-600",
  },
  warning: {
    icon: AlertTriangle,
    bg: "bg-yellow-50 border-yellow-200",
    iconColor: "text-yellow-600",
  },
};

export function ToastContainer() {
  const { toasts, removeToast } = useUIStore();
  const [mounted, setMounted] = useState(false);

  useEffect(() => {
    setMounted(true);
  }, []);

  if (!mounted || toasts.length === 0) return null;

  return createPortal(
    <div
      aria-live="polite"
      className="fixed right-4 top-4 z-[100] flex flex-col gap-2"
    >
      {toasts.map((toast) => {
        const config = variantConfig[toast.type];
        const Icon = config.icon;

        return (
          <div
            key={toast.id}
            className={cn(
              "flex items-start gap-3 rounded-lg border p-4 shadow-md animate-[toast-in_200ms_ease-out]",
              "min-w-[320px] max-w-[420px]",
              config.bg
            )}
          >
            <Icon className={cn("mt-0.5 h-5 w-5 shrink-0", config.iconColor)} />
            <p className="flex-1 text-sm text-gray-900">{toast.message}</p>
            <button
              onClick={() => removeToast(toast.id)}
              className="shrink-0 rounded p-0.5 text-gray-400 hover:text-gray-600 transition-colors"
              aria-label="Dismiss"
            >
              <X className="h-4 w-4" />
            </button>
          </div>
        );
      })}

      <style jsx global>{`
        @keyframes toast-in {
          from {
            opacity: 0;
            transform: translateX(100%);
          }
          to {
            opacity: 1;
            transform: translateX(0);
          }
        }
      `}</style>
    </div>,
    document.body
  );
}
