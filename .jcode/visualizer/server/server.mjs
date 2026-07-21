// =============================================================================
// .jcode/visualizer/server/server.mjs
// =============================================================================
// Servidor del visualizador en tiempo real del arnés jcode.
//
// Funciona en DOS modos:
//   1. LIVE: se conecta al socket de jcode (config.toml [jcode] socket) y
//      lee eventos nativos (session_start, tool_call, swarm_spawn, etc.)
//   2. SIMULATION: si no hay socket de jcode disponible, simula eventos
//      para que puedas ver el visualizador funcionando sin jcode corriendo.
//
// Emite eventos a los browsers conectados vía WebSocket. El frontend
// renderiza un grafo D3 force-directed con:
//   - Nodos: agentes (coordinador + workers + reviewer + guardrails)
//   - Aristas: mensajes entre agentes (swarm spawns, handoffs, reviews)
//   - Loops: panel lateral con loops activos/cerrados, iteraciones, strikes
//   - Gobernanza: score de compliance, handoffs pendientes, R-3STRIKE-MVP
//   - Logs: stream en vivo por agente
// =============================================================================

import http from 'http';
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
import { WebSocketServer } from 'ws';
import net from 'net';
import { spawn } from 'child_process';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const PUBLIC_DIR = path.join(__dirname, '..', 'public');
const PORT = process.env.VIZ_PORT || 7777;
const HOST = process.env.VIZ_HOST || '127.0.0.1';

// =============================================================================
// State compartido
// =============================================================================
const state = {
  agents: new Map(),       // id -> {id, role, status, parent, spawnedAt, closedAt, logs: []}
  loops: new Map(),        // id -> {id, type, goal, status, iter, budget, score, startedAt, closedAt}
  messages: [],            // [{from, to, type, content, ts}] (último 500)
  compliance: {            // estado del compliance
    score: 0,
    strikes: 0,
    srsi: false,
    ddlp: false,
    handoff: false,
    reads_this_turn: 0,
    current_loop: null
  },
  events: [],              // log cronológico de eventos (último 1000)
  history: new Map()       // session_id -> eventos archivados
};

function logEvent(type, data) {
  const evt = { type, data, ts: new Date().toISOString() };
  state.events.push(evt);
  if (state.events.length > 1000) state.events.shift();
  broadcast({ kind: 'event', ...evt });
  if (process.env.VIZ_DEBUG) console.error(`[event] ${type}`, JSON.stringify(data).slice(0, 200));
}

// =============================================================================
// WebSocket broadcast
// =============================================================================
const wss = new WebSocketServer({ noServer: true });

function broadcast(msg) {
  const data = JSON.stringify(msg);
  for (const client of wss.clients) {
    if (client.readyState === 1) client.send(data);
  }
}

function sendSnapshot(client) {
  client.send(JSON.stringify({
    kind: 'snapshot',
    agents: Array.from(state.agents.values()),
    loops: Array.from(state.loops.values()),
    messages: state.messages.slice(-100),
    compliance: state.compliance,
    events: state.events.slice(-100)
  }));
}

// =============================================================================
// HTTP server — sirve el frontend + upgrade a WebSocket
// =============================================================================
const server = http.createServer((req, res) => {
  let filePath = req.url === '/' ? '/index.html' : req.url;
  filePath = path.join(PUBLIC_DIR, filePath);

  // Prevenir path traversal
  if (!filePath.startsWith(PUBLIC_DIR)) {
    res.writeHead(403); res.end('Forbidden'); return;
  }

  const ext = path.extname(filePath);
  const types = {
    '.html': 'text/html; charset=utf-8',
    '.js': 'application/javascript; charset=utf-8',
    '.css': 'text/css; charset=utf-8',
    '.json': 'application/json; charset=utf-8',
    '.svg': 'image/svg+xml',
    '.png': 'image/png',
    '.ico': 'image/x-icon'
  };

  fs.readFile(filePath, (err, body) => {
    if (err) { res.writeHead(404); res.end('Not found'); return; }
    res.writeHead(200, { 'Content-Type': types[ext] || 'application/octet-stream' });
    res.end(body);
  });
});

server.on('upgrade', (req, socket, head) => {
  wss.handleUpgrade(req, socket, head, (ws) => {
    sendSnapshot(ws);
    ws.on('message', (raw) => {
      try {
        const msg = JSON.parse(raw.toString());
        handleClientMessage(ws, msg);
      } catch (e) {
        console.error('Invalid client message:', e.message);
      }
    });
  });
});

// =============================================================================
// Client commands (replay, filter, etc.)
// =============================================================================
function handleClientMessage(ws, msg) {
  switch (msg.cmd) {
    case 'snapshot':
      sendSnapshot(ws);
      break;
    case 'replay':
      replayHistory(ws, msg.from || null);
      break;
    case 'clear':
      state.agents.clear();
      state.loops.clear();
      state.messages = [];
      state.events = [];
      state.compliance = { score: 0, strikes: 0, srsi: false, ddlp: false, handoff: false, reads_this_turn: 0, current_loop: null };
      broadcast({ kind: 'cleared' });
      break;
    case 'inject':
      // Para testing: inyectar evento manual
      logEvent(msg.eventType || 'manual', msg.payload || {});
      break;
    default:
      console.error('Unknown client cmd:', msg.cmd);
  }
}

function replayHistory(ws, fromTs) {
  const events = fromTs ? state.events.filter(e => e.ts >= fromTs) : state.events;
  for (const evt of events) {
    ws.send(JSON.stringify({ kind: 'event', ...evt }));
  }
}

// =============================================================================
// Live mode: leer del socket de jcode
// =============================================================================
const JCODE_SOCKET = process.env.JCODE_SOCKET || '/run/user/1000/jcode.sock';

function tryConnectJcode() {
  const sock = net.createConnection({ path: JCODE_SOCKET }, () => {
    console.error(`[jcode] connected to ${JCODE_SOCKET}`);
    // Suscribirse a eventos nativos
    sock.write(JSON.stringify({ cmd: 'subscribe', events: ['*'] }) + '\n');
  });

  sock.on('data', (buf) => {
    const lines = buf.toString().split('\n').filter(Boolean);
    for (const line of lines) {
      try {
        const evt = JSON.parse(line);
        processJcodeEvent(evt);
      } catch (e) {
        // línea no-JSON, ignorar
      }
    }
  });

  sock.on('error', () => {
    // Socket no disponible — entrar en modo simulación
  });
  sock.on('close', () => {
    // Reintentar en 5s
    setTimeout(tryConnectJcode, 5000);
  });
}

function processJcodeEvent(evt) {
  switch (evt.type) {
    case 'session_start':
      logEvent('session_start', { session_id: evt.session_id, cwd: evt.cwd });
      // Crear agente coordinador
      upsertAgent(evt.session_id, 'coordinator', 'active', null);
      break;

    case 'turn_start':
      state.compliance.reads_this_turn = 0;
      state.compliance.srsi = false;
      logEvent('turn_start', { session_id: evt.session_id, turn: evt.turn });
      break;

    case 'tool_call':
      const sessionId = evt.session_id;
      if (state.agents.has(sessionId)) {
        state.agents.get(sessionId).logs.push({
          ts: new Date().toISOString(),
          tool: evt.tool,
          args: (evt.args || '').slice(0, 200)
        });
        // SRSI detection
        if (['grep', 'rg', 'agentgrep'].includes(evt.tool)) {
          state.compliance.srsi = true;
        }
        state.compliance.reads_this_turn++;
      }
      logEvent('tool_call', evt);
      break;

    case 'swarm_spawn':
      upsertAgent(evt.child_session_id, evt.role || 'worker', 'active', evt.parent_session_id);
      logEvent('swarm_spawn', {
        parent: evt.parent_session_id,
        child: evt.child_session_id,
        role: evt.role
      });
      break;

    case 'swarm_message':
      state.messages.push({
        from: evt.from_session_id,
        to: evt.to_session_id,
        type: evt.message_type,
        content: (evt.content || '').slice(0, 500),
        ts: new Date().toISOString()
      });
      if (state.messages.length > 500) state.messages.shift();
      logEvent('swarm_message', evt);
      break;

    case 'swarm_close':
      if (state.agents.has(evt.session_id)) {
        const a = state.agents.get(evt.session_id);
        a.status = 'closed';
        a.closedAt = new Date().toISOString();
      }
      logEvent('swarm_close', { session_id: evt.session_id });
      break;

    case 'loop_start':
      state.loops.set(evt.loop_id, {
        id: evt.loop_id,
        type: evt.task_class,
        goal: evt.goal,
        status: 'active',
        iter: 0,
        budget: evt.budget || 5,
        score: 0,
        startedAt: new Date().toISOString(),
        closedAt: null,
        agent: evt.session_id
      });
      state.compliance.current_loop = evt.loop_id;
      logEvent('loop_start', evt);
      break;

    case 'loop_iter':
      if (state.loops.has(evt.loop_id)) {
        const l = state.loops.get(evt.loop_id);
        l.iter++;
      }
      logEvent('loop_iter', evt);
      break;

    case 'loop_close':
      if (state.loops.has(evt.loop_id)) {
        const l = state.loops.get(evt.loop_id);
        l.status = evt.success ? 'success' : 'failed';
        l.score = evt.score || 0;
        l.closedAt = new Date().toISOString();
      }
      if (state.compliance.current_loop === evt.loop_id) {
        state.compliance.current_loop = null;
      }
      logEvent('loop_close', evt);
      break;

    case 'compliance_update':
      Object.assign(state.compliance, evt.compliance);
      logEvent('compliance_update', evt.compliance);
      break;

    case 'strike':
      state.compliance.strikes++;
      logEvent('strike', { rule: evt.rule, detail: evt.detail });
      break;

    case 'turn_end':
      logEvent('turn_end', { session_id: evt.session_id, score: evt.score });
      break;

    case 'session_end':
      if (state.agents.has(evt.session_id)) {
        state.agents.get(evt.session_id).status = 'closed';
        state.agents.get(evt.session_id).closedAt = new Date().toISOString();
      }
      logEvent('session_end', evt);
      break;

    default:
      logEvent(evt.type || 'unknown', evt);
  }

  // Recalcular score aprox
  recalcScore();
  broadcastState();
}

function upsertAgent(id, role, status, parent) {
  if (!state.agents.has(id)) {
    state.agents.set(id, {
      id,
      role,
      status,
      parent,
      spawnedAt: new Date().toISOString(),
      closedAt: null,
      logs: []
    });
  } else {
    const a = state.agents.get(id);
    a.role = role || a.role;
    a.status = status || a.status;
  }
}

function recalcScore() {
  let score = 0;
  if (state.compliance.reads_this_turn >= 3) score += 15;
  if (state.compliance.reads_this_turn > 0 || state.events.length > 0) score += 15;
  if (state.compliance.srsi) score += 15;
  if (state.compliance.ddlp) score += 10;
  if (state.compliance.handoff) score += 10;
  if (state.compliance.strikes === 0) score += 10;
  else if (state.compliance.strikes < 3) score += 5;
  score += 15; // drill placeholder
  score += 10; // clean placeholder
  state.compliance.score = Math.min(score, 100);
}

function broadcastState() {
  broadcast({
    kind: 'state',
    agents: Array.from(state.agents.values()),
    loops: Array.from(state.loops.values()),
    messages: state.messages.slice(-100),
    compliance: state.compliance
  });
}

// =============================================================================
// Simulation mode (cuando no hay jcode socket)
// =============================================================================
let simMode = false;
let simInterval = null;

function startSimulation() {
  if (simMode) return;
  simMode = true;
  console.error('[viz] simulation mode enabled (jcode socket not available)');

  // Sesión inicial: coordinador
  const coordId = 'session_coordinator_' + Date.now();
  upsertAgent(coordId, 'coordinator', 'active', null);
  logEvent('session_start', { session_id: coordId, cwd: process.cwd() });

  // Loop inicial
  const loopId = 'L-SLICE-001';
  state.loops.set(loopId, {
    id: loopId,
    type: 'SLICE',
    goal: 'Implementar endpoint POST /items con evento sidecar',
    status: 'active',
    iter: 0,
    budget: 5,
    score: 0,
    startedAt: new Date().toISOString(),
    closedAt: null,
    agent: coordId
  });
  state.compliance.current_loop = loopId;
  logEvent('loop_start', { loop_id: loopId, task_class: 'SLICE', goal: '...', budget: 5, session_id: coordId });

  // Simular eventos periódicamente
  simInterval = setInterval(() => simulateTick(coordId, loopId), 2500);
}

const simTools = ['grep', 'rg', 'edit', 'write', 'bash', 'read', 'grep', 'rg'];
const simWorkers = [
  { role: 'arquitecto-proyecto', task: 'Diseñar plan para POST /items' },
  { role: 'worker-ejecutor', task: 'Implementar createItem() en src/api/items.ts' },
  { role: 'worker-ejecutor', task: 'Implementar dispatchEvent() en src/events/dispatcher.ts' },
  { role: 'reviewer-calidad', task: 'Validar fixed_check del loop L-SLICE-001' }
];

function simulateTick(coordId, loopId) {
  const tick = Math.floor(Math.random() * 10);
  const turn = Math.floor(state.events.length / 5);

  // Turn start
  if (state.events.length % 5 === 0) {
    state.compliance.reads_this_turn = 0;
    state.compliance.srsi = false;
    logEvent('turn_start', { session_id: coordId, turn });
  }

  // Tool calls del coordinador
  const tool = simTools[Math.floor(Math.random() * simTools.length)];
  if (state.agents.has(coordId)) {
    state.agents.get(coordId).logs.push({
      ts: new Date().toISOString(),
      tool,
      args: `src/api/items.ts patrones_busqueda`
    });
  }
  if (['grep', 'rg'].includes(tool)) {
    state.compliance.srsi = true;
  }
  state.compliance.reads_this_turn++;
  logEvent('tool_call', { session_id: coordId, tool, args: '...' });

  // Spawn workers (20% prob)
  if (tick < 2 && state.agents.size < 5) {
    const w = simWorkers[Math.floor(Math.random() * simWorkers.length)];
    const childId = `session_${w.role.split('-')[0]}_${Date.now()}`;
    upsertAgent(childId, w.role, 'active', coordId);
    logEvent('swarm_spawn', {
      parent_session_id: coordId,
      child_session_id: childId,
      role: w.role
    });
    state.messages.push({
      from: coordId,
      to: childId,
      type: 'task_assignment',
      content: w.task,
      ts: new Date().toISOString()
    });
  }

  // Loop iter (cada ~5 ticks)
  if (state.events.length % 12 === 0 && state.loops.has(loopId)) {
    const l = state.loops.get(loopId);
    l.iter++;
    logEvent('loop_iter', { loop_id: loopId, iter: l.iter });

    // Cerrar workers cerrados aleatoriamente
    for (const [id, a] of state.agents) {
      if (a.status === 'active' && a.role !== 'coordinator' && Math.random() < 0.4) {
        a.status = 'closed';
        a.closedAt = new Date().toISOString();
        logEvent('swarm_close', { session_id: id });
        state.messages.push({
          from: id,
          to: coordId,
          type: 'output',
          content: '✅ done — see commit abc1234',
          ts: new Date().toISOString()
        });
      }
    }

    // Strike aleatorio (10%)
    if (Math.random() < 0.1 && state.compliance.strikes < 2) {
      state.compliance.strikes++;
      logEvent('strike', { rule: 'srsi_missing', detail: 'SRSI no detectado antes de fix' });
    }

    // Cerrar loop cuando llega a budget
    if (l.iter >= l.budget) {
      l.status = 'success';
      l.closedAt = new Date().toISOString();
      l.score = 85 + Math.floor(Math.random() * 15);
      state.compliance.current_loop = null;
      state.compliance.handoff = true;
      logEvent('loop_close', {
        loop_id: loopId,
        success: true,
        score: l.score
      });
      logEvent('turn_end', { session_id: coordId, score: state.compliance.score });
    }
  }

  recalcScore();
  broadcastState();
}

// =============================================================================
// Main
// =============================================================================
server.listen(PORT, HOST, () => {
  console.error(`[viz] HTTP server listening on http://${HOST}:${PORT}`);
  console.error(`[viz] WebSocket ready for connections`);

  // Intentar conectarse a jcode; si falla, simular
  if (process.env.VIZ_NO_SIM !== '1') {
    // Test if socket exists
    fs.access(JCODE_SOCKET, fs.constants.R_OK | fs.constants.W_OK, (err) => {
      if (err) {
        console.error(`[viz] jcode socket ${JCODE_SOCKET} not available`);
        startSimulation();
      } else {
        tryConnectJcode();
        // Si después de 3s no recibimos nada, también simular
        setTimeout(() => {
          if (state.events.length === 0 && !simMode) {
            console.error('[viz] no events from jcode, starting simulation alongside');
            startSimulation();
          }
        }, 3000);
      }
    });
  }
});

// Graceful shutdown
process.on('SIGINT', () => {
  console.error('\n[viz] shutting down...');
  if (simInterval) clearInterval(simInterval);
  server.close();
  process.exit(0);
});
