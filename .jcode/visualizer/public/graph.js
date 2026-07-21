/* =============================================================================
   .jcode/visualizer/public/graph.js
   Grafo D3 force-directed de agentes en tiempo real
   ============================================================================= */

const Graph = (() => {
  const svg = d3.select('#graph');
  const width = svg.node().clientWidth || 800;
  const height = svg.node().clientHeight || 600;

  // Definir gradientes para cada rol
  const defs = svg.append('defs');
  const roles = [
    { name: 'coordinator', color: '#58a6ff' },
    { name: 'worker-ejecutor', color: '#3fb950' },
    { name: 'arquitecto-proyecto', color: '#39d0d8' },
    { name: 'reviewer-calidad', color: '#d29922' },
    { name: 'guardrails', color: '#bc8cff' },
    { name: 'unknown', color: '#8b949e' }
  ];
  roles.forEach(r => {
    const grad = defs.append('radialGradient')
      .attr('id', `grad-${r.name}`)
      .attr('cx', '50%').attr('cy', '50%');
    grad.append('stop').attr('offset', '0%').attr('stop-color', r.color).attr('stop-opacity', 1);
    grad.append('stop').attr('offset', '100%').attr('stop-color', r.color).attr('stop-opacity', 0.6);
  });

  // Container groups
  const linkGroup = svg.append('g').attr('class', 'links');
  const nodeGroup = svg.append('g').attr('class', 'nodes');

  // Force simulation
  const sim = d3.forceSimulation()
    .force('link', d3.forceLink().id(d => d.id).distance(120).strength(0.5))
    .force('charge', d3.forceManyBody().strength(-180))
    .force('center', d3.forceCenter(width / 2, height / 2))
    .force('collide', d3.forceCollide().radius(40));

  let linkSel = linkGroup.selectAll('path');
  let nodeSel = nodeGroup.selectAll('g');

  const roleColors = {
    'coordinator': '#58a6ff',
    'worker-ejecutor': '#3fb950',
    'arquitecto-proyecto': '#39d0d8',
    'reviewer-calidad': '#d29922',
    'guardrails': '#bc8cff'
  };

  const roleShort = {
    'coordinator': 'COORD',
    'worker-ejecutor': 'WORKER',
    'arquitecto-proyecto': 'ARCH',
    'reviewer-calidad': 'REVIEW',
    'guardrails': 'GUARD'
  };

  function getNodeRadius(d) {
    if (d.role === 'coordinator') return 22;
    return 16;
  }

  function getNodeColor(d) {
    if (d.status === 'closed') return '#8b949e';
    return roleColors[d.role] || '#8b949e';
  }

  function update(agents, messages) {
    // Nodes from agents
    const nodes = agents.map(a => ({ ...a }));

    // Links: parent → child (swarm hierarchy) + messages
    const links = [];
    const linkSet = new Set();

    agents.forEach(a => {
      if (a.parent && agents.find(x => x.id === a.parent)) {
        const key = `${a.parent}->${a.id}`;
        if (!linkSet.has(key)) {
          linkSet.add(key);
          links.push({ source: a.parent, target: a.id, type: 'spawn' });
        }
      }
    });

    messages.forEach(m => {
      if (agents.find(x => x.id === m.from) && agents.find(x => x.id === m.to)) {
        const key = `${m.from}->${m.to}-${m.ts}`;
        if (!linkSet.has(key)) {
          linkSet.add(key);
          links.push({ source: m.from, target: m.to, type: m.type, content: m.content });
        }
      }
    });

    // Apply data
    linkSel = linkGroup.selectAll('path').data(links, d => `${d.source.id || d.source}->${d.target.id || d.target}-${d.type}`);
    linkSel.exit().remove();
    linkSel = linkSel.enter().append('path')
      .attr('class', d => `link-line ${d.type === 'spawn' ? 'link-active' : ''}`)
      .attr('fill', 'none')
      .attr('stroke-dasharray', d => d.type === 'spawn' ? 'none' : '4 2')
      .merge(linkSel);

    nodeSel = nodeGroup.selectAll('g').data(nodes, d => d.id);
    nodeSel.exit().remove();

    const nodeEnter = nodeSel.enter().append('g')
      .attr('class', 'node')
      .call(d3.drag()
        .on('start', dragStart)
        .on('drag', dragging)
        .on('end', dragEnd));

    nodeEnter.append('circle')
      .attr('class', 'node-circle')
      .attr('r', getNodeRadius)
      .attr('fill', d => `url(#grad-${d.role || 'unknown'})`)
      .attr('stroke', getNodeColor)
      .attr('stroke-width', 2);

    nodeEnter.append('text')
      .attr('class', 'node-label')
      .attr('dy', '-0.3em')
      .text(d => roleShort[d.role] || d.role || 'AGENT');

    nodeEnter.append('text')
      .attr('class', 'node-role')
      .attr('dy', '1.2em')
      .text(d => d.id.split('_')[1] || d.id.slice(-6));

    // Status indicator (small dot)
    nodeEnter.append('circle')
      .attr('class', 'node-status')
      .attr('cx', d => getNodeRadius(d) * 0.7)
      .attr('cy', d => -getNodeRadius(d) * 0.7)
      .attr('r', 4)
      .attr('fill', d => d.status === 'active' ? '#3fb950' : '#8b949e')
      .attr('stroke', '#0d1117')
      .attr('stroke-width', 1.5);

    nodeSel = nodeEnter.merge(nodeSel);

    // Update status dot on existing nodes
    nodeSel.select('.node-status')
      .attr('fill', d => d.status === 'active' ? '#3fb950' : '#8b949e');

    nodeSel.select('.node-circle')
      .attr('stroke', getNodeColor);

    // Update simulation
    sim.nodes(nodes);
    sim.force('link').links(links);
    sim.alpha(0.6).restart();
  }

  function dragStart(event, d) {
    if (!event.active) sim.alphaTarget(0.3).restart();
    d.fx = d.x; d.fy = d.y;
  }
  function dragging(event, d) { d.fx = event.x; d.fy = event.y; }
  function dragEnd(event, d) {
    if (!event.active) sim.alphaTarget(0);
    d.fx = null; d.fy = null;
  }

  // Tick
  sim.on('tick', () => {
    linkSel.attr('d', d => {
      const sx = d.source.x, sy = d.source.y;
      const tx = d.target.x, ty = d.target.y;
      const dr = Math.sqrt((tx - sx) ** 2 + (ty - sy) ** 2) * 1.5;
      return `M${sx},${sy}A${dr},${dr} 0 0,1 ${tx},${ty}`;
    });
    nodeSel.attr('transform', d => `translate(${d.x},${d.y})`);
  });

  // Resize
  window.addEventListener('resize', () => {
    const w = svg.node().clientWidth;
    const h = svg.node().clientHeight;
    sim.force('center', d3.forceCenter(w / 2, h / 2));
    sim.alpha(0.3).restart();
  });

  // Force controls
  document.getElementById('force-strength').addEventListener('input', (e) => {
    sim.force('charge').strength(-parseInt(e.target.value));
    sim.alpha(0.3).restart();
  });
  document.getElementById('link-distance').addEventListener('input', (e) => {
    sim.force('link').distance(parseInt(e.target.value));
    sim.alpha(0.3).restart();
  });

  return { update };
})();
