import { Match3Engine } from './engine.js';
import { generateLevel } from './levels.js';
import { defaultProgress } from './storage.js';

export class GameSession {
  constructor({ store, seed = randomSeed() }) {
    this.store = store;
    this.progress = store.load() ?? defaultProgress();
    this.level = generateLevel(this.progress.unlockedLevel);
    this.engine = new Match3Engine(seed);
    this.board = this.engine.makeBoard(8, this.level.ingredientCount);
    this.score = 0;
    this.moves = this.level.moves;
    this.collected = Object.create(null);
    this.specialsCreated = 0;
    this.lastTriggeredSpecial = false;
    this.result = null;
    this.persistenceError = null;
  }

  start(levelNumber = this.progress.unlockedLevel, seed = randomSeed()) {
    this.level = generateLevel(levelNumber);
    this.engine = new Match3Engine(seed);
    this.board = this.engine.makeBoard(8, this.level.ingredientCount);
    this.score = 0;
    this.moves = this.level.moves;
    this.collected = Object.create(null);
    this.specialsCreated = 0;
    this.lastTriggeredSpecial = false;
    this.result = null;
  }

  play(first, second) {
    if (this.result) return false;
    const resolution = this.engine.resolveSwap(first, second, this.board);
    if (!resolution) return false;
    this.board = resolution.board;
    this.lastTriggeredSpecial = resolution.specialsTriggered;
    this.score += resolution.scoreEarned;
    this.moves -= 1;
    for (const [ingredient, count] of Object.entries(resolution.collected)) {
      this.collected[ingredient] = (this.collected[ingredient] ?? 0) + count;
    }
    this.specialsCreated += resolution.specialsCreated.length;
    this.checkResult();
    return true;
  }

  checkResult() {
    const goal = this.level.goal;
    const achieved = goal.type === 'score' ? this.score >= goal.target
      : goal.type === 'collect' ? (this.collected[goal.ingredient] ?? 0) >= goal.target
        : this.specialsCreated >= goal.target;
    if (achieved) {
      this.result = 'victory';
      this.progress.completedLevels = Array.from(new Set([...this.progress.completedLevels, this.level.number])).sort((a, b) => a - b);
      this.progress.bestScores[this.level.number] = Math.max(this.progress.bestScores[this.level.number] ?? 0, this.score);
      this.progress.unlockedLevel = Math.max(this.progress.unlockedLevel, this.level.number + 1);
      this.persist();
    } else if (this.moves <= 0) {
      this.result = 'defeat';
      this.progress.bestScores[this.level.number] = Math.max(this.progress.bestScores[this.level.number] ?? 0, this.score);
      this.persist();
    }
  }

  goalProgress() {
    const goal = this.level.goal;
    const current = goal.type === 'score' ? this.score
      : goal.type === 'collect' ? (this.collected[goal.ingredient] ?? 0)
        : this.specialsCreated;
    return { current: Math.min(current, goal.target), target: goal.target };
  }

  togglePreference(key) {
    const allowed = ['soundEnabled', 'musicEnabled', 'hapticsEnabled', 'prefersReducedMotion'];
    if (!allowed.includes(key)) throw new TypeError(`Unknown preference: ${key}`);
    this.progress[key] = !this.progress[key];
    this.persist();
  }

  persist() {
    try {
      this.store.save(this.progress);
      this.persistenceError = null;
    } catch {
      this.persistenceError = 'Seu progresso não pôde ser salvo neste navegador.';
    }
  }
}

function randomSeed() {
  if (globalThis.crypto?.getRandomValues) {
    const values = new Uint32Array(2);
    globalThis.crypto.getRandomValues(values);
    return (BigInt(values[0]) << 32n) | BigInt(values[1]);
  }
  return BigInt(Date.now());
}
