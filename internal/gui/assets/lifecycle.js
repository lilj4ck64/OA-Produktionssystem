(() => {
  const newID = () => window.crypto?.randomUUID?.() || `${Date.now()}-${Math.random()}`;
  let id;
  let active = true;
  let timer;

  const heartbeat = () => {
    if (!active) return;
    fetch('/api/local-session/heartbeat', {
      method: 'POST',
      headers: {'Content-Type': 'text/plain'},
      body: id,
      cache: 'no-store',
      keepalive: true
    }).catch(() => {});
  };

  const start = () => {
    id = newID();
    active = true;
    clearInterval(timer);
    heartbeat();
    timer = setInterval(heartbeat, 2000);
  };

  start();
  window.addEventListener('pagehide', () => {
    active = false;
    clearInterval(timer);
    navigator.sendBeacon('/api/local-session/close', id);
  });
  // A page restored from the browser's back/forward cache keeps its old
  // JavaScript state, so resume the heartbeat explicitly.
  window.addEventListener('pageshow', event => {
    if (event.persisted && !active) start();
  });
})();
