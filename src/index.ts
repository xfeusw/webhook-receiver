import * as http from "node:http";
import * as fs from "node:fs";
import * as path from "node:path";

const PORT = 1313;
const parent = path.dirname(__dirname);
const EVENTS_DIR = path.join(parent, 'tmp/events');

fs.mkdirSync(EVENTS_DIR, { recursive: true });

const server = http.createServer((req, res) => {
  let body = '';
  req.on('data', chunk => { body += chunk; });
  req.on('end', () => {
    const event = req.headers['x-forgejo-event'] ?? 'unknown';
    const eventType = req.headers['x-forgejo-event-type'] ?? 'unknown';
    const timestamp = Date.now();
    const filename = `${event}+${eventType}_${timestamp}.json`;

    let parsedBody;
    try {
      parsedBody = JSON.parse(body);
    } catch {
      parsedBody = body;
    }

    const payload = { headers: req.headers, body: parsedBody };
    fs.writeFileSync(path.join(EVENTS_DIR, filename), JSON.stringify(payload, null, 2));
    console.log(`Saved: ${filename}`);

    res.writeHead(200, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({ ok: true }));
  });
});

server.listen(PORT, () => {
  console.log(`Server running at http://localhost:${PORT}/`);
});
