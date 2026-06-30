/* QuesMe Massage — service worker (app shell cache, network-first) */
var CACHE = 'qsmmassage-v6';
var SHELL = [
  './', 'index.html', 'login.html', 'home.html', 'book.html', 'therapist.html', 'admin.html', 'shop-console.html', 'qr.html',
  'app.css', 'i18n.js', 'inapp.js', 'pwa.js', 'config.js', 'manifest.webmanifest', 'icon-192.png', 'icon-512.png'
];
self.addEventListener('install', function (e){ e.waitUntil(caches.open(CACHE).then(function(c){ return c.addAll(SHELL).catch(function(){}); }).then(function(){ return self.skipWaiting(); })); });
self.addEventListener('activate', function (e){ e.waitUntil(caches.keys().then(function(keys){ return Promise.all(keys.map(function(k){ if(k!==CACHE) return caches.delete(k); })); }).then(function(){ return self.clients.claim(); })); });
self.addEventListener('fetch', function (e){
  if(e.request.method!=='GET') return;
  e.respondWith(fetch(e.request).then(function(res){ var copy=res.clone(); caches.open(CACHE).then(function(c){ c.put(e.request, copy).catch(function(){}); }); return res; })
    .catch(function(){ return caches.match(e.request).then(function(m){ return m || caches.match('index.html'); }); }));
});
self.addEventListener('push', function (e){ var d={}; try{ d=e.data?e.data.json():{}; }catch(err){} e.waitUntil(self.registration.showNotification(d.title||'QuesMe Massage', { body:d.body||'예약 알림', icon:'icon-192.png', badge:'icon-192.png' })); });
self.addEventListener('notificationclick', function (e){ e.notification.close(); e.waitUntil(clients.matchAll({type:'window'}).then(function(cl){ if(cl.length) return cl[0].focus(); return clients.openWindow('index.html'); })); });
