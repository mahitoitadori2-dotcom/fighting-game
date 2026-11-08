// Tiny static server for local testing of web/ (same COOP/COEP headers as _headers).
// Usage: node serve.js <folder> [port]
const http = require('http'), fs = require('fs'), path = require('path');
const root = path.resolve(process.argv[2]); const port = +(process.argv[3] || 8060);
const types = { '.html': 'text/html', '.js': 'text/javascript', '.css': 'text/css', '.wasm': 'application/wasm',
  '.pck': 'application/octet-stream', '.png': 'image/png', '.svg': 'image/svg+xml' };
http.createServer((req, res) => {
  let p = decodeURIComponent(req.url.split('?')[0]);
  if (p.endsWith('/')) p += 'index.html';
  const f = path.join(root, p);
  if (!f.startsWith(root) || !fs.existsSync(f) || fs.statSync(f).isDirectory()) { res.writeHead(404); return res.end('404'); }
  res.writeHead(200, { 'Content-Type': types[path.extname(f)] || 'application/octet-stream',
    'Cross-Origin-Opener-Policy': 'same-origin', 'Cross-Origin-Embedder-Policy': 'require-corp',
    'Cross-Origin-Resource-Policy': 'same-origin' });
  fs.createReadStream(f).pipe(res);
}).listen(port, () => console.log('serving ' + root + ' on http://localhost:' + port));
