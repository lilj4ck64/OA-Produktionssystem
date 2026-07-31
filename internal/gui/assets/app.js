(() => {
  const input = document.querySelector('input[type=file]');
  const zone = document.querySelector('#dropzone');
  if (input && zone) {
    ['dragenter', 'dragover'].forEach(name => zone.addEventListener(name, event => {
      event.preventDefault(); zone.classList.add('dragging');
    }));
    ['dragleave', 'drop'].forEach(name => zone.addEventListener(name, event => {
      event.preventDefault(); zone.classList.remove('dragging');
    }));
    zone.addEventListener('drop', event => {
      if (event.dataTransfer.files.length) input.files = event.dataTransfer.files;
    });
  }

  const button = document.querySelector('#choose-folder');
  const status = document.querySelector('#folder-status');
  if (!button) return;
  if (!window.showDirectoryPicker || !window.indexedDB) {
    button.disabled = true;
    status.textContent = 'Dieser Browser unterstützt den direkten Ordnerzugriff nicht. Bitte den ZIP-Import verwenden.';
    return;
  }

  const openDatabase = () => new Promise((resolve, reject) => {
    const request = indexedDB.open('oa-local-folders', 1);
    request.onupgradeneeded = () => request.result.createObjectStore('projects');
    request.onsuccess = () => resolve(request.result);
    request.onerror = () => reject(request.error);
  });
  const rememberHandle = async (project, handle) => {
    const database = await openDatabase();
    await new Promise((resolve, reject) => {
      const transaction = database.transaction('projects', 'readwrite');
      transaction.objectStore('projects').put(handle, project);
      transaction.oncomplete = resolve;
      transaction.onerror = () => reject(transaction.error);
    });
    database.close();
  };
  const collectFiles = async (directory, prefix, result) => {
    for await (const [name, handle] of directory.entries()) {
      if (prefix === '' && name === 'Outputs') continue;
      const path = prefix ? `${prefix}/${name}` : name;
      if (handle.kind === 'directory') await collectFiles(handle, path, result);
      else result.push({path, file: await handle.getFile()});
    }
  };

  button.addEventListener('click', async () => {
    button.disabled = true;
    try {
      const handle = await showDirectoryPicker({mode: 'readwrite'});
      status.textContent = 'Projektdateien werden gelesen …';
      const files = [];
      await collectFiles(handle, '', files);
      const form = new FormData();
      for (const item of files) {
        form.append('paths', item.path);
        form.append('files', item.file, item.file.name);
      }
      status.textContent = `${files.length} Dateien werden importiert …`;
      const response = await fetch('/import-folder', {
        method: 'POST', headers: {'Accept': 'application/json'}, body: form
      });
      const result = await response.json();
      if (!response.ok) throw new Error(result.error || 'Ordnerimport fehlgeschlagen.');
      await rememberHandle(result.project, handle);
      location.href = '/?message=' + encodeURIComponent(`Projekt ${result.project} wurde importiert. Ausgaben werden direkt in Outputs gespeichert.`);
    } catch (error) {
      if (error.name !== 'AbortError') status.textContent = error.message;
      button.disabled = false;
    }
  });
})();
