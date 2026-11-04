export const INGREDIENTS = Object.freeze([
  { id: 'acai', name: 'Açaí', symbol: '🫐' },
  { id: 'cupuacu', name: 'Cupuaçu', symbol: '🥭' },
  { id: 'brazilNut', name: 'Castanha-do-Pará', symbol: '🌰' },
  { id: 'jambu', name: 'Jambu', symbol: '🌿' },
  { id: 'tucupi', name: 'Tucupi', symbol: '🫙' },
  { id: 'tapereba', name: 'Taperebá', symbol: '🍋' },
  { id: 'bacuri', name: 'Bacuri', symbol: '🍈' },
  { id: 'cassava', name: 'Mandioca', symbol: '🌱' },
]);

export const SPECIALS = Object.freeze({
  riverCurrent: { name: 'Correnteza', symbol: '↔', description: 'Limpa uma linha inteira' },
  forestBurst: { name: 'Explosão da Floresta', symbol: '✹', description: 'Limpa uma área 3×3' },
  uruUru: { name: 'Uru-Uru', symbol: '◉', description: 'Limpa todas as peças do mesmo ingrediente' },
});

export const REGIONS = Object.freeze(['Ver-o-Peso', 'Rio Guamá', 'Ilha do Combu', 'Floresta de Utinga']);
