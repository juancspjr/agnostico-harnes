# Visualizador del Arnés JCode

> Debug gráfico en tiempo real del arnés jcode. Ve cómo los agentes se
> comunican, cómo cambian los loops dinámicamente, y si la gobernanza
> funciona.

---

## Cómo correr

```bash
cd .jcode/visualizer/server
npm install                # una sola vez
npm start                  # o: node server.mjs
```

Abre http://localhost:7777 en el navegador.

## Modos de operación

### Modo LIVE (cuando jcode está corriendo)

El servidor intenta conectarse al socket de jcode (definido en
`config.toml [jcode] socket`). Si está disponible, lee eventos nativos:

- `session_start` / `session_end`
- `turn_start` / `turn_end`
- `tool_call` (con tool + args)
- `swarm_spawn` / `swarm_message` / `swarm_close`
- `loop_start` / `loop_iter` / `loop_close`
- `compliance_update`
- `strike`

Y los renderiza en tiempo real en el grafo.

### Modo SIMULATION (sin jcode)

Si el socket de jcode no está disponible, el servidor entra automáticamente
en modo simulación. Genera eventos realistas para que puedas ver el
visualizador funcionando sin tener jcode corriendo.

Para desactivar la simulación:
```bash
VIZ_NO_SIM=1 npm start
```

## Configuración

Variables de entorno:

| Variable | Default | Descripción |
|---|---|---|
| `VIZ_PORT` | `7777` | Puerto HTTP/WS |
| `VIZ_HOST` | `127.0.0.1` | Host a bindear |
| `VIZ_SOCKET` | (de config.toml) | Socket de jcode |
| `VIZ_DEBUG` | (unset) | Log verbose de eventos |
| `VIZ_NO_SIM` | (unset) | Desactivar simulación automática |

## Qué verás

### Panel izquierdo — Grafo de agentes (D3 force-directed)

- **Nodos**: cada agente activo (coordinador + workers + reviewer + guardrails)
- **Color por rol**:
  - 🔵 Coordinador
  - 🟢 Worker-ejecutor
  - 🟡 Reviewer-calidad
  - 🟣 Guardrails
  - 🌊 Arquitecto-proyecto
- **Aristas**: jerarquía de swarm (parent → child) + mensajes entre agentes
- **Drag & drop**: mueve los nodos para reorganizar
- **Status indicator**: punto verde (activo) / gris (cerrado) en cada nodo

### Panel central — Loops + Gobernanza

- **Loops activos y cerrados** con barra de progreso (iter/budget)
- **Score de compliance** (círculo animado 0-100)
- **Grid de compliance**: SRSI / DDLP / Handoff / Reads / Strikes / Loop actual
- **Barra R-3STRIKE-MVP**: visualización de strikes (0-3)

### Panel derecho — Eventos en vivo (3 tabs)

1. **Eventos**: stream cronológico de todos los eventos (session, turn, tool, swarm, loop, strike)
2. **Mensajes**: mensajes entre agentes (de → → tipo → contenido)
3. **Logs/agent**: selecciona un agente y ve sus tool calls

## Controles

- **Limpiar**: reinicia el estado del visualizador
- **Replay**: re-emite eventos históricos
- **Force strength / Link distance**: ajusta el layout del grafo D3

## Arquitectura

```
visualizer/
├── server/
│   ├── package.json
│   └── server.mjs          # HTTP + WebSocket + jcode socket client + simulador
└── public/
    ├── index.html          # Layout 3 paneles
    ├── styles.css          # Dark theme, syntax highlighting
    ├── graph.js            # D3 force-directed graph
    └── app.js              # WebSocket client + UI updates
```

### Flujo de datos

```
jcode (socket)
    ↓ eventos nativos
server.mjs (processJcodeEvent)
    ↓ broadcast WebSocket
app.js (handleMessage)
    ↓ Graph.update + renderLoops + renderCompliance
UI en vivo
```

## Debug de problemas comunes

### "No veo agentes en el grafo"

1. Verifica que jcode esté corriendo (`pgrep -af jcode`)
2. Verifica el socket (`ls -la /run/user/1000/jcode.sock`)
3. Si no hay jcode, debe entrar en modo simulación automáticamente
4. Revisa la consola del navegador (F12) para errores WebSocket

### "El score no sube de 0"

El score se calcula en `server.mjs::recalcScore()`. Necesita:
- `reads_this_turn >= 3` para +15
- `srsi=true` para +15
- `ddlp=true` para +10
- `handoff=true` para +10
- `strikes=0` para +10
- (placeholders de drill + clean suman 25)

### "WebSocket se desconecta cada 2s"

El servidor reintenta cada 2s. Si persiste:
- Verifica que el puerto 7777 esté libre: `lsof -i :7777`
- Verifica firewall

## Extensión

Para añadir nuevos tipos de eventos:

1. En `server.mjs::processJcodeEvent`, añade un case al switch
2. En `app.js::renderEvent`, el CSS ya tiene clases para tipos nuevos (o añade una en `styles.css`)
3. En `graph.js::update`, si el evento afecta nodos/aristas, actualiza el data binding
