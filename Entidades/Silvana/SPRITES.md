# 🎨 Lista de Sprites do Boss (Silvanna / Armateus)

Tudo é opcional: o que faltar continua como **cubo/shader placeholder**.

---

## A) Formas do corpo (AnimatedSprite2D)

Adicione nós-filho no **`Entidades/Armotheus/Armotheus.tscn`** com EXATAMENTE estes nomes.
O script mostra/esconde sozinho por fase (não mexa em "Visible").

| Nó              | Quando aparece          | Animações que o código toca |
|-----------------|-------------------------|------------------------------|
| `Forma_Chapeu`  | Fase 1 + Transição 1    | `idle`, `attack`, `laser_warn`, `laser_fire`, `staggered` |
| `Forma_Lamina`  | Fase 2                  | `idle`, `attack`, `staggered` |
| `Forma_Bruxa`   | Transição 2 + Fase 3    | `idle`, `staggered` |
| `Forma_Final`   | Fase Final              | `idle`, `staggered` |

**O que cada animação significa:**
- `idle` — parado (toda forma deve ter).
- `attack` — Pêndulo (chapéu) / Corte Fantasma (lâmina).
- `laser_warn` — aviso da Varredura Escarlate (chapéu).
- `laser_fire` — disparo da Varredura (chapéu).
- `staggered` — quando o stagger é quebrado (atordoado). Opcional.

> O nó `AnimatedSprite2D` que já existe também vale como `Forma_Chapeu`.

---

## B) Skins dos ataques (PackedScene → campos `Skin ...` no Inspetor do boss)

Cada campo aceita uma **cena**. Centralize a arte na **origem (0,0)**.
Dica: se a raiz da cena for um **Control** (TextureRect/NinePatchRect), ela é
**redimensionada automaticamente** pro tamanho do ataque (ótimo pros largões).
Se for **Sprite2D**, mantém o tamanho nativo (bom pros pequenos).

| Campo               | Ataque                         | Tamanho aprox. | Formato |
|---------------------|--------------------------------|----------------|---------|
| `Skin Laser`        | coluna da Varredura Escarlate  | 6 × altura da arena | vertical fina |
| `Skin Gelo`         | poça de gelo no chão           | 56 × 12        | horizontal baixa |
| `Skin Corte`        | Corte Fantasma / linhas do Final | largura da arena × 10 | horizontal longa |
| `Skin Espada`       | colunas da Chuva de Espadas    | 24 × altura da arena | vertical |
| `Skin Espelho Laser`| lasers da Transição 2          | largura da arena × 8 | horizontal longa |
| `Skin Faca`         | facas de ricochete             | 12 × 4         | pequena |
| `Skin Dragao`       | mãos de dragão                 | 28 × 20        | média |
| `Skin Espinho`      | espinhos da parede (Vassoura)  | 16 × altura da arena | vertical |
| `Skin Nucleo`       | núcleo letal do Vórtice        | 44 × altura da arena | coluna central |
| `Skin Blizzard`     | nevasca da Fase Final          | tela inteira   | cena com shader |

**Ainda são cubos (sem campo de skin por enquanto):**
- Clones do **Duelo de Sombras** (1 azul = verdadeiro, 1 cinza = falso).
- Clones + ícone dos **Espelhos Gêmeos** (vermelho / prata).
> Se quiser, eu adiciono campos de skin pra esses também.

---

## C) Resumo do que produzir

**Animadas (sprite-sheets):** Forma_Chapeu, Forma_Lamina, Forma_Bruxa, Forma_Final
(cada uma com pelo menos `idle`; chapéu/lâmina com `attack`; chapéu com `laser_warn`/`laser_fire`).

**Estáticas/curtas (cenas de skin):** laser, gelo, corte, espada, espelho_laser,
faca, dragao, espinho, nucleo, blizzard.
