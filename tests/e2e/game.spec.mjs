import { expect, test } from '@playwright/test';

async function openLevelOne(page) {
  await page.goto('/');
  await expect(page.getByRole('heading', { name: /Sabores, rios/ })).toBeVisible();
  await page.getByRole('button', { name: 'Jogar' }).click();
  await page.getByRole('button', { name: /Fase 1,/ }).click();
  await expect(page.getByTestId('game-board')).toBeVisible();
}

async function findMove(page, shouldMatch) {
  return page.evaluate((shouldMatch) => {
    const cells = Array.from(document.querySelectorAll('[data-testid^="cell-"]'));
    const board = Array.from({ length: 8 }, (_, row) => Array.from({ length: 8 }, (_, column) => cells[row * 8 + column].dataset.ingredient));
    const matches = (grid) => {
      for (let row = 0; row < 8; row += 1) for (let column = 0; column < 6; column += 1) {
        if (grid[row][column] === grid[row][column + 1] && grid[row][column] === grid[row][column + 2]) return true;
      }
      for (let column = 0; column < 8; column += 1) for (let row = 0; row < 6; row += 1) {
        if (grid[row][column] === grid[row + 1][column] && grid[row][column] === grid[row + 2][column]) return true;
      }
      return false;
    };
    for (let row = 0; row < 8; row += 1) for (let column = 0; column < 8; column += 1) {
      for (const [nextRow, nextColumn] of [[row, column + 1], [row + 1, column]]) {
        if (nextRow >= 8 || nextColumn >= 8) continue;
        const copy = board.map((line) => line.slice());
        [copy[row][column], copy[nextRow][nextColumn]] = [copy[nextRow][nextColumn], copy[row][column]];
        if (matches(copy) === shouldMatch) return [[row, column], [nextRow, nextColumn]];
      }
    }
    return null;
  }, shouldMatch);
}

async function activateCells(page, move, testInfo) {
  for (const [row, column] of move) {
    const cell = page.getByTestId(`cell-${row}-${column}`);
    if (testInfo.project.name.startsWith('mobile')) await cell.tap();
    else await cell.click();
  }
}

test('home, fase map and a real board move work with the current input mode', async ({ page }, testInfo) => {
  await openLevelOne(page);
  expect(await page.evaluate(() => document.documentElement.scrollWidth <= window.innerWidth)).toBe(true);
  await page.screenshot({ path: testInfo.outputPath('gameplay-board.png'), fullPage: true });
  await expect(page.getByRole('grid', { name: /Tabuleiro Match-3/ })).toBeVisible();
  await expect(page.getByTestId('game-board').getByRole('button')).toHaveCount(64);

  const move = await findMove(page, true);
  expect(move).not.toBeNull();
  const previousMoves = Number(await page.getByTestId('moves').innerText());
  await activateCells(page, move, testInfo);
  await expect(page.getByTestId('moves')).toHaveText(String(previousMoves - 1));
  await expect.poll(async () => Number(await page.getByTestId('score').innerText())).toBeGreaterThan(0);
});

test('dragging an adjacent piece resolves a legal move', async ({ page }) => {
  await openLevelOne(page);
  const move = await findMove(page, true);
  expect(move).not.toBeNull();
  const boxes = await Promise.all(move.map(([row, column]) => page.getByTestId(`cell-${row}-${column}`).boundingBox()));
  const previousMoves = Number(await page.getByTestId('moves').innerText());
  await page.mouse.move(boxes[0].x + boxes[0].width / 2, boxes[0].y + boxes[0].height / 2);
  await page.mouse.down();
  await page.mouse.move(boxes[1].x + boxes[1].width / 2, boxes[1].y + boxes[1].height / 2, { steps: 5 });
  await page.mouse.up();
  await expect(page.getByTestId('moves')).toHaveText(String(previousMoves - 1));
  await expect.poll(async () => Number(await page.getByTestId('score').innerText())).toBeGreaterThan(0);
});

test('pause locks the board and resume restores play', async ({ page }) => {
  await openLevelOne(page);
  await page.getByRole('button', { name: 'Pausar partida' }).click();
  await expect(page.getByRole('heading', { name: 'Pausa' })).toBeVisible();
  await expect(page.getByTestId('game-board').getByRole('button').first()).toBeDisabled();
  await page.getByRole('button', { name: 'Continuar', exact: true }).click();
  await expect(page.getByTestId('game-board').getByRole('button').first()).toBeEnabled();
});

test('a non-matching swap leaves score and move count unchanged', async ({ page }, testInfo) => {
  await openLevelOne(page);
  const move = await findMove(page, false);
  expect(move).not.toBeNull();
  const previousMoves = await page.getByTestId('moves').innerText();
  const previousScore = await page.getByTestId('score').innerText();
  await activateCells(page, move, testInfo);
  await expect(page.getByTestId('moves')).toHaveText(previousMoves);
  await expect(page.getByTestId('score')).toHaveText(previousScore);
  await expect(page.getByRole('status').filter({ hasText: 'não forma uma combinação' })).toBeVisible();
});

test('preferences persist after reloading the page', async ({ page }) => {
  await page.goto('/');
  await page.getByRole('button', { name: 'Abrir configurações' }).click();
  const soundSwitch = page.getByRole('switch', { name: 'Efeitos sonoros' });
  const initial = await soundSwitch.getAttribute('aria-checked');
  await soundSwitch.click();
  await expect(soundSwitch).toHaveAttribute('aria-checked', initial === 'true' ? 'false' : 'true');
  await page.reload();
  await page.getByRole('button', { name: 'Abrir configurações' }).click();
  await expect(page.getByRole('switch', { name: 'Efeitos sonoros' })).toHaveAttribute('aria-checked', initial === 'true' ? 'false' : 'true');
});

test('the service worker caches the game for an offline reload', async ({ page, context }) => {
  await page.goto('/');
  await page.waitForFunction(async () =>
    'serviceWorker' in navigator
      && (await navigator.serviceWorker.getRegistrations()).some((registration) => registration.active),
  );
  await page.evaluate(async () => {
    await navigator.serviceWorker.register('/sw.js', { scope: '/' });
    await navigator.serviceWorker.ready;
  });
  await context.setOffline(true);
  await page.reload();
  await expect(page.getByRole('heading', { name: /Sabores, rios/ })).toBeVisible();
});
