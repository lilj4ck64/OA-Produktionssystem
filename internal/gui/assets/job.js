(() => {
  const id = window.OA_JOB_ID;
  if (!id) return;

  const poll = async () => {
    try {
      const response = await fetch('/api/jobs/' + encodeURIComponent(id));
      if (!response.ok) throw new Error('Buildstatus ist nicht erreichbar.');
      const job = await response.json();
      const queue = job.queuePosition ? ` (Position ${job.queuePosition})` : '';
      document.querySelector('#status').textContent = 'Status: ' + job.status + queue;
      document.querySelector('#progress').value = job.progress;
      document.querySelector('#logs').textContent = job.logs.join('\n');
      document.querySelector('#artifacts').replaceChildren(...job.artifacts.map(item => {
        const link = document.createElement('a');
        link.href = item.url;
        link.target = '_blank';
        link.rel = 'noopener';
        link.textContent = item.format + ' in neuem Tab öffnen (' + item.size + ' Bytes)';
        return link;
      }));
      const saveStatus = document.querySelector('#save-status');
      if (saveStatus && job.status === 'fertig') {
        saveStatus.textContent = 'Alle Ausgaben wurden automatisch im Ordner Outputs neben der Anwendung gespeichert.';
      } else if (saveStatus && job.status === 'fehlgeschlagen') {
        saveStatus.textContent = 'Der Build ist fehlgeschlagen. Es wurden keine neuen Ausgaben gespeichert.';
        saveStatus.classList.add('error');
      }
      if (job.status === 'wartet' || job.status === 'läuft') setTimeout(poll, 700);
      else if (job.status === 'fertig') return;
    } catch (_) { setTimeout(poll, 1500); }
  };
  poll();
})();
