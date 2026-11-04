import { INGREDIENTS, SPECIALS } from './catalog.js';
import { generateLevel } from './levels.js';
import { GameSession } from './session.js';
import { LocalProgressStore } from './storage.js';

const app = document.querySelector('#app');
const store = new LocalProgressStore();
const session = new GameSession({ store });
let screen = 'home';
let selected = null;
let paused = false;
let dragStart = null;
let suppressNextClick = false;
let deferredInstallPrompt = null;
let noticeTimer = null;
let audioContext = null;

window.addEventListener('beforeinstallprompt', (event) => {
  event.preventDefault();
  deferredInstallPrompt = event;
});

function mascot(className = '') {
  return `<img class="${className}" src="./assets/yumi.svg" alt="Yumi, mascote da aventura" width="220" height="250">`;
}

function goalLabel(goal) {
  if (goal.type === 'score') return `Alcance ${goal.target} pontos`;
  if (goal.type === 'collect') return `Colete ${goal.target} · ${ingredient(goal.ingredient).name}`;
  return `Crie ${goal.target} especial(is)`;
}

function ingredient(id) {
  if (Number.isInteger(id)) return INGREDIENTS[id] ?? INGREDIENTS[0];
  return INGREDIENTS.find((item) => item.id === id) ?? INGREDIENTS[0];
}

function render() {
  const focusKey = document.activeElement?.dataset?.focusKey;
  if (screen === 'home') app.innerHTML = renderHome();
  else if (screen === 'levels') app.innerHTML = renderLevels();
  else if (screen === 'settings') app.innerHTML = renderSettings();
  else app.innerHTML = renderGame();
  if (focusKey) app.querySelector(`[data-focus-key="${CSS.escape(focusKey)}"]`)?.focus({ preventScroll: true });
}

function renderHome() {
  return `<section class="home-screen" aria-labelledby="home-title">
    <div class="home-copy">
      <p class="eyebrow">Amazônia paraense · fase ${session.progress.unlockedLevel}</p>
      <h1 id="home-title">Sabores, rios <em>e descobertas.</em></h1>
      <p class="lead">Viaje pelo Pará com Yumi. Combine ingredientes da nossa terra, conheça novas paisagens e descubra o que vem depois de cada jogada.</p>
      <div class="button-row">
        <button class="primary-button" data-action="levels" data-focus-key="start">Jogar <span aria-hidden="true">→</span></button>
        <button class="secondary-button" data-action="settings" data-focus-key="home-settings">Configurações</button>
      </div>
      <p class="storyline">Açaí · Cupuaçu · Jambu · Tucupi · Mandioca</p>
      ${session.persistenceError ? `<p class="error-note" role="alert">${session.persistenceError}</p>` : ''}
    </div>
    <div class="home-art" aria-label="Yumi pronta para a aventura">
      <span class="floating-fruit one" aria-hidden="true">🫐</span><span class="floating-fruit two" aria-hidden="true">🌿</span><span class="floating-fruit three" aria-hidden="true">🥭</span>
      ${mascot()}
    </div>
  </section>`;
}

function renderLevels() {
  const levels = Array.from({ length: 24 }, (_, index) => index + 1);
  return `<section aria-labelledby="levels-title">
    <div class="screen-heading"><button class="back-button" data-action="home" aria-label="Voltar ao início" data-focus-key="back">‹</button><h1 id="levels-title">Sua jornada</h1></div>
    <p class="screen-subtitle">Cada parada revela um sabor ou paisagem do Pará.</p>
    <div class="level-grid" aria-label="Fases disponíveis">
      ${levels.map((number) => {
        const unlocked = number <= session.progress.unlockedLevel;
        const completed = session.progress.completedLevels.includes(number);
        const state = completed ? 'completada' : unlocked ? 'disponível' : 'bloqueada';
        const level = generateLevel(number);
        return `<button class="level-card ${unlocked ? 'unlocked' : 'locked'} ${completed ? 'completed' : ''}" data-action="start-level" data-level="${number}" data-focus-key="level-${number}" ${unlocked ? '' : 'disabled'} aria-label="Fase ${number}, ${state}, ${level.region}, objetivo: ${goalLabel(level.goal)}">
          <span class="level-number">${completed ? '✦' : unlocked ? number : '🔒'}</span><span class="level-meta">${completed ? 'CONCLUÍDA' : unlocked ? 'FASE' : 'BLOQUEADA'}</span>
        </button>`;
      }).join('')}
    </div>
  </section>`;
}

function renderSettings() {
  const items = [
    ['soundEnabled', 'Efeitos sonoros', 'Sons sutis ao combinar ingredientes'],
    ['hapticsEnabled', 'Vibração', 'Feedback tátil em dispositivos compatíveis'],
    ['prefersReducedMotion', 'Reduzir movimento', 'Animações mais discretas'],
  ];
  return `<section aria-labelledby="settings-title">
    <div class="screen-heading"><button class="back-button" data-action="back" aria-label="Voltar" data-focus-key="back">‹</button><h1 id="settings-title">Configurações</h1></div>
    <div class="settings-panel" role="group" aria-label="Preferências do jogo">
      ${items.map(([key, title, detail]) => `<div class="toggle-row"><span class="toggle-copy"><strong>${title}</strong><small>${detail}</small></span><button class="switch" role="switch" aria-checked="${session.progress[key]}" aria-label="${title}" data-action="toggle-preference" data-preference="${key}" data-focus-key="switch-${key}"></button></div>`).join('')}
      <div class="toggle-row"><span class="toggle-copy"><strong>Jogar sem conexão</strong><small>Instale o jogo para abrir pela tela inicial.</small></span><button class="secondary-button" data-action="install" data-focus-key="install">Instalar</button></div>
    </div>
    <p class="screen-subtitle" style="margin:18px 0 0">Sem conta, anúncios ou conexão obrigatória. Seu progresso fica neste navegador.</p>
    ${session.persistenceError ? `<p class="error-note" role="alert">${session.persistenceError}</p>` : ''}
  </section>`;
}

function renderGame() {
  const { current, target } = session.goalProgress();
  const level = session.level;
  const boardCells = session.board.map((row, rowIndex) => row.map((piece, columnIndex) => {
    const item = ingredient(piece.ingredient);
    const special = piece.special ? SPECIALS[piece.special] : null;
    const isSelected = selected && selected.row === rowIndex && selected.column === columnIndex;
    const label = `${item.name}${special ? `, especial ${special.name}: ${special.description}` : ''}`;
    return `<button type="button" class="piece-cell ${isSelected ? 'selected' : ''}" data-action="cell" data-row="${rowIndex}" data-column="${columnIndex}" data-ingredient="${item.id}" data-testid="cell-${rowIndex}-${columnIndex}" aria-label="Linha ${rowIndex + 1}, coluna ${columnIndex + 1}: ${label}" aria-pressed="${Boolean(isSelected)}" ${paused || session.result ? 'disabled' : ''} data-focus-key="cell-${rowIndex}-${columnIndex}">
      <span class="fruit" aria-hidden="true">${item.symbol}</span>${special ? `<span class="special-mark" aria-hidden="true">${special.symbol}</span>` : ''}
    </button>`;
  }).join('')).join('');

  const overlay = session.result ? renderResultOverlay() : paused ? renderPauseOverlay() : '';
  return `<section class="game-screen" aria-labelledby="game-title">
    <div class="game-top">
      <button class="back-button" data-action="levels" aria-label="Sair da partida" data-focus-key="game-back">‹</button>
      <div class="game-title"><p class="eyebrow">Fase ${level.number} · ${level.region}</p><h1 id="game-title">${goalLabel(level.goal)}</h1></div>
      <button class="icon-button" data-action="pause" aria-label="${paused ? 'Continuar' : 'Pausar'} partida" data-focus-key="pause">${paused ? '▶' : 'Ⅱ'}</button>
    </div>
    <div class="game-stats" aria-label="Estado da partida">
      <div class="stat-card"><span class="stat-label">Objetivo</span><span class="stat-value" data-testid="goal-progress">${current} / ${target}</span><span class="stat-detail">${goalLabel(level.goal)}</span></div>
      <div class="stat-card"><span class="stat-label">Pontos</span><span class="stat-value" data-testid="score">${session.score}</span><span class="stat-detail">Recorde ${session.progress.bestScores[level.number] ?? 0}</span></div>
      <div class="stat-card"><span class="stat-label">Jogadas</span><span class="stat-value" data-testid="moves">${session.moves}</span><span class="stat-detail">Restantes</span></div>
    </div>
    <div class="board-wrap" data-testid="board-wrap">
      <div class="game-board" role="grid" aria-label="Tabuleiro Match-3, oito linhas e oito colunas" data-testid="game-board">${boardCells}</div>
      ${overlay}
    </div>
    <p class="sr-only" id="game-announcer" role="status" aria-live="polite" aria-atomic="true">${session.result ? session.result === 'victory' ? 'Fase concluída!' : 'Fim de jogo.' : `Objetivo: ${current} de ${target}. ${session.moves} jogadas restantes.`}</p>
    <div class="game-hint">${mascot()}<span><strong>${session.moves < 5 ? 'Você consegue!' : 'Vamos nessa!'}</strong><br>Toque em duas peças próximas ou arraste uma para trocar.</span></div>
    ${session.persistenceError ? `<p class="error-note" role="alert">${session.persistenceError}</p>` : ''}
  </section>`;
}

function renderPauseOverlay() {
  return `<div class="pause-overlay" role="dialog" aria-modal="true" aria-labelledby="pause-title"><div class="overlay-card">
    ${mascot('overlay-mascot')}<h2 id="pause-title">Pausa</h2><p>Respire um pouco. Sua aventura continua quando você voltar.</p>
    <div class="overlay-actions"><button class="primary-button" data-action="resume" data-focus-key="resume">Continuar</button><button class="secondary-button" data-action="levels">Voltar às fases</button></div>
  </div></div>`;
}

function renderResultOverlay() {
  const victory = session.result === 'victory';
  return `<div class="result-overlay" role="dialog" aria-modal="true" aria-labelledby="result-title"><div class="overlay-card">
    ${mascot('overlay-mascot')}<h2 id="result-title">${victory ? 'Parabéns!' : 'Quase lá!'}</h2>
    <p>${victory ? 'Uma nova parada paraense espera por você.' : 'Toda aventura fica melhor na próxima tentativa.'}</p><strong>${session.score} pontos</strong>
    <div class="overlay-actions"><button class="primary-button" data-action="${victory ? 'next-level' : 'retry'}" data-focus-key="result-primary">${victory ? 'Próxima fase →' : 'Tentar de novo ↻'}</button><button class="secondary-button" data-action="home">Início</button></div>
  </div></div>`;
}

function showNotice(message) {
  document.querySelector('.notice')?.remove();
  const notice = document.createElement('div');
  notice.className = 'notice';
  notice.setAttribute('role', 'status');
  notice.textContent = message;
  document.body.append(notice);
  clearTimeout(noticeTimer);
  noticeTimer = setTimeout(() => notice.remove(), 2600);
}

function playFeedback(kind) {
  if (session.progress.soundEnabled) {
    try {
      audioContext ??= new AudioContext();
      const notes = kind === 'victory' ? [523, 659, 784] : kind === 'special' ? [392, 587] : [440];
      notes.forEach((frequency, index) => {
        const oscillator = audioContext.createOscillator();
        const gain = audioContext.createGain();
        const start = audioContext.currentTime + index * .08;
        oscillator.type = 'sine';
        oscillator.frequency.value = frequency;
        gain.gain.setValueAtTime(.0001, start);
        gain.gain.exponentialRampToValueAtTime(.055, start + .018);
        gain.gain.exponentialRampToValueAtTime(.0001, start + .18);
        oscillator.connect(gain).connect(audioContext.destination);
        oscillator.start(start);
        oscillator.stop(start + .2);
      });
    } catch { /* Audio may be unavailable or blocked by the browser. */ }
  }
  if (session.progress.hapticsEnabled && kind !== 'victory') navigator.vibrate?.(kind === 'special' ? [18, 24, 18] : 18);
}

function playMove(first, second) {
  const success = session.play(first, second);
  selected = null;
  if (success) {
    playFeedback(session.result === 'victory' ? 'victory' : session.lastTriggeredSpecial ? 'special' : 'match');
    render();
  } else {
    render();
    showNotice('Essa troca não forma uma combinação. Tente outra peça.');
  }
}

document.addEventListener('click', (event) => {
  const button = event.target.closest('[data-action]');
  if (!button) return;
  const action = button.dataset.action;
  if (action === 'cell') {
    if (suppressNextClick) { suppressNextClick = false; return; }
    const position = { row: Number(button.dataset.row), column: Number(button.dataset.column) };
    if (!selected) selected = position;
    else if (selected.row === position.row && selected.column === position.column) selected = null;
    else if (Math.abs(selected.row - position.row) + Math.abs(selected.column - position.column) === 1) playMove(selected, position);
    else selected = position;
    render();
    return;
  }
  if (action === 'home') { screen = 'home'; selected = null; paused = false; }
  else if (action === 'levels') { screen = 'levels'; selected = null; paused = false; }
  else if (action === 'settings') screen = 'settings';
  else if (action === 'back') screen = 'home';
  else if (action === 'start-level') {
    const number = Number(button.dataset.level);
    if (number <= session.progress.unlockedLevel) { session.start(number); screen = 'game'; selected = null; paused = false; }
  } else if (action === 'pause') paused = !paused;
  else if (action === 'resume') paused = false;
  else if (action === 'next-level') { session.start(session.progress.unlockedLevel); screen = 'game'; }
  else if (action === 'retry') { session.start(session.level.number); screen = 'game'; }
  else if (action === 'toggle-preference') {
    const preference = button.dataset.preference;
    session.togglePreference(preference);
    render();
    if (session.persistenceError) showNotice(session.persistenceError);
    return;
  }
  else if (action === 'install') { installPWA(); return; }
  render();
  if (session.persistenceError) showNotice(session.persistenceError);
});

app.addEventListener('pointerdown', (event) => {
  const cell = event.target.closest('[data-action="cell"]');
  if (!cell || !app.contains(cell)) return;
  dragStart = { position: { row: Number(cell.dataset.row), column: Number(cell.dataset.column) }, x: event.clientX, y: event.clientY, pointerId: event.pointerId };
});

app.addEventListener('pointerup', (event) => {
  if (!dragStart || dragStart.pointerId !== event.pointerId) return;
  const start = dragStart;
  dragStart = null;
  const dx = event.clientX - start.x;
  const dy = event.clientY - start.y;
  if (Math.hypot(dx, dy) < 16) return;
  const rowDelta = Math.abs(dx) > Math.abs(dy) ? 0 : dy < 0 ? -1 : 1;
  const columnDelta = Math.abs(dx) > Math.abs(dy) ? dx < 0 ? -1 : 1 : 0;
  const target = { row: start.position.row + rowDelta, column: start.position.column + columnDelta };
  if (target.row < 0 || target.row >= 8 || target.column < 0 || target.column >= 8) return;
  suppressNextClick = true;
  setTimeout(() => { suppressNextClick = false; }, 300);
  playMove(start.position, target);
});

app.addEventListener('pointercancel', () => { dragStart = null; });

async function installPWA() {
  if (!deferredInstallPrompt) {
    showNotice('No navegador compatível, use “Instalar aplicativo” ou “Adicionar à tela inicial” no menu do navegador.');
    return;
  }
  await deferredInstallPrompt.prompt();
  deferredInstallPrompt = null;
}

render();
if ('serviceWorker' in navigator && (location.protocol === 'https:' || location.hostname === 'localhost')) {
  navigator.serviceWorker.register(new URL('../sw.js', import.meta.url), { scope: './' }).catch(() => {});
}

