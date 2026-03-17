export async function requestNotificationPermission(): Promise<boolean> {
  if (!('Notification' in window)) return false;
  if (Notification.permission === 'granted') return true;
  if (Notification.permission === 'denied') return false;

  const result = await Notification.requestPermission();
  return result === 'granted';
}

export function showBrowserNotification(
  title: string,
  options?: { body?: string; icon?: string; tag?: string }
) {
  if (!('Notification' in window) || Notification.permission !== 'granted') return;

  const notification = new Notification(title, {
    body: options?.body,
    icon: options?.icon || '/icons/icon-192x192.png',
    badge: '/icons/icon-192x192.png',
    tag: options?.tag, // Prevents duplicate notifications
  });

  // Auto-close after 5 seconds
  setTimeout(() => notification.close(), 5000);

  // Focus window on click
  notification.onclick = () => {
    window.focus();
    notification.close();
  };
}
