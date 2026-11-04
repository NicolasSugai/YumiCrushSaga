export const PROGRESS_KEY = 'yumicrushsaga.progress.v1';
export const PROGRESS_SCHEMA_VERSION = 1;

export function defaultProgress() {
  return {
    schemaVersion: PROGRESS_SCHEMA_VERSION,
    unlockedLevel: 1,
    completedLevels: [],
    bestScores: {},
    soundEnabled: true,
    musicEnabled: true,
    hapticsEnabled: true,
    prefersReducedMotion: false,
  };
}

export function isValidProgress(progress) {
  return Boolean(progress)
    && progress.schemaVersion === PROGRESS_SCHEMA_VERSION
    && Number.isInteger(progress.unlockedLevel) && progress.unlockedLevel >= 1
    && Array.isArray(progress.completedLevels) && progress.completedLevels.every((level) => Number.isInteger(level) && level > 0)
    && progress.bestScores && typeof progress.bestScores === 'object' && !Array.isArray(progress.bestScores)
    && Object.entries(progress.bestScores).every(([level, score]) => Number.isInteger(Number(level)) && Number(level) > 0 && Number.isInteger(score) && score >= 0)
    && ['soundEnabled', 'musicEnabled', 'hapticsEnabled', 'prefersReducedMotion'].every((key) => typeof progress[key] === 'boolean');
}

export class LocalProgressStore {
  constructor(storage = globalThis.localStorage, key = PROGRESS_KEY) {
    this.storage = storage;
    this.key = key;
  }

  load() {
    const data = this.storage.getItem(this.key);
    if (data === null) return null;
    try {
      const progress = JSON.parse(data);
      return isValidProgress(progress) ? progress : null;
    } catch {
      return null;
    }
  }

  save(progress) {
    if (!isValidProgress(progress)) throw new TypeError('Invalid progress data');
    const existingData = this.storage.getItem(this.key);
    if (existingData !== null) {
      let existing;
      try { existing = JSON.parse(existingData); } catch { throw new Error('Existing progress is corrupt; it was preserved'); }
      if (!isValidProgress(existing)) throw new Error('Existing progress is incompatible; it was preserved');
    }
    this.storage.setItem(this.key, JSON.stringify(progress));
  }
}
