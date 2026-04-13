var CACHE = 'dotsai-v1';
var PRECACHE = [
  '/',
  '/index.html',
  '/main.css',
  '/site.css',
  '/favicon.svg',
  'https://cdnjs.cloudflare.com/ajax/libs/gsap/3.12.5/gsap.min.js',
  'https://cdnjs.cloudflare.com/ajax/libs/gsap/3.12.5/ScrollTrigger.min.js',
];

self.addEventListener('install', function(e) {
  e.waitUntil(
    caches.open(CACHE).then(function(c) {
      return Promise.allSettled(PRECACHE.map(function(url) {
        var req = (url.startsWith('http') && !url.startsWith(self.location.origin))
          ? new Request(url, { mode: 'no-cors' })
          : url;
        return c.add(req).catch(function() {});
      }));
    })
  );
  self.skipWaiting();
});

self.addEventListener('activate', function(e) {
  e.waitUntil(
    caches.keys().then(function(keys) {
      return Promise.all(
        keys.filter(function(k) { return k !== CACHE; }).map(function(k) { return caches.delete(k); })
      );
    })
  );
  self.clients.claim();
});

self.addEventListener('fetch', function(e) {
  var url = e.request.url;

  // Network-only: external services
  if (url.includes('cal.com') || url.includes('wa.me') || url.includes('dotsai.cloud') || url.includes('googleapis.com/calendar')) return;

  // Cache-first: static assets (CSS, JS, SVG, fonts, CDN)
  if (/\.(css|js|svg|woff2?|ttf|eot|png|jpg|ico)/.test(url) || url.includes('cdnjs') || url.includes('fonts.g')) {
    e.respondWith(
      caches.match(e.request).then(function(r) {
        return r || fetch(e.request).then(function(res) {
          return caches.open(CACHE).then(function(c) {
            if (res.ok || res.type === 'opaque') c.put(e.request, res.clone());
            return res;
          });
        });
      })
    );
    return;
  }

  // Stale-while-revalidate: HTML pages
  e.respondWith(
    caches.open(CACHE).then(function(c) {
      return c.match(e.request).then(function(cached) {
        var fetchPromise = fetch(e.request).then(function(res) {
          if (res.ok) c.put(e.request, res.clone());
          return res;
        }).catch(function() { return cached; });
        return cached || fetchPromise;
      });
    })
  );
});
