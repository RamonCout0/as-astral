# 🗡️ Boss Silvanna (Armateus + Silvanna) — Guia Completo

A luta inteira é **um boss só**, com **um HP único** (304x barras de 1.000).
Tudo roda pelo script **`res://silvanna.gd`**, anexado à cena única do boss:

> **Cena única do boss:** `res://Entidades/Armotheus/Armotheus.tscn`
> (Armateus é a *forma da Fase 1* da Silvanna — por isso ficam no mesmo `.tscn`.)

Cenas de teste:
- `Mundos/teste/teste.tscn` — mapa completo.
- `Mundos/teste/silvanna_teste.tscn` — arena limpa.

---

## 1) Sprites de cada forma (corpo do boss)

O boss troca de "forma" por fase. Para usar SEU sprite, adicione um nó-filho
no `Armotheus.tscn` (clique direito no nó raiz **Armotheus → Add Child Node →
AnimatedSprite2D**) com **exatamente** estes nomes:

| Nó (nome exato) | Aparece em | Forma |
|---|---|---|
| `Forma_Chapeu`  | Fase 1 + Transição 1 | Armateus chapéu |
| `Forma_Lamina`  | Fase 2 | Armateus espadachim |
| `Forma_Bruxa`   | Transição 2 + Fase 3 | Silvanna |
| `Forma_Final`   | Fase Final | Zero Absoluto |

> O `AnimatedSprite2D` que já existe vale como `Forma_Chapeu` (compatibilidade) —
> não precisa renomear.

**Passo a passo para colocar um sprite numa forma:**
1. Adicione o nó `AnimatedSprite2D` com o nome da tabela (ex.: `Forma_Lamina`).
2. No `SpriteFrames` dele, crie as animações abaixo (pelo menos `idle`).
3. Arraste seu sprite-sheet e fatie nos frames.
4. Pronto — o código mostra/esconde automático por fase. **Não mexa em "Visible"**,
   o script controla. Se a forma não existir, ele cai num **cubo de cor** placeholder.

**Nomes de animação que o código toca** (crie os que quiser, os que faltarem são ignorados):
- `idle` — parado (todas as formas)
- `attack` — Pêndulo (chapéu) e Corte Fantasma (lâmina)
- `laser_warn` / `laser_fire` — Varredura Escarlate (chapéu)
- `staggered` — quando o stagger é quebrado (atordoado)

---

## 2) Trocar o placeholder dos ATAQUES (cubos → sua arte)

Cada ataque desenha um **cubo** por padrão. Para trocar por arte, selecione o nó
do boss e arraste uma **cena (.tscn/PackedScene)** no campo `Skin ...` correspondente
(no Inspetor, grupo de cada ataque):

| Campo (Inspetor) | Ataque |
|---|---|
| `Skin Laser`         | coluna da Varredura Escarlate |
| `Skin Gelo`          | poças de gelo |
| `Skin Corte`         | linha do Corte Fantasma / linhas do Final |
| `Skin Espada`        | colunas da Chuva de Espadas |
| `Skin Espelho Laser` | lasers da Transição 2 |
| `Skin Faca`          | facas de ricochete |
| `Skin Dragao`        | mãos de dragão |
| `Skin Espinho`       | espinhos da Vassoura |
| `Skin Nucleo`        | núcleo do Vórtice |

> A skin é só visual — a hitbox/tamanho/dano continua vindo da config do ataque.
> Faça a arte centralizada na origem (0,0). Se nenhum skin for setado, usa o cubo.
> (Clones do Duelo, ícone dos Espelhos e a nevasca do Final continuam cubos por enquanto.)

---

## 3) Configurar os ataques (velocidade / dano / telegrafo)

**Tudo no Inspetor**, selecionando o nó do boss. Cada ataque tem seu grupo.
Os principais:

### Geral
- `Move Speed` — velocidade do boss se reposicionar.
- `Pause Fase1/2/3` — tempo de respiro entre ataques (maior = mais lento).

### Pêndulo
- `Pendulo Speed` — **maior = arco mais rápido**.
- `Pendulo Damage`, `Pendulo Range` (distância que machuca).

### Varredura Escarlate
- `Laser Telegraph` — tempo de aviso antes de disparar.
- `Laser Speed` — **velocidade da varredura** (maior = mais difícil).
- `Laser Damage`.

### Corte Fantasma / Chuva de Espadas
- `Corte Telegraph` / `Espadas Telegraph` — tempo de aviso (maior = mais fácil).
- `Corte Active` / `Espadas Active` — quanto tempo o golpe fica ativo.
- `... Damage`. `Espadas Gaps` — nº de brechas seguras.

### Transições (gates de stagger)
- `Vortice Time` / `Trans2 Time` — tempo p/ quebrar o stagger antes do **wipe**.
- `Vortice Pull` — força da sucção.
- `Espelho Laser Interval/Telegraph/Active/Damage` — lasers da Transição 2.

### Fase Final
- `Final Time` — tempo do DPS check.
- `Final Dps Check` — dano necessário p/ vencer no tempo.
- `Hipotermia Pct` — % de vida do player perdida por segundo.
- `Final Knife/Cut Interval` — frequência de facas/linhas.

---

## 4) Dano, Parry/Counter e Quebra de Stagger

- **Dano no boss:** o golpe do player chama `take_damage()` (tira HP) **e**
  `add_stagger()` (enche a barra amarela). Ajuste o quanto de stagger por golpe
  no **player** em `Assets/Player/Cena/player.gd` → `STAGGER_RATIO` (0.6 = 60% do dano).
- **Feedback de dano:** o boss **pisca vermelho** ao levar dano.
- **Parry/Counter (tecla Z):** em Duelo de Sombras, Vassoura e Espelhos Gêmeos,
  acertar o counter faz o boss **piscar azul**; no Duelo ainda **enche 40% do stagger**.
- **Quebra de Stagger:** quando a barra amarela enche, o boss entra em
  **atordoado** por `Stagger Stun Time` segundos:
  - toca a animação `staggered` e fica amarelo;
  - leva **dano multiplicado** por `Stagger Stun Dmg Mult` (padrão 2x) — é a janela de DPS;
  - emite o sinal `boss_staggered` (pra som/câmera, se quiser).
- **Transições (Vórtice / Espelhos):** lá o stagger é um **portão** — encha a barra
  no tempo, senão é **wipe** (morte). O dano normal não passa ali (boss imune a HP).

---

## 5) HUD

- **Vida do boss + barra de stagger:** `UI/boss_hud.tscn` (já reage aos sinais).
- **Vida do player:** `UI/player_hud.tscn` (ProgressBar no canto).
- Ambos já estão nas cenas de teste.

---

## 6) Dicas de desvio (pra testar)

- **Dash (Shift) dá invencibilidade** — atravessa quase tudo.
- Todo perigo **pisca translúcido (aviso)** antes de ficar **sólido (dano)**.
- Laser/linha horizontal: pule se for baixo, fique no chão se for alto, ou dash.
- Núcleo do Vórtice / espinhos da Vassoura: **encostar = morte**, não toque.
- Colunas (Espadas): corra para as brechas.

---

## 7) Shaders (efeitos)

- **Ataques:** todos os cubos de perigo usam o shader `Shaders_Efeitos/perigo.gdshader`
  (brilho + pulso + borda de energia), na **cor de cada ataque**. Ajuste os uniforms
  (`pulse_speed`, `glow`, `edge_glow`, `scan_speed`) direto no `.gdshader`.
- **Nevasca (Fase Final):** tela cheia com `tempestade_neve.gdshader` intensificado.
  Tune por `Blizzard Density` ou troque tudo por `Skin Blizzard`.
- Para shader em UM ataque específico, faça uma cena com `ShaderMaterial` e plugue no
  campo `Skin ...` dele (a skin substitui o cubo).

## 8) Trocar a música ao surgir a Silvanna

Grupo **Áudio** no Inspetor do boss:
- `Silvanna Music` — arraste o arquivo de música (toca na **Transição 2**, quando a
  Silvanna surge).
- `Music Player` — (opcional) aponte para o `AudioStreamPlayer` da cena que deve trocar
  de faixa. **Se deixar vazio, o script acha o AudioStreamPlayer da cena sozinho** e
  troca a faixa nele (sem sobrepor). Se não houver nenhum, ele cria um interno.
