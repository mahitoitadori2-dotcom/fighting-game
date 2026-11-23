// UNIVERSAL BEATDOWN - ONLINE RELAY (2026-11-23). Lobbies by ROOM CODE + a "quickplay" list of open rooms.
// Plain Node.js, NO npm packages (it speaks WebSocket itself), so it runs on any free Node host.
//
//   node server/relay.js            -> listens on PORT (env) or 8787
//
// PROTOCOL (text frames = JSON control messages, binary frames = game data passed through untouched):
//   client -> {"t":"host", "mode":"versus"|"story", "name":"..."}   server -> {"t":"room", "code":"K7QX2"}
//   client -> {"t":"join", "code":"K7QX2"}                           server -> {"t":"joined", "mode":..., "host":"..."}
//   client -> {"t":"quick", "mode":"versus"}                         joins the oldest open room of that mode
//   client -> {"t":"list"}                                           server -> {"t":"rooms", "rooms":[{code,mode,host}]}
//   server -> {"t":"peer"} (to the host when the guest arrives), {"t":"left"} (the other one went), {"t":"error","msg":...}
//   BINARY frames from one player go to the other one in the same room (the game's inputs / snapshots).
// A room holds 2 players (host + guest). It is removed when the host leaves.

const http = require('http');
const crypto = require('crypto');
const PORT = +(process.env.PORT || 8787);
const CODE_CHARS = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';     // No 0/O, 1/I
const rooms = new Map();                                      // code -> {mode, host, guest, hostName, made}

function newCode() {
  for (;;) {
    let c = '';
    for (let i = 0; i < 5; i++) c += CODE_CHARS[crypto.randomInt(CODE_CHARS.length)];
    if (!rooms.has(c)) return c;
  }
}

// ---------- minimal WebSocket (RFC 6455) ----------
function sendFrame(sock, opcode, payload) {
  if (sock.destroyed) return;
  const len = payload.length;
  let head;
  if (len < 126) { head = Buffer.alloc(2); head[1] = len; }
  else if (len < 65536) { head = Buffer.alloc(4); head[1] = 126; head.writeUInt16BE(len, 2); }
  else { head = Buffer.alloc(10); head[1] = 127; head.writeBigUInt64BE(BigInt(len), 2); }
  head[0] = 0x80 | opcode;
  sock.write(Buffer.concat([head, payload]));
}
const sendJSON = (sock, obj) => sock && sendFrame(sock, 0x1, Buffer.from(JSON.stringify(obj)));

function attach(sock, onText, onBinary, onClose) {
  let buf = Buffer.alloc(0);
  let frag = null, fragOp = 0;
  sock.on('data', (chunk) => {
    buf = Buffer.concat([buf, chunk]);
    for (;;) {
      if (buf.length < 2) return;
      const fin = (buf[0] & 0x80) !== 0, op = buf[0] & 0x0f, masked = (buf[1] & 0x80) !== 0;
      let len = buf[1] & 0x7f, off = 2;
      if (len === 126) { if (buf.length < 4) return; len = buf.readUInt16BE(2); off = 4; }
      else if (len === 127) { if (buf.length < 10) return; len = Number(buf.readBigUInt64BE(2)); off = 10; }
      if (len > 4 * 1024 * 1024) { sock.destroy(); return; }            // (Nothing in the game is this big)
      const need = off + (masked ? 4 : 0) + len;
      if (buf.length < need) return;
      let data = buf.subarray(off + (masked ? 4 : 0), need);
      if (masked) {
        const mask = buf.subarray(off, off + 4);
        data = Buffer.from(data);
        for (let i = 0; i < data.length; i++) data[i] ^= mask[i & 3];
      }
      buf = buf.subarray(need);
      if (op === 0x8) { sock.end(); return; }
      if (op === 0x9) { sendFrame(sock, 0xA, data); continue; }       // ping -> pong
      if (op === 0xA) continue;
      if (op === 0x0) { if (frag) frag = Buffer.concat([frag, data]); }
      else { frag = data; fragOp = op; }
      if (!fin) continue;
      const msg = frag; frag = null;
      if (fragOp === 0x1) onText(msg.toString('utf8')); else if (fragOp === 0x2) onBinary(msg);
    }
  });
  sock.on('close', onClose);
  sock.on('error', () => sock.destroy());
}

// ---------- lobby ----------
function otherOf(room, sock) { return room.host === sock ? room.guest : room.host; }

function leave(sock) {
  const code = sock.ubRoom;
  if (!code || !rooms.has(code)) return;
  const room = rooms.get(code);
  sendJSON(otherOf(room, sock), { t: 'left' });
  if (room.host === sock) { rooms.delete(code); if (room.guest) room.guest.ubRoom = null; }
  else room.guest = null;
  sock.ubRoom = null;
}

function joinRoom(sock, code) {
  const room = rooms.get(code);
  if (!room) return sendJSON(sock, { t: 'error', msg: 'NO ROOM WITH THAT CODE' });
  if (room.guest) return sendJSON(sock, { t: 'error', msg: 'THAT ROOM IS FULL' });
  leave(sock);
  room.guest = sock;
  sock.ubRoom = code;
  sendJSON(sock, { t: 'joined', code, mode: room.mode, host: room.hostName });
  sendJSON(room.host, { t: 'peer' });
}

function onMessage(sock, text) {
  let m;
  try { m = JSON.parse(text); } catch (e) { return; }
  switch (m.t) {
    case 'host': {
      leave(sock);
      const code = newCode();
      rooms.set(code, { mode: m.mode === 'story' ? 'story' : 'versus', host: sock, guest: null, hostName: String(m.name || 'PLAYER').slice(0, 16), made: Date.now() });
      sock.ubRoom = code;
      sendJSON(sock, { t: 'room', code });
      break;
    }
    case 'join': joinRoom(sock, String(m.code || '').toUpperCase().trim()); break;
    case 'quick': {
      const open = [...rooms.entries()].filter(([, r]) => !r.guest && r.host !== sock && r.mode === (m.mode || 'versus')).sort((a, b) => a[1].made - b[1].made);
      if (open.length) joinRoom(sock, open[0][0]); else sendJSON(sock, { t: 'error', msg: 'NO OPEN ROOMS RIGHT NOW' });
      break;
    }
    case 'list':
      sendJSON(sock, { t: 'rooms', rooms: [...rooms.entries()].filter(([, r]) => !r.guest).map(([code, r]) => ({ code, mode: r.mode, host: r.hostName })) });
      break;
    case 'leave': leave(sock); break;
  }
}

const server = http.createServer((req, res) => {
  res.writeHead(200, { 'content-type': 'text/plain' });
  res.end('Universal Beatdown relay: ' + rooms.size + ' rooms\n');                    // (Health check for hosts)
});
server.on('upgrade', (req, sock) => {
  const key = req.headers['sec-websocket-key'];
  if (!key) { sock.destroy(); return; }
  const accept = crypto.createHash('sha1').update(key + '258EAFA5-E914-47DA-95CA-C5AB0DC85B11').digest('base64');
  sock.write('HTTP/1.1 101 Switching Protocols\r\nUpgrade: websocket\r\nConnection: Upgrade\r\nSec-WebSocket-Accept: ' + accept + '\r\n\r\n');
  sock.setNoDelay(true);
  attach(sock, (text) => onMessage(sock, text), (bin) => {
    const room = sock.ubRoom && rooms.get(sock.ubRoom);
    if (room) { const o = otherOf(room, sock); if (o) sendFrame(o, 0x2, bin); }
  }, () => leave(sock));
});
server.listen(PORT, () => console.log('relay listening on ' + PORT));
