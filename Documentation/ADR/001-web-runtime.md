# ADR 001: Web e PWA independentes para YumiCrushSaga

- Estado: aceito para a primeira versão Web.
- Data: 2026-11-04.

## Contexto

O aplicativo existente usa SwiftUI, SpriteKit e Swift Package Manager. SwiftUI e SpriteKit não executam em navegadores, e traduzir o aplicativo inteiro para WebAssembly não disponibilizaria essas APIs. As regras centrais estão em Swift e precisam manter comportamento compatível entre produtos.

## Decisão

Manter iOS e Web como produtos independentes. A Web usa módulos ECMAScript nativos, CSS e HTML sem framework de execução. `Web/src/engine.js`, `levels.js` e `session.js` portam o comportamento observável do motor e da configuração Swift atuais. Os testes JavaScript cobrem invariantes e os testes Swift seguem como autoridade de regressão para o produto nativo. A interface não importa ou modifica os módulos Swift.

O navegador hospeda progresso em `localStorage`, fornece os oito ingredientes regionais, três especiais, objetivos e progresso. A PWA usa um service worker com cache versionado, sem API externa ou backend. O build copia `Web/` para `dist/` e usa caminhos relativos para funcionar em `/YumiCrushSaga/` no GitHub Pages.

## Consequências

- As regras existem em Swift e JavaScript; fixtures e testes de paridade são necessários para evitar divergência.
- O código, UI, mascote vetorial original e assets do iOS permanecem separados.
- Não entram fotografias de `Design/References/` no bundle.
- Web Audio fornece efeitos sintetizados. A disponibilidade de áudio/haptics depende do navegador e dos gestos de interação.
- A execução local e a hospedagem são estáticas e podem funcionar offline após instalação e primeiro carregamento completo.
