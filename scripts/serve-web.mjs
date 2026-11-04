import { createReadStream } from 'node:fs';
import { access } from 'node:fs/promises';
import { createServer } from 'node:http';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '../Web');
const port = Number(process.env.PORT ?? 4173);
const contentTypes = new Map([
  ['.html', 'text/html; charset=utf-8'], ['.css', 'text/css; charset=utf-8'], ['.js', 'text/javascript; charset=utf-8'],
  ['.mjs', 'text/javascript; charset=utf-8'], ['.svg', 'image/svg+xml'], ['.png', 'image/png'],
  ['.webmanifest', 'application/manifest+json; charset=utf-8'],
]);

createServer(async (request, response) => {
  try {
    const pathname = decodeURIComponent(new URL(request.url, `http://${request.headers.host}`).pathname);
    const relative = pathname.replace(/^\/+/, '') || 'index.html';
    let filename = path.resolve(root, relative);
    if (!filename.startsWith(`${root}${path.sep}`) && filename !== path.join(root, 'index.html')) {
      response.writeHead(403).end('Forbidden');
      return;
    }
    try { await access(filename); } catch { filename = path.join(root, 'index.html'); }
    response.writeHead(200, { 'content-type': contentTypes.get(path.extname(filename)) ?? 'application/octet-stream', 'cache-control': 'no-cache' });
    createReadStream(filename).pipe(response);
  } catch {
    response.writeHead(400).end('Bad request');
  }
}).listen(port, '127.0.0.1', () => console.log(`YumiCrushSaga Web at http://127.0.0.1:${port}`));
