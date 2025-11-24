// Requires parallax.min.js loaded before this script
(function () {
  const scene = document.getElementById('scene');
  if (!scene) return;

  let parallaxInstance = null;

  function initParallax(options) {
    if (parallaxInstance) parallaxInstance.destroy();
    parallaxInstance = new Parallax(scene, options || {
      relativeInput: true,
      hoverOnly: true
    });
  }

  function isIOS13Plus() {
    return typeof DeviceOrientationEvent !== 'undefined' &&
           typeof DeviceOrientationEvent.requestPermission === 'function';
  }

  document.addEventListener('DOMContentLoaded', function () {
    const btn = document.getElementById('enable-motion');

    if (isIOS13Plus()) {
      if (btn) btn.style.display = 'block';

      btn && btn.addEventListener('click', function () {
        DeviceOrientationEvent.requestPermission()
          .then(function (response) {
            if (response === 'granted') {
              initParallax({ relativeInput: false, hoverOnly: false });
            } else {
              initParallax({ relativeInput: true, hoverOnly: true });
            }
            btn.style.display = 'none';
          })
          .catch(function () {
            initParallax({ relativeInput: true, hoverOnly: true });
            btn.style.display = 'none';
          });
      });
    } else {
      if (btn) btn.style.display = 'none';
      initParallax({ relativeInput: true, hoverOnly: true });
    }
  });
})();
