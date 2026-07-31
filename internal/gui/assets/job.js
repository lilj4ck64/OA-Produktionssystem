(() => {
  const id = window.OA_JOB_ID;
  if (!id) return;
  const poll = async () => {
    try {
      const response = await fetch('/api/jobs/' + encodeURIComponent(id));
      const job = await response.json();
      document.querySelector('#status').textContent = 'Status: ' + job.status;
      document.querySelector('#progress').value = job.progress;
      document.querySelector('#logs').textContent = job.logs.join('\n');
      document.querySelector('#artifacts').replaceChildren(...job.artifacts.map(item => {
        const link = document.createElement('a');
        link.href = item.url;
        link.textContent = item.format + ' herunterladen (' + item.size + ' Bytes)';
        return link;
      }));
      if (job.status === 'wartet' || job.status === 'läuft') setTimeout(poll, 700);
    } catch (_) { setTimeout(poll, 1500); }
  };
  poll();
})();
