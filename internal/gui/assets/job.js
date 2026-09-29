(() => {
  const id = window.OA_JOB_ID;
  if (!id) return;

  const formatLabels = {
    'web-pdf': 'Web-PDF',
    'print-pdf': 'Print-PDF',
    epub: 'EPUB'
  };
  let artifactSignature = '';
  let selectedFormat = '';
  let previewVersion = 0;

  const formatBytes = size => new Intl.NumberFormat('de-DE', {
    style: 'unit', unit: size >= 1_000_000 ? 'megabyte' : 'kilobyte',
    unitDisplay: 'short', maximumFractionDigits: 1
  }).format(size >= 1_000_000 ? size / 1_000_000 : size / 1_000);

  const renderArtifacts = artifacts => {
    const signature = artifacts.map(item => `${item.format}:${item.url}:${item.size}`).join('|');
    if (signature === artifactSignature) return;
    artifactSignature = signature;
    const results = document.querySelector('#results');
    if (!artifacts.length) {
      results.hidden = true;
      return;
    }
    results.hidden = false;
    if (!artifacts.some(item => item.format === selectedFormat)) {
      selectedFormat = artifacts.some(item => item.format === 'web-pdf') ? 'web-pdf' : artifacts[0].format;
    }
    const tabs = document.querySelector('#artifact-tabs');
    tabs.replaceChildren(...artifacts.map(item => {
      const button = document.createElement('button');
      button.type = 'button';
      button.className = 'artifact-tab';
      button.id = `tab-${item.format}`;
      button.setAttribute('role', 'tab');
      button.setAttribute('aria-controls', 'artifact-preview');
      button.textContent = formatLabels[item.format] || item.format;
      button.addEventListener('click', () => showArtifact(item));
      button.addEventListener('keydown', event => {
        if (event.key !== 'ArrowLeft' && event.key !== 'ArrowRight') return;
        event.preventDefault();
        const offset = event.key === 'ArrowRight' ? 1 : -1;
        const targetIndex = (artifacts.indexOf(item) + offset + artifacts.length) % artifacts.length;
        showArtifact(artifacts[targetIndex]);
        document.querySelector(`#tab-${artifacts[targetIndex].format}`).focus();
      });
      return button;
    }));
    showArtifact(artifacts.find(item => item.format === selectedFormat));
  };

  const showArtifact = item => {
    selectedFormat = item.format;
    previewVersion += 1;
    document.querySelectorAll('.artifact-tab').forEach(button => {
      const active = button.id === `tab-${item.format}`;
      button.setAttribute('aria-selected', String(active));
      button.tabIndex = active ? 0 : -1;
    });
    const actions = document.querySelector('#artifact-actions');
    const download = document.createElement('a');
    download.className = 'button';
    download.href = item.downloadUrl || item.url + '?download=1';
    download.textContent = `${formatLabels[item.format] || item.format} herunterladen (${formatBytes(item.size)})`;
    const actionItems = [download];
    if (item.format !== 'epub') {
      const open = document.createElement('a');
      open.className = 'button secondary';
      open.href = item.url;
      open.target = '_blank';
      open.rel = 'noopener';
      open.textContent = 'In neuem Tab öffnen';
      actionItems.push(open);
    }
    actions.replaceChildren(...actionItems);

    if (item.format === 'epub') renderEPUB(item, previewVersion);
    else renderPDF(item);
  };

  const renderPDF = item => {
    const frame = document.createElement('iframe');
    frame.className = 'artifact-frame pdf-frame';
    frame.src = item.previewUrl || item.url;
    frame.title = `${formatLabels[item.format] || item.format} Vorschau`;
    frame.loading = 'lazy';
    document.querySelector('#artifact-preview').replaceChildren(frame);
  };

  const renderEPUB = async (item, version) => {
    const preview = document.querySelector('#artifact-preview');
    const loading = document.createElement('p');
    loading.className = 'preview-message';
    loading.setAttribute('role', 'status');
    loading.textContent = 'EPUB-Vorschau wird geladen …';
    preview.replaceChildren(loading);
    try {
      const response = await fetch(item.previewUrl);
      if (!response.ok) throw new Error('Die EPUB-Struktur konnte nicht gelesen werden.');
      const publication = await response.json();
      if (version !== previewVersion) return;

      const reader = document.createElement('div');
      reader.className = 'epub-reader';
      const controls = document.createElement('div');
      controls.className = 'epub-controls';
      const previous = document.createElement('button');
      previous.type = 'button';
      previous.className = 'secondary';
      previous.textContent = 'Zurück';
      const section = document.createElement('select');
      section.setAttribute('aria-label', 'Abschnitt auswählen');
      publication.spine.forEach((entry, index) => {
        const option = document.createElement('option');
        option.value = String(index);
        option.textContent = entry.label;
        section.append(option);
      });
      const next = document.createElement('button');
      next.type = 'button';
      next.className = 'secondary';
      next.textContent = 'Weiter';
      const fontSize = document.createElement('select');
      fontSize.setAttribute('aria-label', 'Schriftgröße');
      [['85', 'Klein'], ['100', 'Normal'], ['115', 'Groß'], ['130', 'Sehr groß']].forEach(([value, label]) => {
        const option = document.createElement('option');
        option.value = value;
        option.textContent = label;
        if (value === '100') option.selected = true;
        fontSize.append(option);
      });
      const frame = document.createElement('iframe');
      frame.className = 'artifact-frame epub-frame';
      frame.title = `EPUB-Vorschau${publication.title ? `: ${publication.title}` : ''}`;
      frame.setAttribute('sandbox', 'allow-same-origin');
      frame.referrerPolicy = 'no-referrer';

      const updateControls = () => {
        const index = Number(section.value);
        previous.disabled = index <= 0;
        next.disabled = index >= publication.spine.length - 1;
      };
      const navigate = index => {
        section.value = String(index);
        frame.src = publication.spine[index].url;
        updateControls();
      };
      previous.addEventListener('click', () => navigate(Number(section.value) - 1));
      next.addEventListener('click', () => navigate(Number(section.value) + 1));
      section.addEventListener('change', () => navigate(Number(section.value)));
      fontSize.addEventListener('change', () => applyEPUBFontSize(frame, fontSize.value));
      frame.addEventListener('load', () => {
        applyEPUBFontSize(frame, fontSize.value);
        keepEPUBLinksInsideReader(frame, item.previewUrl);
        syncEPUBSection(frame, section, publication.spine);
        updateControls();
      });
      controls.append(previous, section, next, fontSize);
      reader.append(controls, frame);
      preview.replaceChildren(reader);
      navigate(0);
    } catch (error) {
      if (version !== previewVersion) return;
      loading.classList.add('error');
      loading.textContent = error.message;
    }
  };

  const applyEPUBFontSize = (frame, percent) => {
    try { frame.contentDocument.documentElement.style.fontSize = `${percent}%`; } catch (_) {}
  };

  const keepEPUBLinksInsideReader = (frame, manifestURL) => {
    try {
      const previewPrefix = new URL(manifestURL, location.href).pathname.replace(/manifest$/, '');
      const contentPrefix = previewPrefix + 'content/';
      frame.contentDocument.querySelectorAll('a[href]').forEach(link => {
        const target = new URL(link.href, frame.contentWindow.location.href);
        if (target.origin === location.origin && target.pathname.startsWith(contentPrefix) && target.pathname.toLowerCase().endsWith('.xhtml')) {
          link.addEventListener('click', event => {
            event.preventDefault();
            const entryPath = decodeURIComponent(target.pathname.slice(contentPrefix.length));
            frame.src = `${previewPrefix}document?path=${encodeURIComponent(entryPath)}${target.hash}`;
          });
        } else if (target.origin !== location.origin) {
          link.addEventListener('click', event => {
            event.preventDefault();
            window.open(target.href, '_blank', 'noopener,noreferrer');
          });
        }
      });
    } catch (_) {}
  };

  const syncEPUBSection = (frame, section, spine) => {
    try {
      const currentLocation = frame.contentWindow.location;
      const currentPath = currentLocation.pathname + currentLocation.search;
      const index = spine.findIndex(entry => {
        const target = new URL(entry.url, location.href);
        return target.pathname + target.search === currentPath;
      });
      if (index >= 0) section.value = String(index);
    } catch (_) {}
  };

  const poll = async () => {
    try {
      const response = await fetch('/api/jobs/' + encodeURIComponent(id));
      if (!response.ok) throw new Error('Buildstatus ist nicht erreichbar.');
      const job = await response.json();
      const isImport = job.operation === 'Importprüfung';
      const queue = job.queuePosition ? ` (Position ${job.queuePosition})` : '';
      document.querySelector('#status').textContent = 'Status: ' + job.status + queue;
      document.querySelector('#progress').value = job.progress;
      document.querySelector('#progress-message').textContent = job.progressMessage;
      document.querySelector('#logs').textContent = job.logs.join('\n');
      const logDownload = document.querySelector('#log-download');
      const logDownloadRow = document.querySelector('#log-download-row');
      const finished = job.status === 'fertig' || job.status === 'fehlgeschlagen' || job.status === 'abgebrochen';
      if (logDownload && logDownloadRow && finished && job.logDownloadUrl) {
        logDownload.href = job.logDownloadUrl;
        logDownload.textContent = `Logdatei herunterladen (${formatBytes(job.logSize)})`;
        logDownloadRow.hidden = false;
      }
      renderArtifacts(job.artifacts || []);
      const saveStatus = document.querySelector('#save-status');
      if (saveStatus && job.status === 'fertig') {
        saveStatus.textContent = 'Alle Ausgaben wurden im Ordner Outputs und die vollständige Logdatei im Ordner Log neben der Anwendung gespeichert.';
      } else if (saveStatus && job.status === 'fehlgeschlagen') {
        saveStatus.textContent = job.logFileName
          ? `${isImport ? 'Der Import' : 'Der Build'} ist fehlgeschlagen. Die vollständige Logdatei wurde im Ordner Log neben der Anwendung gespeichert.`
          : `${isImport ? 'Der Import' : 'Der Build'} ist fehlgeschlagen. Die Logdatei konnte nicht gespeichert werden.`;
        saveStatus.classList.add('error');
      }
      if (job.status === 'wartet' || job.status === 'läuft') setTimeout(poll, 700);
      else if (job.status === 'fertig') return;
    } catch (_) { setTimeout(poll, 1500); }
  };
  poll();
})();
