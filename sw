// ========== SERVICE WORKER: Архитектор Времени ==========
// Версия кеша — меняйте при обновлении приложения
const CACHE_NAME = 'architect-v1';

// Файлы для кеширования при установке
const PRECACHE = [
    './',
    './index.html',
    './manifest.json'
];

// ===== УСТАНОВКА: кешируем основные файлы =====
self.addEventListener('install', event => {
    console.log('[SW] Установка...');
    event.waitUntil(
        caches.open(CACHE_NAME)
            .then(cache => {
                console.log('[SW] Кешируем файлы');
                return cache.addAll(PRECACHE);
            })
            .then(() => self.skipWaiting())
    );
});

// ===== АКТИВАЦИЯ: удаляем старые кеши =====
self.addEventListener('activate', event => {
    console.log('[SW] Активация...');
    event.waitUntil(
        caches.keys().then(keys =>
            Promise.all(
                keys
                    .filter(key => key !== CACHE_NAME)
                    .map(key => {
                        console.log('[SW] Удаляем старый кеш:', key);
                        return caches.delete(key);
                    })
            )
        ).then(() => self.clients.claim())
    );
});

// ===== ЗАПРОСЫ: стратегия "Network First, fallback to Cache" =====
// Сначала пробуем сеть (чтобы данные были свежими),
// при отсутствии связи — отдаём из кеша
self.addEventListener('fetch', event => {

    // Пропускаем не-GET запросы и внешние URL
    if (event.request.method !== 'GET') return;
    if (!event.request.url.startsWith(self.location.origin)) return;

    event.respondWith(
        fetch(event.request)
            .then(response => {
                // Сохраняем свежую копию в кеш
                const clone = response.clone();
                caches.open(CACHE_NAME).then(cache => cache.put(event.request, clone));
                return response;
            })
            .catch(() => {
                // Нет сети — берём из кеша
                return caches.match(event.request)
                    .then(cached => cached || caches.match('./'));
            })
    );
});
