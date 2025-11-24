(function () {
  const area = document.getElementById('orbsArea');
  if (!area) return;

  const orbCountAttr = area.dataset.orbs;
  const orbCount = Number.parseInt(orbCountAttr, 10) > 0
    ? Number.parseInt(orbCountAttr, 10)
    : 10;

  const areaW = area.offsetWidth;
  const areaH = area.offsetHeight;

  function rand(min, max) {
    return Math.random() * (max - min) + min;
  }

  const orbs = [];
  for (let i = 0; i < orbCount; i++) {
    const orb = document.createElement('div');
    orb.className = 'orb';
    const size = rand(22, 54);
    orb.style.width = size + 'px';
    orb.style.height = size + 'px';

    const tail = document.createElement('div');
    tail.className = 'orb-tail';
    tail.style.height = rand(22, 42) + 'px';
    orb.appendChild(tail);

    area.appendChild(orb);

    orbs.push({
      el: orb,
      tail: tail,
      size: size,
      x: rand(-areaW * 0.4, areaW * 1.2),
      y: rand(-areaH * 0.2, areaH * 1.2),
      angle: rand(0, Math.PI * 2),
      speed: rand(0.3, 1.1),
      t: rand(0, 1000),
      tailAngle: rand(15, 75),
      roamX: rand(15, 60),
      roamY: rand(20, 90)
    });
  }

  function moveOrbs() {
    orbs.forEach(o => {
      o.t += o.speed * 0.8;
      o.x += Math.cos(o.angle + Math.sin(o.t / 110)) * o.speed * 0.7 +
             Math.sin(o.t / 100) * o.roamX * 0.001;
      o.y += Math.sin(o.angle + Math.cos(o.t / 95)) * o.speed * 0.7 +
             Math.cos(o.t / 107) * o.roamY * 0.001;

      o.el.style.left = o.x + 'px';
      o.el.style.top  = o.y + 'px';
      o.tailAngle += rand(-2, 2);
      o.tail.style.setProperty('--tail-rotation', o.tailAngle + 'deg');
    });
    requestAnimationFrame(moveOrbs);
  }
  moveOrbs();
})();
