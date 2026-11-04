import test from 'node:test';
import assert from 'node:assert/strict';
import { INGREDIENTS } from '../../Web/src/catalog.js';
import { Match3Engine, MAX_CASCADES, cloneBoard } from '../../Web/src/engine.js';

const emptyBoard = () => Array.from({ length: 8 }, () => Array(8).fill(null));
const piece = (ingredient, special = null) => ({ ingredient, special });

function fillPattern(board, palette = INGREDIENTS.length) {
  for (let row = 0; row < 8; row += 1) {
    for (let column = 0; column < 8; column += 1) board[row][column] = piece((row + column) % palette);
  }
}

function firstMove(board, engine = new Match3Engine(4)) {
  for (let row = 0; row < board.length; row += 1) {
    for (let column = 0; column < board[0].length; column += 1) {
      for (const second of [{ row, column: column + 1 }, { row: row + 1, column }]) {
        if (second.row >= board.length || second.column >= board[0].length) continue;
        const candidate = new Match3Engine(51);
        if (candidate.resolveSwap({ row, column }, second, board)) return [{ row, column }, second];
      }
    }
  }
  return null;
}

function ingredientCounts(board) {
  return board.flat().filter(Boolean).reduce((counts, item) => {
    counts[item.ingredient] = (counts[item.ingredient] ?? 0) + 1;
    return counts;
  }, {});
}

test('a seed reproduces the same complete, match-free, playable board', () => {
  const firstEngine = new Match3Engine(42);
  const secondEngine = new Match3Engine(42);
  const first = firstEngine.makeBoard();
  const second = secondEngine.makeBoard();
  assert.deepEqual(first, second);
  assert.equal(first.flat().filter(Boolean).length, 64);
  assert.equal(firstEngine.matches(first).size, 0);
  assert.equal(firstEngine.hasLegalMove(first), true);
});

test('100 generated seeds have full boards without starting matches or deadlocks', () => {
  for (let seed = 0; seed < 100; seed += 1) {
    const engine = new Match3Engine(seed);
    const board = engine.makeBoard();
    assert.equal(board.flat().filter(Boolean).length, 64, `seed ${seed} left a hole`);
    assert.equal(engine.matches(board).size, 0, `seed ${seed} started with a match`);
    assert.equal(engine.hasLegalMove(board), true, `seed ${seed} started in a deadlock`);
  }
});

test('horizontal, vertical and crossing matches form a unique position set', () => {
  const board = emptyBoard();
  for (let column = 1; column <= 3; column += 1) board[2][column] = piece(0);
  for (let row = 1; row <= 3; row += 1) board[row][2] = piece(0);
  for (let row = 4; row <= 6; row += 1) board[row][6] = piece(3);
  assert.equal(new Match3Engine(1).matches(board).size, 8);
});

test('a four run creates a Correnteza and a five run creates an Uru-Uru', () => {
  const fourBoard = emptyBoard();
  fillPattern(fourBoard);
  fourBoard[1][0] = piece(0); fourBoard[1][1] = piece(0); fourBoard[1][2] = piece(3); fourBoard[1][3] = piece(0); fourBoard[0][2] = piece(0);
  const four = new Match3Engine(28).resolveSwap({ row: 0, column: 2 }, { row: 1, column: 2 }, fourBoard);
  assert.equal(four.specialsCreated[0], 'riverCurrent');

  const fiveBoard = emptyBoard();
  fillPattern(fiveBoard);
  for (const column of [0, 1, 3, 4]) fiveBoard[1][column] = piece(0);
  fiveBoard[1][2] = piece(3); fiveBoard[0][2] = piece(0);
  const five = new Match3Engine(31).resolveSwap({ row: 0, column: 2 }, { row: 1, column: 2 }, fiveBoard);
  assert.equal(five.specialsCreated[0], 'uruUru');
});

test('a T junction creates an Explosão da Floresta at the intersection', () => {
  const board = emptyBoard();
  fillPattern(board);
  board[2][2] = piece(0); board[2][3] = piece(0); board[2][4] = piece(3);
  board[1][4] = piece(0); board[3][4] = piece(0); board[2][5] = piece(0);
  const result = new Match3Engine(10).resolveSwap({ row: 2, column: 4 }, { row: 2, column: 5 }, board);
  assert.equal(result.specialsCreated[0], 'forestBurst');
});

test('each special clears its documented footprint when swapped', () => {
  const riverBoard = emptyBoard();
  fillPattern(riverBoard);
  riverBoard[3][2].special = 'riverCurrent';
  const river = new Match3Engine(250).resolveSwap({ row: 3, column: 2 }, { row: 3, column: 3 }, riverBoard);
  assert.equal(river.specialsTriggered, true);
  assert.ok(Object.values(river.collected).reduce((sum, count) => sum + count, 0) >= 8);

  const forestBoard = emptyBoard();
  fillPattern(forestBoard);
  forestBoard[3][3].special = 'forestBurst';
  const forest = new Match3Engine(251).resolveSwap({ row: 3, column: 3 }, { row: 3, column: 4 }, forestBoard);
  assert.equal(forest.specialsTriggered, true);
  assert.ok(Object.values(forest.collected).reduce((sum, count) => sum + count, 0) >= 9);

  const uruBoard = emptyBoard();
  fillPattern(uruBoard);
  uruBoard[0][0].special = 'uruUru';
  const acaiCount = ingredientCounts(uruBoard)[0];
  const uru = new Match3Engine(252).resolveSwap({ row: 0, column: 0 }, { row: 0, column: 1 }, uruBoard);
  assert.equal(uru.specialsTriggered, true);
  assert.ok(uru.collected[0] >= acaiCount);
});

test('invalid and non-adjacent swaps return no resolution and preserve the source board', () => {
  const board = emptyBoard();
  fillPattern(board);
  const original = cloneBoard(board);
  const engine = new Match3Engine(3);
  assert.equal(engine.resolveSwap({ row: 0, column: 0 }, { row: 0, column: 1 }, board), null);
  assert.equal(engine.resolveSwap({ row: 0, column: 0 }, { row: 0, column: 7 }, board), null);
  assert.deepEqual(board, original);
});

test('reshuffling a deadlock preserves each ingredient count', () => {
  const board = emptyBoard();
  fillPattern(board);
  const before = ingredientCounts(board);
  const engine = new Match3Engine(112);
  assert.equal(engine.hasLegalMove(board), false);
  assert.equal(engine.reshuffleIfNeeded(board), true);
  assert.equal(engine.matches(board).size, 0);
  assert.equal(engine.hasLegalMove(board), true);
  assert.deepEqual(ingredientCounts(board), before);
});

test('many resolved moves end with a stable full playable board within the cascade cap', () => {
  for (let seed = 0; seed < 100; seed += 1) {
    const engine = new Match3Engine(seed);
    const board = engine.makeBoard();
    const move = firstMove(board);
    assert.ok(move, `seed ${seed} should have a legal move`);
    const result = engine.resolveSwap(...move, board);
    assert.ok(result);
    assert.ok(result.cascades <= MAX_CASCADES);
    assert.equal(result.board.flat().filter(Boolean).length, 64);
    assert.equal(engine.matches(result.board).size, 0);
    assert.equal(engine.hasLegalMove(result.board), true);
    assert.ok(result.scoreEarned > 0);
  }
});
