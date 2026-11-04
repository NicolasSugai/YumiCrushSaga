import { INGREDIENTS } from './catalog.js';

const MASK_64 = (1n << 64n) - 1n;
const ZERO_SEED = 0x9E3779B97F4A7C15n;
const MULTIPLIER = 0x2545F4914F6CDD1Dn;

export const MAX_CASCADES = 32;

export class SeededRandom {
  constructor(seed) {
    this.state = BigInt.asUintN(64, BigInt(seed)) || ZERO_SEED;
  }

  nextInt(upperBound) {
    if (!Number.isInteger(upperBound) || upperBound <= 0) throw new RangeError('upperBound must be positive');
    let state = this.state;
    state ^= state >> 12n;
    state ^= BigInt.asUintN(64, state << 25n);
    state ^= state >> 27n;
    this.state = BigInt.asUintN(64, state);
    return Number(BigInt.asUintN(64, state * MULTIPLIER) % BigInt(upperBound));
  }
}

export const positionKey = ({ row, column }) => `${row}:${column}`;
export const parsePosition = (key) => {
  const [row, column] = key.split(':').map(Number);
  return { row, column };
};
export const isAdjacent = (a, b) => Math.abs(a.row - b.row) + Math.abs(a.column - b.column) === 1;

function comparePositions(a, b) {
  return a.row - b.row || a.column - b.column;
}

export class Match3Engine {
  constructor(seed = 1) {
    this.random = new SeededRandom(seed);
    this.ingredientCount = 5;
  }

  makeBoard(size = 8, ingredientCount = 5) {
    const count = Math.min(INGREDIENTS.length, Math.max(3, Math.trunc(ingredientCount)));
    this.ingredientCount = count;
    const board = Array.from({ length: size }, () => Array(size).fill(null));
    for (let row = 0; row < size; row += 1) {
      for (let column = 0; column < size; column += 1) {
        let options = Array.from({ length: count }, (_, index) => index);
        if (column >= 2) {
          const left = board[row][column - 1]?.ingredient;
          const left2 = board[row][column - 2]?.ingredient;
          if (left !== undefined && left === left2) options = options.filter((index) => index !== left);
        }
        if (row >= 2) {
          const above = board[row - 1][column]?.ingredient;
          const above2 = board[row - 2][column]?.ingredient;
          if (above !== undefined && above === above2) options = options.filter((index) => index !== above);
        }
        board[row][column] = { ingredient: options[this.random.nextInt(options.length)], special: null };
      }
    }
    this.reshuffleIfNeeded(board, count);
    return board;
  }

  matches(board) {
    const result = new Set();
    for (let row = 0; row < board.length; row += 1) {
      let start = 0;
      while (start < board[row].length) {
        const ingredient = board[row][start]?.ingredient;
        if (ingredient === undefined) { start += 1; continue; }
        let end = start + 1;
        while (end < board[row].length && board[row][end]?.ingredient === ingredient) end += 1;
        if (end - start >= 3) for (let column = start; column < end; column += 1) result.add(positionKey({ row, column }));
        start = end;
      }
    }
    const columns = board[0]?.length ?? 0;
    for (let column = 0; column < columns; column += 1) {
      let start = 0;
      while (start < board.length) {
        const ingredient = board[start][column]?.ingredient;
        if (ingredient === undefined) { start += 1; continue; }
        let end = start + 1;
        while (end < board.length && board[end][column]?.ingredient === ingredient) end += 1;
        if (end - start >= 3) for (let row = start; row < end; row += 1) result.add(positionKey({ row, column }));
        start = end;
      }
    }
    return result;
  }

  hasLegalMove(board) {
    if (this.matches(board).size > 0) return false;
    const rows = board.length;
    const columns = board[0]?.length ?? 0;
    for (let row = 0; row < rows; row += 1) {
      for (let column = 0; column < columns; column += 1) {
        const first = { row, column };
        for (const second of [{ row, column: column + 1 }, { row: row + 1, column }]) {
          if (second.row >= rows || second.column >= columns || !board[row][column] || !board[second.row][second.column]) continue;
          if (board[row][column].special || board[second.row][second.column].special) return true;
          const copy = cloneBoard(board);
          swapPieces(copy, first, second);
          if (this.matches(copy).size > 0) return true;
        }
      }
    }
    return false;
  }

  resolveSwap(first, second, source) {
    const rows = source.length;
    const columns = source[0]?.length ?? 0;
    if (!contains(first, rows, columns) || !contains(second, rows, columns) || !isAdjacent(first, second)
      || !source[first.row][first.column] || !source[second.row][second.column] || this.matches(source).size > 0) return null;

    const board = cloneBoard(source);
    swapPieces(board, first, second);
    let matched = this.matches(board);
    const specialSwap = Boolean(source[first.row][first.column]?.special || source[second.row][second.column]?.special);
    if (matched.size === 0 && !specialSwap) return null;

    const collected = Object.create(null);
    const specialsCreated = [];
    let scoreEarned = 0;
    let cascades = 0;
    let specialsTriggered = false;

    while ((matched.size > 0 || (specialSwap && cascades === 0)) && cascades < MAX_CASCADES) {
      cascades += 1;
      let removal = new Set(matched);
      if (specialSwap && cascades === 1) {
        removal.add(positionKey(first));
        removal.add(positionKey(second));
      }
      removal = this.expandSpecials(removal, board);
      const preferred = cascades === 1 ? [second, first] : [];
      const created = this.specialCreation(board, matched, preferred);
      if (created) {
        removal.delete(positionKey(created.position));
        board[created.position.row][created.position.column].special = created.kind;
        specialsCreated.push(created.kind);
      }

      let waveScore = 0;
      for (const key of Array.from(removal).sort((a, b) => comparePositions(parsePosition(a), parsePosition(b)))) {
        const position = parsePosition(key);
        const piece = board[position.row][position.column];
        if (!piece) continue;
        if (piece.special) specialsTriggered = true;
        collected[piece.ingredient] = (collected[piece.ingredient] ?? 0) + 1;
        waveScore += 60 + (piece.special ? 120 : 0);
        board[position.row][position.column] = null;
      }
      scoreEarned += waveScore * cascades;
      this.applyGravity(board);
      this.refill(board, this.ingredientCount);
      matched = this.matches(board);
    }

    const reshuffled = this.reshuffleIfNeeded(board, this.ingredientCount);
    return { board, scoreEarned, collected, cascades, reshuffled, specialsTriggered, specialsCreated };
  }

  reshuffleIfNeeded(board, ingredientCount = this.ingredientCount) {
    if (this.hasLegalMove(board) && this.matches(board).size === 0) return false;
    this.reshuffle(board, ingredientCount);
    return true;
  }

  matchGroups(board) {
    const groups = [];
    for (let row = 0; row < board.length; row += 1) {
      let start = 0;
      while (start < (board[row]?.length ?? 0)) {
        const ingredient = board[row][start]?.ingredient;
        if (ingredient === undefined) { start += 1; continue; }
        let end = start + 1;
        while (end < board[row].length && board[row][end]?.ingredient === ingredient) end += 1;
        if (end - start >= 3) groups.push(Array.from({ length: end - start }, (_, offset) => ({ row, column: start + offset })));
        start = end;
      }
    }
    const columns = board[0]?.length ?? 0;
    for (let column = 0; column < columns; column += 1) {
      let start = 0;
      while (start < board.length) {
        const ingredient = board[start][column]?.ingredient;
        if (ingredient === undefined) { start += 1; continue; }
        let end = start + 1;
        while (end < board.length && board[end][column]?.ingredient === ingredient) end += 1;
        if (end - start >= 3) groups.push(Array.from({ length: end - start }, (_, offset) => ({ row: start + offset, column })));
        start = end;
      }
    }
    return groups;
  }

  specialCreation(board, matches, preferred) {
    if (matches.size === 0) return null;
    const groups = this.matchGroups(board);
    let group = null;
    for (const candidate of groups) if (!group || candidate.length > group.length) group = candidate;
    if (!group || group.length < 4) return null;
    const junction = this.junctionPosition(board);
    const kind = junction ? 'forestBurst' : group.length >= 5 ? 'uruUru' : 'riverCurrent';
    const available = Array.from(matches).map(parsePosition).filter((position) => !board[position.row][position.column]?.special);
    if (available.length === 0) return null;
    if (junction && available.some((position) => samePosition(position, junction))) return { position: junction, kind };
    for (const position of preferred) if (available.some((candidate) => samePosition(candidate, position))) return { position, kind };
    const groupAvailable = group.filter((position) => available.some((candidate) => samePosition(candidate, position)));
    const ordered = (groupAvailable.length > 0 ? groupAvailable : available).sort(comparePositions);
    return { position: ordered[Math.floor(ordered.length / 2)], kind };
  }

  junctionPosition(board) {
    for (const key of Array.from(this.matches(board)).sort((a, b) => comparePositions(parsePosition(a), parsePosition(b)))) {
      const position = parsePosition(key);
      const ingredient = board[position.row][position.column]?.ingredient;
      if (ingredient === undefined) continue;
      let left = position.column;
      while (left > 0 && board[position.row][left - 1]?.ingredient === ingredient) left -= 1;
      let right = position.column;
      while (right + 1 < (board[0]?.length ?? 0) && board[position.row][right + 1]?.ingredient === ingredient) right += 1;
      let top = position.row;
      while (top > 0 && board[top - 1][position.column]?.ingredient === ingredient) top -= 1;
      let bottom = position.row;
      while (bottom + 1 < board.length && board[bottom + 1][position.column]?.ingredient === ingredient) bottom += 1;
      if (right - left + 1 >= 3 && bottom - top + 1 >= 3) return position;
    }
    return null;
  }

  expandSpecials(initial, board) {
    const result = new Set(initial);
    const queue = Array.from(initial).sort((a, b) => comparePositions(parsePosition(a), parsePosition(b)));
    while (queue.length > 0) {
      const key = queue.pop();
      const position = parsePosition(key);
      const kind = board[position.row][position.column]?.special;
      if (!kind) continue;
      const affected = new Set();
      if (kind === 'riverCurrent') {
        for (let column = 0; column < (board[0]?.length ?? 0); column += 1) affected.add(positionKey({ row: position.row, column }));
      } else if (kind === 'forestBurst') {
        for (let row = Math.max(0, position.row - 1); row <= Math.min(board.length - 1, position.row + 1); row += 1) {
          for (let column = Math.max(0, position.column - 1); column <= Math.min((board[0]?.length ?? 0) - 1, position.column + 1); column += 1) {
            affected.add(positionKey({ row, column }));
          }
        }
      } else if (kind === 'uruUru') {
        const ingredient = board[position.row][position.column]?.ingredient;
        for (let row = 0; row < board.length; row += 1) {
          for (let column = 0; column < (board[0]?.length ?? 0); column += 1) {
            if (board[row][column]?.ingredient === ingredient) affected.add(positionKey({ row, column }));
          }
        }
      }
      for (const affectedKey of affected) {
        if (result.has(affectedKey)) continue;
        result.add(affectedKey);
        const item = parsePosition(affectedKey);
        if (board[item.row][item.column]?.special) queue.push(affectedKey);
      }
    }
    return result;
  }

  applyGravity(board) {
    for (let column = 0; column < (board[0]?.length ?? 0); column += 1) {
      const survivors = [];
      for (let row = board.length - 1; row >= 0; row -= 1) if (board[row][column]) survivors.push(board[row][column]);
      for (let row = 0; row < board.length; row += 1) board[row][column] = null;
      survivors.forEach((piece, index) => { board[board.length - 1 - index][column] = piece; });
    }
  }

  refill(board, ingredientCount) {
    for (let row = 0; row < board.length; row += 1) {
      for (let column = 0; column < (board[0]?.length ?? 0); column += 1) {
        if (!board[row][column]) board[row][column] = { ingredient: this.random.nextInt(ingredientCount), special: null };
      }
    }
  }

  reshuffle(board, ingredientCount) {
    const rows = board.length;
    const columns = board[0]?.length ?? 0;
    const pieces = board.flat().filter(Boolean);
    if (pieces.length === rows * columns && pieces.length > 0) {
      for (let attempt = 0; attempt < 100; attempt += 1) {
        const shuffled = pieces.slice();
        for (let index = shuffled.length - 1; index > 0; index -= 1) {
          const other = this.random.nextInt(index + 1);
          [shuffled[index], shuffled[other]] = [shuffled[other], shuffled[index]];
        }
        const candidate = Array.from({ length: rows }, (_, row) => shuffled.slice(row * columns, (row + 1) * columns));
        if (this.matches(candidate).size === 0 && this.hasLegalMove(candidate)) {
          replaceBoard(board, candidate);
          return;
        }
      }
    }
    for (let attempt = 0; attempt < 100; attempt += 1) {
      const candidate = this.makeBoardWithoutReshuffle(rows, columns, ingredientCount);
      if (this.hasLegalMove(candidate) && this.matches(candidate).size === 0) {
        replaceBoard(board, candidate);
        return;
      }
    }
    replaceBoard(board, this.guaranteedPlayableBoard(rows, columns, ingredientCount));
  }

  makeBoardWithoutReshuffle(rows, columns, ingredientCount) {
    const choices = Array.from({ length: Math.max(3, Math.min(INGREDIENTS.length, ingredientCount)) }, (_, index) => index);
    const result = Array.from({ length: rows }, () => Array(columns).fill(null));
    for (let row = 0; row < rows; row += 1) {
      for (let column = 0; column < columns; column += 1) {
        let allowed = choices.slice();
        if (column >= 2 && result[row][column - 1]?.ingredient === result[row][column - 2]?.ingredient) {
          allowed = allowed.filter((index) => index !== result[row][column - 1].ingredient);
        }
        if (row >= 2 && result[row - 1][column]?.ingredient === result[row - 2][column]?.ingredient) {
          allowed = allowed.filter((index) => index !== result[row - 1][column].ingredient);
        }
        result[row][column] = { ingredient: allowed[this.random.nextInt(allowed.length)], special: null };
      }
    }
    return result;
  }

  guaranteedPlayableBoard(rows, columns, ingredientCount) {
    const count = Math.max(3, Math.min(INGREDIENTS.length, ingredientCount));
    const board = Array.from({ length: rows }, (_, row) => Array.from({ length: columns }, (_, column) => ({ ingredient: (row + column) % count, special: null })));
    if (rows > 1 && columns > 3) {
      board[0][0].ingredient = 0;
      board[0][1].ingredient = 0;
      board[0][2].ingredient = 1;
      board[0][3].ingredient = 0;
      board[1][2].ingredient = 0;
    }
    return board;
  }
}

export function cloneBoard(board) {
  return board.map((row) => row.map((piece) => piece ? { ...piece } : null));
}

function contains(position, rows, columns) {
  return Number.isInteger(position.row) && Number.isInteger(position.column)
    && position.row >= 0 && position.row < rows && position.column >= 0 && position.column < columns;
}

function samePosition(a, b) { return a.row === b.row && a.column === b.column; }

function swapPieces(board, first, second) {
  [board[first.row][first.column], board[second.row][second.column]] = [board[second.row][second.column], board[first.row][first.column]];
}

function replaceBoard(target, source) {
  target.splice(0, target.length, ...source.map((row) => row.slice()));
}
