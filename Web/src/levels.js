import { INGREDIENTS, REGIONS } from './catalog.js';

// Kept in parity with Domain/Entities/LevelConfiguration.swift.
export function generateLevel(number) {
  const level = Math.max(1, Math.trunc(number));
  const targetIndex = (level - 1) % INGREDIENTS.length;
  const moves = Math.max(12, 25 - Math.floor((level - 1) / 3));
  const ingredientCount = Math.max(Math.min(6, 5 + Math.floor(level / 8)), targetIndex + 1);
  const region = REGIONS[Math.floor((level - 1) / 2) % REGIONS.length];

  let goal;
  if (level % 5 === 0) {
    goal = { type: 'specials', target: 1 + Math.min(Math.floor(level / 15), 1) };
  } else if (level % 2 === 0) {
    const difficultyTarget = 10 + Math.min(Math.floor((level - 1) / 4), 5);
    const boardCapacityTarget = Math.max(8, Math.floor((moves * 4) / ingredientCount));
    goal = {
      type: 'collect',
      ingredient: INGREDIENTS[targetIndex].id,
      target: Math.min(difficultyTarget, boardCapacityTarget),
    };
  } else {
    goal = { type: 'score', target: 900 + Math.min(level - 1, 6) * 150 };
  }

  return Object.freeze({ number: level, moves, goal: Object.freeze(goal), ingredientCount, region });
}
