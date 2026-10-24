// A tiny static server for testing the full game in the browser pane, which can't open local files over about
// 524 KB. Usage: node tools/serve.js [root] [port]  (defaults: the project folder, 5173); / serves the game.
const http = require('http'), fs = require('fs'), path = require('path');
const root = path.resolve(process.argv[2] || path.join(__dirname, '..')), port = +process.argv[3] || 5173;
const TYPES = { '.html': 'text/html; charset=utf-8', '.png': 'image/png', '.js': 'text/javascript', '.json': 'application/json' };
http.createServer((q, r) => {
  let p = path.join(root, decodeURIComponent(q.url.split('?')[0]));
  if (!p.startsWith(root)) { r.writeHead(403); return r.end(); }
  if (p.endsWith(path.sep)) p += 'one-life-ascend.html';
  fs.readFile(p, (e, d) => { if (e) { r.writeHead(404); return r.end(); } r.writeHead(200, { 'Content-Type': TYPES[path.extname(p)] || 'application/octet-stream' }); r.end(d); });
}).listen(port, '127.0.0.1', () => console.log(`serving ${root} on http://localhost:${port}`));
