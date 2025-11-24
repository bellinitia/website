(function () {
  const durationMs    = 8_000;
  const step          = 50;
  const totalVisualMs = 15_000;

  const section   = document.getElementById('timerSection');
  if (!section) return;

  const timeEl    = document.getElementById('time');
  const arrowEl   = document.getElementById('growing-arrow');
  const sphereEl  = document.getElementById('sphere');
  const bgLayerEl = section.querySelector('.bg-zoom-layer');

  let remainingMs;
  let started = false;

  let visualElapsedMs = 0;
  let lastFrameTime = null;
  let visualsDone = false;

  let countdownTimer = null;

  function formatTime(ms) {
    const totalSeconds = Math.floor(ms / 1000);
    const minutes = Math.floor(totalSeconds / 60);
    const seconds = totalSeconds % 60;
    const millis  = ms % 1000;
    const m = String(minutes).padStart(2, '0');
    const s = String(seconds).padStart(2, '0');
    const msStr = String(millis).padStart(3, '0');
    return `${m}:${s}:${msStr}`;
  }

  function applyVisuals(deltaMs) {
    if (visualsDone) return;

    visualElapsedMs += deltaMs;
    if (visualElapsedMs >= totalVisualMs) {
      visualElapsedMs = totalVisualMs;
      visualsDone = true;
    }

    const p = visualElapsedMs / totalVisualMs;

    const minBlur = 4;
    const maxBlur = 30;
    const blur = minBlur + (maxBlur - minBlur) * p;
    arrowEl.style.textShadow = `0 0 ${blur}px rgba(255,64,64,0.9)`;

    const scaleStart = 1;
    const scaleEnd   = 1.6;
    const scale      = scaleStart + (scaleEnd - scaleStart) * p;
    if (bgLayerEl) {
      bgLayerEl.style.transform = `scale(${scale})`;
    }
  }

  function visualsLoop(timestamp) {
    if (lastFrameTime === null) lastFrameTime = timestamp;
    const delta = timestamp - lastFrameTime;
    lastFrameTime = timestamp;

    applyVisuals(delta);

    if (!visualsDone) {
      requestAnimationFrame(visualsLoop);
    }
  }

  function updateCountdown() {
    if (remainingMs < 0) remainingMs = 0;

    timeEl.textContent = formatTime(remainingMs);
    timeEl.style.visibility = 'visible';

    if (remainingMs === 0) {
      clearInterval(countdownTimer);
      startBlinkPhase();
    } else {
      remainingMs -= step;
    }
  }

  function startBlinkPhase() {
    const totalBlinks   = 10;
    const blinkInterval = 200;
    let count = 0;
    let visible = true;

    const blinkTimer = setInterval(() => {
      visible = !visible;
      timeEl.style.visibility = visible ? 'visible' : 'hidden';
      count++;

      if (count >= totalBlinks * 2) {
        clearInterval(blinkTimer);
        timeEl.style.visibility = 'visible';
        startSpherePhase();
      }
    }, blinkInterval);
  }

  function startSpherePhase() {
    const sphereDurationMs = 1_000;
    const sphereStep = 40;
    let elapsed = 0;

    const sphereTimer = setInterval(() => {
      elapsed += sphereStep;
      if (elapsed > sphereDurationMs) elapsed = sphereDurationMs;

      const t = elapsed / sphereDurationMs;
      const sphereScaleMin = 0.01;
      const sphereScaleMax = 30;
      const sphereScale =
        sphereScaleMin + (sphereScaleMax - sphereScaleMin) * t;

      sphereEl.style.transform =
        `translate(-50%, -50%) scale(${sphereScale})`;

      if (elapsed >= sphereDurationMs) {
        clearInterval(sphereTimer);
      }
    }, sphereStep);
  }

  function startTimer() {
    if (started) return;
    started = true;
    remainingMs = durationMs;

    requestAnimationFrame(visualsLoop);
    updateCountdown();
    countdownTimer = setInterval(updateCountdown, step);
  }

  const observer = new IntersectionObserver((entries) => {
    entries.forEach(entry => {
      if (entry.isIntersecting) startTimer();
    });
  }, { threshold: 0.4 });

  observer.observe(section);
})();
