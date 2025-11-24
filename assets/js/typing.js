(function () {
  const typingEl = document.getElementById('typing');
  const demoEl   = document.getElementById('typingPar');
  const cursorEl = document.getElementById('cursor');
  if (!typingEl || !demoEl || !cursorEl) return;

  let i = 0;
  const speed = 100;
  let typedOnce = false;

  const fullText = demoEl.textContent.replace('|', '').trim();
  demoEl.textContent = '';
  demoEl.appendChild(cursorEl);

  function typeWriter() {
    if (i < fullText.length) {
      demoEl.insertBefore(
        document.createTextNode(fullText.charAt(i)),
        cursorEl
      );
      i++;
      setTimeout(typeWriter, speed);
    }
  }

  const observer = new IntersectionObserver((entries) => {
    entries.forEach(entry => {
      if (entry.isIntersecting && !typedOnce) {
        typedOnce = true;
        typeWriter();
      }
    });
  }, { threshold: 0.3 });

  observer.observe(typingEl);
})();
