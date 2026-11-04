# Versão Web e PWA

A versão Web é independente do app SwiftUI/SpriteKit e conserva a identidade regional do Pará. Não há cadastro, backend, telemetria ou dependência de API paga. A mascote incluída é um SVG original; fotografias em `Design/References/` não fazem parte do build.

## Requisitos e comandos

Requer Node.js 20+ e npm. Na raiz do repositório:

```sh
npm ci
npm test
npm run build
npm run serve
```

O build estático fica em `dist/`; `npm run serve` abre `http://127.0.0.1:4173`. Testes E2E desktop e toque precisam do Chromium do Playwright:

```sh
npx playwright install chromium
npm run test:e2e
```

## Jogar e salvar

Use dois cliques/toques em peças adjacentes ou arraste uma peça para a vizinha. O botão de pausa interrompe as interações. Progresso, melhores pontuações e preferências são armazenados no `localStorage` deste navegador; apagar os dados do site apaga esse salvamento. Sons são sintetizados com Web Audio; toque/haptic depende do suporte do navegador.

Em navegador compatível, use “Instalar aplicativo” ou “Adicionar à tela inicial”. O manifesto define a identidade PWA e o service worker mantém os arquivos estáticos em cache versionado. Depois de uma implantação, uma nova navegação atualiza a versão do shell. A primeira visita exige rede.

## GitHub Actions e Pages

`.github/workflows/web-ci.yml` executa testes e build. `.github/workflows/pages.yml` é manual e prepara/publica o conteúdo `dist/` no GitHub Pages quando alguém acionar deliberadamente o workflow. Estes arquivos são apenas locais nesta entrega: nenhum workflow foi enviado ou iniciado, Pages não foi habilitado na configuração remota e não houve deploy.

Para habilitar Pages, primeiro enviar uma branch/alteração autorizada contendo o workflow, depois abrir **Settings → Pages**, escolher **GitHub Actions** como fonte e executar `Publish Web to GitHub Pages` manualmente. O endereço esperado é `https://nicolassugai.github.io/YumiCrushSaga/`. O build usa caminhos relativos para o caminho base do projeto. A ação de deploy tem permissões de Pages e OIDC limitadas ao job de publicação.

## Diferenças para iOS

O app nativo continua sendo o produto SwiftUI/SpriteKit, com seu próprio ciclo de vida, áudio e persistência. A Web é um port independente das regras, não uma compilação dos arquivos Swift. Testes do navegador não substituem os testes e builds do Xcode; divergências são verificadas por invariantes equivalentes.
