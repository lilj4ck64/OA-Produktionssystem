(() => {
  const id = window.OA_JOB_ID;
  const project = window.OA_PROJECT_NAME;
  if (!id) return;
  let completedArtifacts = [];

  const loadHandle = () => new Promise((resolve, reject) => {
    if (!window.indexedDB) return resolve(null);
    const request = indexedDB.open('oa-local-folders', 1);
    request.onupgradeneeded = () => request.result.createObjectStore('projects');
    request.onerror = () => reject(request.error);
    request.onsuccess = () => {
      const database = request.result;
      const get = database.transaction('projects').objectStore('projects').get(project);
      get.onsuccess = () => { resolve(get.result || null); database.close(); };
      get.onerror = () => { reject(get.error); database.close(); };
    };
  });
  const saveToFolder = async (requestPermission) => {
    const handle = await loadHandle();
    if (!handle || !completedArtifacts.length) return false;
    let permission = await handle.queryPermission({mode: 'readwrite'});
    if (permission !== 'granted' && requestPermission) {
      permission = await handle.requestPermission({mode: 'readwrite'});
    }
    if (permission !== 'granted') return false;
    const outputs = await handle.getDirectoryHandle('Outputs', {create: true});
    for (const artifact of completedArtifacts) {
      const response = await fetch(artifact.url);
      if (!response.ok) throw new Error(`${artifact.format} konnte nicht gelesen werden.`);
      const filename = decodeURIComponent(new URL(artifact.url, location.href).pathname.split('/').pop());
      const file = await outputs.getFileHandle(filename, {create: true});
      const writer = await file.createWritable();
      try { await writer.write(await response.blob()); await writer.close(); }
      catch (error) { await writer.abort(); throw error; }
    }
    document.querySelector('#save-status').textContent = 'Alle Ausgaben wurden direkt in den lokalen Ordner Outputs geschrieben.';
    document.querySelector('#save-folder').hidden = true;
    return true;
  };
  const offerFolderSave = async () => {
    const saveButton = document.querySelector('#save-folder');
    try {
      if (await saveToFolder(false)) return;
      if (await loadHandle()) saveButton.hidden = false;
    } catch (error) {
      document.querySelector('#save-status').textContent = `Direktes Schreiben fehlgeschlagen: ${error.message}`;
      saveButton.hidden = false;
    }
  };
  document.querySelector('#save-folder').addEventListener('click', async event => {
    event.currentTarget.disabled = true;
    try {
      if (!await saveToFolder(true)) throw new Error('Der Browser hat keinen Schreibzugriff erhalten.');
    } catch (error) {
      document.querySelector('#save-status').textContent = `Direktes Schreiben fehlgeschlagen: ${error.message}`;
      event.currentTarget.disabled = false;
    }
  });

  const poll = async () => {
    try {
      const response = await fetch('/api/jobs/' + encodeURIComponent(id));
      if (!response.ok) throw new Error('Buildstatus ist nicht erreichbar.');
      const job = await response.json();
      document.querySelector('#status').textContent = 'Status: ' + job.status;
      document.querySelector('#progress').value = job.progress;
      document.querySelector('#logs').textContent = job.logs.join('\n');
      document.querySelector('#artifacts').replaceChildren(...job.artifacts.map(item => {
        const link = document.createElement('a');
        link.href = item.url;
        link.textContent = item.format + ' öffnen oder herunterladen (' + item.size + ' Bytes)';
        return link;
      }));
      if (job.status === 'wartet' || job.status === 'läuft') setTimeout(poll, 700);
      else if (job.status === 'fertig') {
        completedArtifacts = job.artifacts;
        await offerFolderSave();
      }
    } catch (_) { setTimeout(poll, 1500); }
  };
  poll();
})();
