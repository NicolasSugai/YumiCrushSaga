import test from 'node:test';
import assert from 'node:assert/strict';
import { INGREDIENTS } from '../../Web/src/catalog.js';
import { Match3Engine } from '../../Web/src/engine.js';
import { generateLevel } from '../../Web/src/levels.js';
import { GameSession } from '../../Web/src/session.js';
import { defaultProgress, isValidProgress, LocalProgressStore } from '../../Web/src/storage.js';

class MemoryStorage {
  values = new Map();
  getItem(key) { return this.values.get(key) ?? null; }
  setItem(key, value) { this.values.set(key, value); }
}

class MemoryProgressStore {
  saved = null;
  load() { return this.saved; }
  save(progress) { this.saved = structuredClone(progress); }
}

function firstMove(board) {
  for (let row = 0; row < 8; row += 1) for (let column = 0; column < 8; column += 1) {
    for (const second of [{ row, column: column + 1 }, { row: row + 1, column }]) {
      if (second.row >= 8 || second.column >= 8) continue;
      if (new Match3Engine(15).resolveSwap({ row, column }, second, board)) return [{ row, column }, second];
    }
  }
  return null;
}

test('generated levels preserve the native progression rules and collection palette', () => {
  for (let number = 1; number <= 200; number += 1) {
    const level = generateLevel(number);
    assert.ok(level.moves >= 12 && level.moves <= 25);
    assert.ok(level.ingredientCount >= 3 && level.ingredientCount <= 8);
    if (level.goal.type === 'collect') {
      assert.ok(level.goal.target >= 8 && level.goal.target <= 15);
      assert.ok(level.ingredientCount >= INGREDIENTS.findIndex((item) => item.id === level.goal.ingredient) + 1);
      assert.ok(level.goal.target <= Math.max(8, Math.floor((level.moves * 4) / level.ingredientCount)));
    }
    if (level.goal.type === 'specials') assert.ok(level.goal.target === 1 || level.goal.target === 2);
  }
  assert.deepEqual(generateLevel(5).goal, { type: 'specials', target: 1 });
  assert.equal(generateLevel(1).goal.target, 900);
});

test('a valid move advances the board, updates score and consumes exactly one move', () => {
  const session = new GameSession({ store: new MemoryProgressStore(), seed: 42 });
  const move = firstMove(session.board);
  assert.ok(move);
  const beforeMoves = session.moves;
  const beforeScore = session.score;
  assert.equal(session.play(...move), true);
  assert.equal(session.moves, beforeMoves - 1);
  assert.ok(session.score > beforeScore);
  assert.equal(session.result, null);
});

test('a winning move unlocks the next level and later moves are ignored', () => {
  const store = new MemoryProgressStore();
  const session = new GameSession({ store, seed: 42 });
  session.level = { ...session.level, goal: { type: 'score', target: 1 } };
  const move = firstMove(session.board);
  assert.ok(move);
  assert.equal(session.play(...move), true);
  assert.equal(session.result, 'victory');
  assert.equal(session.progress.unlockedLevel, 2);
  assert.ok(session.progress.completedLevels.includes(1));
  const endBoard = structuredClone(session.board);
  const endMoves = session.moves;
  assert.equal(session.play(...move), false);
  assert.deepEqual(session.board, endBoard);
  assert.equal(session.moves, endMoves);

  const restored = new GameSession({ store, seed: 7 });
  assert.equal(restored.progress.unlockedLevel, 2);
  assert.equal(restored.level.number, 2);
});

test('using the last move without reaching the goal ends in defeat', () => {
  const session = new GameSession({ store: new MemoryProgressStore(), seed: 77 });
  session.level = { ...session.level, goal: { type: 'score', target: 999_999 } };
  session.moves = 1;
  const move = firstMove(session.board);
  assert.ok(move);
  assert.equal(session.play(...move), true);
  assert.equal(session.moves, 0);
  assert.equal(session.result, 'defeat');
});

test('invalid moves do not spend a turn, and settings survive a new session', () => {
  const store = new MemoryProgressStore();
  const session = new GameSession({ store, seed: 108 });
  const before = session.moves;
  let invalid = null;
  for (let row = 0; row < 8 && !invalid; row += 1) for (let column = 0; column < 8 && !invalid; column += 1) {
    for (const second of [{ row, column: column + 1 }, { row: row + 1, column }]) {
      if (second.row < 8 && second.column < 8 && !new Match3Engine(15).resolveSwap({ row, column }, second, session.board)) { invalid = [{ row, column }, second]; break; }
    }
  }
  assert.ok(invalid);
  assert.equal(session.play(...invalid), false);
  assert.equal(session.moves, before);
  session.togglePreference('soundEnabled');
  const restored = new GameSession({ store, seed: 4 });
  assert.equal(restored.progress.soundEnabled, false);
});

test('versioned local storage round trips and refuses to overwrite corrupt data', () => {
  const storage = new MemoryStorage();
  const store = new LocalProgressStore(storage);
  const progress = defaultProgress();
  progress.unlockedLevel = 8;
  progress.completedLevels = [1, 2, 7];
  progress.bestScores[7] = 2800;
  progress.prefersReducedMotion = true;
  store.save(progress);
  assert.deepEqual(store.load(), progress);
  assert.equal(isValidProgress(progress), true);

  storage.setItem(store.key, '{broken');
  assert.equal(store.load(), null);
  assert.throws(() => store.save(defaultProgress()), /corrupt/i);
  assert.equal(storage.getItem(store.key), '{broken');
});
