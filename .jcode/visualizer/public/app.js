/* =============================================================================
   .jcode/visualizer/public/app.js
   Frontend principal — WebSocket + UI updates
   ============================================================================= */

const WS_URL = `ws://${location.hostname}:${location.port || 7777}`;
let ws = null;
let startTime = Date.now();

// =============================================================================
// WebSocket
// =============================================================================
function connect() {
  setStatus('connecting', 'Conectando…');
  ws = new WebSocket(WS_URL);

  ws.onopen = () => {
    setStatus('connected', 'Conectado');
    ws.send(JSON.stringify({ cmd: 'snapshot' }));
  };

  ws.onmessage = (ev) => {
    try {
      const msg = JSON.parse(ev.data);
      handleMessage(msg);
    } catch (e) {
      console.error('Invalid message:', e);
    }
  };

  ws.onclose = () => {
    setStatus('disconnected', 'Desconectado — reintentando…');
    setTimeout(connect, 2000);
  };

  ws.onerror = () => {
    setStatus('disconnected', 'Error de conexión');
  };
}

function setStatus(state, label) {
  const pill = document.getElementById('conn-status');
  pill.querySelector('.dot').className = `dot dot-${state}`;
  pill.querySelector('.label').textContent = label;
}

function send(msg) {
  if (ws && ws.readyState === WebSocket.OPEN) {
    ws.send(JSON.stringify(msg));
  }
}

// =============================================================================
// Message handlers
// =============================================================================
function handleMessage(msg) {
  switch (msg.kind) {
    case 'snapshot':
      renderSnapshot(msg);
      break;
    case 'state':
      renderState(msg);
      break;
    case 'event':
      renderEvent(msg);
      break;
    case 'cleared':
      document.getElementById('events-list').innerHTML = '';
      document.getElementById('messages-list').innerHTML = '';
      document.getElementById('logs-list').innerHTML = '';
      Graph.update([], []);
      break;
  }
}

function renderSnapshot(snap) {
  renderState(snap);
  // Renderizar eventos históricos
  (snap.events || []).forEach(renderEvent);
}

function renderState(state) {
  // Graph
  Graph.update(state.agents || [], state.messages || []);

  // Loops
  renderLoops(state.loops || []);

  // Compliance
  renderCompliance(state.compliance || {});

  // Messages list
  renderMessages(state.messages || []);

  // Agent select
  renderAgentSelect(state.agents || []);

  // Footer stats
  document.getElementById('event-count').textContent = state.events ? state.events.length : 0;
  const activeAgents = (state.agents || []).filter(a => a.status === 'active').length;
  document.getElementById('active-agents').textContent = activeAgents;
}

function renderLoops(loops) {
  const container = document.getElementById('loops-list');
  if (loops.length === 0) {
    container.innerHTML = '<div class="loop-card"><em>Sin loops activos</em></div>';
    return;
  }

  // Mostrar activos primero, luego cerrados (más recientes arriba)
  const sorted = [...loops].sort((a, b) => {
    if (a.status === 'active' && b.status !== 'active') return -1;
    if (b.status === 'active' && a.status !== 'active') return 1;
    return (b.startedAt || '').localeCompare(a.startedAt || '');
  }).slice(0, 10);

  container.innerHTML = sorted.map(l => {
    const progress = l.budget ? Math.min(100, (l.iter / l.budget) * 100) : 0;
    const statusClass = l.status === 'active' ? 'active' : (l.status === 'success' ? 'success' : 'failed');
    const statusIcon = l.status === 'active' ? '🟢' : (l.status === 'success' ? '✅' : '❌');
    return `
      <div class="loop-card ${statusClass}">
        <div class="loop-header">
          <span class="loop-id">${l.id}</span>
          <span class="loop-type">${l.type}</span>
        </div>
        <div class="loop-goal">${l.goal || '—'}</div>
        <div class="loop-progress">
          <span>${statusIcon}</span>
          <div class="loop-progress-bar">
            <div class="loop-progress-fill" style="width:${progress}%"></div>
          </div>
          <span>${l.iter}/${l.budget}</span>
        </div>
        <div class="loop-meta">
          <span>started: ${l.startedAt ? new Date(l.startedAt).toLocaleTimeString() : '—'}</span>
          ${l.score ? `<span>score: ${l.score}/100</span>` : ''}
        </div>
      </div>
    `;
  }).join('');
}

function renderCompliance(c) {
  // Score circle
  const score = c.score || 0;
  const circle = document.getElementById('score-circle');
  const circumference = 2 * Math.PI * 45;
  const offset = circumference - (score / 100) * circumference;
  circle.style.strokeDashoffset = offset;
  if (score >= 80) circle.style.stroke = '#3fb950';
  else if (score >= 50) circle.style.stroke = '#d29922';
  else circle.style.stroke = '#f85149';
  document.getElementById('score-value').textContent = score;

  // Items
  setCI('ci-srsi', c.srsi ? '✓' : '✗', c.srsi ? 'ok' : 'warn');
  setCI('ci-ddlp', c.ddlp ? '✓' : '✗', c.ddlp ? 'ok' : 'warn');
  setCI('ci-handoff', c.handoff ? '✓' : '✗', c.handoff ? 'ok' : 'warn');
  setCI('ci-reads', c.reads_this_turn || 0, c.reads_this_turn >= 3 ? 'ok' : 'warn');
  setCI('ci-strikes', c.strikes || 0, (c.strikes || 0) === 0 ? 'ok' : ((c.strikes || 0) >= 3 ? 'danger' : 'warn'));
  setCI('ci-loop', c.current_loop || '—', c.current_loop ? 'ok' : '');

  // Strike bar
  const strikes = c.strikes || 0;
  const fill = document.getElementById('strike-bar-fill');
  fill.style.width = `${Math.min(100, (strikes / 3) * 100)}%`;
  fill.className = strikes >= 3 ? 'strike-bar-fill danger' : 'strike-bar-fill';
  document.getElementById('strike-count').textContent = strikes;
}

function setCI(id, value, cls) {
  const el = document.getElementById(id);
  el.querySelector('.ci-value').textContent = value;
  el.className = `compliance-item ${cls}`;
}

function renderEvent(evt) {
  const list = document.getElementById('events-list');
  const li = document.createElement('li');
  const ts = evt.ts ? new Date(evt.ts).toLocaleTimeString() : '';
  const type = evt.type || 'event';
  const data = typeof evt.data === 'object' ? JSON.stringify(evt.data).slice(0, 200) : String(evt.data || '');

  li.innerHTML = `<span class="event-ts">${ts}</span><span class="event-type ${type}">${type}</span>${data}`;
  list.insertBefore(li, list.firstChild);

  // Limitar a 200 items
  while (list.children.length > 200) list.removeChild(list.lastChild);
}

function renderMessages(messages) {
  const list = document.getElementById('messages-list');
  list.innerHTML = messages.map(m => {
    const ts = m.ts ? new Date(m.ts).toLocaleTimeString() : '';
    const fromShort = (m.from || '').split('_')[1] || (m.from || '').slice(-6);
    const toShort = (m.to || '').split('_')[1] || (m.to || '').slice(-6);
    return `<li>
      <span class="event-ts">${ts}</span>
      <span class="message-from">${fromShort}</span>
      → <span class="message-to">${toShort}</span>
      <span class="message-type">[${m.type}]</span>
      ${escapeHtml(m.content || '').slice(0, 150)}
    </li>`;
  }).join('');
}

let currentAgentId = '';
function renderAgentSelect(agents) {
  const select = document.getElementById('agent-select');
  const prev = currentAgentId;
  select.innerHTML = '<option value="">— selecciona agente —</option>' +
    agents.map(a => `<option value="${a.id}">${a.role} — ${a.id.slice(-8)} (${a.status})</option>`).join('');
  if (prev && agents.find(a => a.id === prev)) select.value = prev;

  select.onchange = () => {
    currentAgentId = select.value;
    renderLogs(agents);
  };

  if (currentAgentId) renderLogs(agents);
}

function renderLogs(agents) {
  const list = document.getElementById('logs-list');
  if (!currentAgentId) { list.innerHTML = ''; return; }
  const a = agents.find(x => x.id === currentAgentId);
  if (!a) { list.innerHTML = ''; return; }

  list.innerHTML = (a.logs || []).map(l => {
    const ts = l.ts ? new Date(l.ts).toLocaleTimeString() : '';
    return `<li><span class="event-ts">${ts}</span><span class="event-type tool_call">${l.tool}</span>${escapeHtml(l.args || '').slice(0, 150)}</li>`;
  }).reverse().join('');
}

function escapeHtml(s) {
  return String(s)
    .replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;').replace(/'/g, '&#39;');
}

// =============================================================================
// UI events
// =============================================================================
document.getElementById('btn-clear').addEventListener('click', () => {
  if (confirm('¿Limpiar todo el estado del visualizador?')) {
    send({ cmd: 'clear' });
  }
});

document.getElementById('btn-replay').addEventListener('click', () => {
  send({ cmd: 'replay' });
});

document.querySelectorAll('.tab').forEach(t => {
  t.addEventListener('click', () => {
    document.querySelectorAll('.tab').forEach(x => x.classList.remove('active'));
    document.querySelectorAll('.tab-content').forEach(x => x.classList.add('hidden'));
    t.classList.add('active');
    document.getElementById(`tab-${t.dataset.tab}`).classList.remove('hidden');
  });
});

// Uptime
setInterval(() => {
  const s = Math.floor((Date.now() - startTime) / 1000);
  const m = Math.floor(s / 60);
  const r = s % 60;
  document.getElementById('uptime').textContent = m > 0 ? `${m}m ${r}s` : `${r}s`;
}, 1000);

// =============================================================================
// Init
// =============================================================================
connect();
