# Steal a Car

Jogo de Roblox: compre carros na esteira, junte dinheiro na sua garagem e roube os carros raros dos outros jogadores.

O documento de design completo do MVP fica nos arquivos do projeto (`steal-a-car/design-mvp.md`).

## Como rodar no Roblox Studio (primeira vez)

O código fica neste repositório e é sincronizado com o Studio pelo **Rojo**.

1. Instale o **[Git](https://git-scm.com/downloads)** e o **[VS Code](https://code.visualstudio.com/)**.
2. No VS Code, abra a paleta de comandos (`Ctrl+Shift+P`), escolha **Git: Clone** e cole `https://github.com/devsoriginall/steal-a-car.git`.
3. Instale a extensão **"Rojo - Roblox Studio Sync"** no VS Code. Quando ela oferecer, aceite instalar o Rojo e o plugin do Studio.
4. Abra o **Roblox Studio** e crie um jogo novo a partir do modelo **Baseplate**.
5. No VS Code, rode `Ctrl+Shift+P` → **Rojo: Open menu** e clique em `default.project.json` para iniciar o servidor.
6. No Studio, abra a aba **Plugins** → **Rojo** → **Connect**. Os scripts aparecem no Studio.
7. Clique em **Play** (F5). O mapa, as garagens e a esteira são criados automaticamente.

Toda vez que o código mudar aqui no GitHub, rode **Git: Pull** no VS Code. Com o Rojo conectado, o Studio é atualizado sozinho.

### Para testar o save
O progresso só é salvo depois que o jogo é publicado (**File → Publish to Roblox**) e a opção **Game Settings → Security → Enable Studio Access to API Services** está ativada. Sem ela, o jogo funciona, mas o progresso volta do zero a cada teste.

### Antes de lançar
- **Game Settings → Places → Max Players: 8** (uma garagem por jogador).

## Como funciona o roubo

- Na garagem de outro jogador, segure **E** em um carro para pegá-lo. Uma miniatura fica sobre sua cabeça e você anda mais devagar.
- Entre na **sua** garagem para ficar com o carro.
- Se alguém te acertar com o **Taco** (tecla 1 para equipar, clique para bater), se você morrer ou sair do jogo, o carro volta para o dono.
- Não dá para roubar uma garagem **trancada** (botão vermelho na entrada, 60s, recarga de 3 min) nem a de quem entrou há menos de **5 minutos**.
- Para testar sozinho, use **Teste → Clientes e servidores → 2 jogadores → Iniciar**.

## Loja de Robux

Os itens ficam em `src/shared/Config/Products.luau`. Para ativar um item, crie-o em
**create.roblox.com → seu jogo → Monetização** (Passes ou Produtos de desenvolvedor)
e coloque o ID dele no campo `id`. Item com `id = 0` aparece como "Em breve".

No Studio, as compras são simuladas: o Roblox mostra a janela de compra, mas não cobra Robux.

## Estrutura do código

```
src/
  shared/              -> ReplicatedStorage.Shared (servidor e cliente)
    Config/
      Cars.luau        carros: preço, renda, raridade, cor
      Rarities.luau    raridades e chance de aparecer
      Mutations.luau   Dourado ×2, Diamante ×5, Neon ×10
      Products.luau    itens da loja de Robux (IDs do site do Roblox)
      CarStyles.luau   formato 3D de cada carro (tamanho, cabine, detalhes)
      GameConfig.luau  números gerais (dinheiro inicial, vagas, esteira...)
    Format.luau        formata $1.5K, $2.3M...
    Net.luau           RemoteEvents
  server/              -> ServerScriptService.Server
    Main.server.luau   inicia tudo e cuida da entrada e saída de jogadores
    Modules/CarFactory.luau     monta o modelo 3D de cada carro a partir do CarStyles
    Services/
      DataService.luau     save/load no DataStore
      MapService.luau      gera chão, esteira e 8 garagens
      EconomyService.luau  dinheiro, renda por segundo, placar
      GarageService.luau   vagas, carros na garagem, vender, comprar vaga
      ConveyorService.luau carros na esteira e compra
      StealService.luau    roubo: pegar, carregar e entregar carros
      CombatService.luau   taco (derruba o carro de quem está roubando)
      RebirthService.luau  rebirth: zera o progresso por +50% de renda
      MonetizationService.luau game passes e produtos (Robux)
  client/              -> StarterPlayerScripts.Client
    HUD.client.luau          dinheiro, renda e notificações
    PromptFilter.client.luau mostra cada botão só para quem pode usá-lo
    Shop.client.luau         loja de Robux
```

**Balanceamento:** quase tudo se ajusta em `src/shared/Config/`, sem mexer na lógica.

**Segurança:** dinheiro, compras e vendas são sempre calculados no servidor. O cliente só mostra informações.

## Status

- [x] Semana 1: mapa, garagens, esteira, compra, renda por segundo, venda, vagas, save
- [x] Semana 2a: roubo, taco, trava da garagem, proteção de iniciante, rebirth
- [x] Semana 2b: game passes e produtos (Robux) — falta preencher os IDs em Products.luau
- [ ] Semana 3: modelos 3D de verdade, sons, polimento, lançamento
