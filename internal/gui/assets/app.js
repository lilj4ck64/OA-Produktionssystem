(() => {
  const input = document.querySelector('input[type=file]');
  const zone = document.querySelector('#dropzone');
  if (!input || !zone) return;
  ['dragenter', 'dragover'].forEach(name => zone.addEventListener(name, event => {
    event.preventDefault(); zone.classList.add('dragging');
  }));
  ['dragleave', 'drop'].forEach(name => zone.addEventListener(name, event => {
    event.preventDefault(); zone.classList.remove('dragging');
  }));
  zone.addEventListener('drop', event => {
    if (event.dataTransfer.files.length) input.files = event.dataTransfer.files;
  });
})();
