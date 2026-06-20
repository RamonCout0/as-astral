# 🔄 GUIA DE REFATORAÇÃO - AS ASTRAL
# De C# para GDScript

## 📁 Arquivos Convertidos

✅ **Criados com sucesso:**
1. `Entidades/Armotheus/armotheus.gd` (convertido de Armotheus.cs)
2. `Entidades/Armotheus/laser_escarlate.gd` (convertido de LaserEscarlate.cs)
3. `Entidades/Armotheus/fire_hazard.gd` (convertido de FireHazard.cs)

---

## 🔧 Mudanças Necessárias nas Cenas (.tscn)

### 1. **Armotheus.tscn**

**ANTES:**
```
[node name="Armotheus" type="CharacterBody2D"]
script = ExtResource("Armotheus.cs")
```

**DEPOIS:**
```
[node name="Armotheus" type="CharacterBody2D"]
script = ExtResource("armotheus.gd")
```

**Propriedades exportadas (verificar na inspetor):**
- `arena_left`, `arena_right`, `arena_top`, `arena_floor`
- `attack_cooldown`
- `laser_scene` → Apontar para `LaserEscarlate.tscn` (será criada)
- `fire_hazard_scene` → Apontar para `FireHazard.tscn` (será criada)

---

### 2. **LaserEscarlate.tscn** (CRIAR NOVA CENA)

```
[node name="LaserEscarlate" type="Node2D"]
script = ExtResource("laser_escarlate.gd")
```

**Estrutura:**
- Root: Node2D
- Script: `laser_escarlate.gd`
- Não precisa de filhos (Line2D é criado dinamicamente)

---

### 3. **FireHazard.tscn** (CRIAR NOVA CENA)

```
[node name="FireHazard" type="Area2D"]
script = ExtResource("fire_hazard.gd")
```

**Estrutura:**
- Root: Area2D
- Script: `fire_hazard.gd`
- Collision Layer: 0
- Collision Mask: 2 (player)
- Não precisa de filhos (criados dinamicamente no _ready)

---

## 🎯 Principais Diferenças C# → GDScript

### **Sintaxe**

| C# | GDScript |
|---|---|
| `public partial class` | `extends CharacterBody2D` |
| `[Export]` | `@export` |
| `private float _hp;` | `var _hp : float = 0.0` |
| `const float MaxHp = 100f;` | `const MAX_HP := 100.0` |
| `enum BossState { Idle, Dead }` | `enum BossState { IDLE, DEAD }` |
| `Mathf.Max(a, b)` | `max(a, b)` |
| `Mathf.Clamp(x, 0, 1)` | `clamp(x, 0.0, 1.0)` |
| `GD.Randf()` | `randf()` |
| `GetNode<T>("path")` | `get_node("path")` |
| `GetNodeOrNull<T>()` | `get_node_or_null()` |
| `AddToGroup("boss")` | `add_to_group("boss")` |
| `IsInGroup("player")` | `is_in_group("player")` |
| `EmitSignal("signal_name", arg)` | `signal_name.emit(arg)` |

### **Signals**

**C#:**
```csharp
[Signal] public delegate void FinishedEventHandler();
EmitSignal(SignalName.Finished);
```

**GDScript:**
```gdscript
signal finished
finished.emit()
```

### **Timers**

**C#:**
```csharp
GetTree().CreateTimer(1.5f).Timeout += FireLaser;
```

**GDScript:**
```gdscript
await get_tree().create_timer(1.5).timeout
_fire_laser()
```

### **Delegates/Lambdas**

**C#:**
```csharp
laser.CounterHit += () => AddStagger(2_500f);
```

**GDScript:**
```gdscript
laser.counter_hit.connect(func(): _add_stagger(2_500.0))
```

---

## 🗑️ Arquivos para DELETAR (após validar tudo)

### **Arquivos C#:**
- ❌ `Entidades/Armotheus/Armotheus.cs`
- ❌ `Entidades/Armotheus/LaserEscarlate.cs`
- ❌ `Entidades/Armotheus/FireHazard.cs`

### **Arquivos .uid (se existirem):**
- ❌ `Armotheus.cs.uid`
- ❌ `LaserEscarlate.cs.uid`
- ❌ `FireHazard.cs.uid`

### **Projeto C#:**
- ❌ `As astral.csproj`
- ❌ `As astral.csproj.old`
- ❌ `As astral.csproj.old.1`
- ❌ `as-astral.sln`

### **Diretório .mono:**
- ❌ Toda a pasta `.mono` (se existir)

---

## ✅ Checklist de Migração

### **Fase 1: Preparação**
- [ ] Backup completo do projeto (Git commit ou cópia)
- [ ] Verificar que todos os arquivos GDScript foram criados

### **Fase 2: Criar Cenas**
- [ ] Criar `LaserEscarlate.tscn`
  - Root: Node2D
  - Script: `laser_escarlate.gd`
- [ ] Criar `FireHazard.tscn`
  - Root: Area2D
  - Script: `fire_hazard.gd`
  - Collision Layer: 0
  - Collision Mask: 2

### **Fase 3: Atualizar Armotheus.tscn**
- [ ] Abrir `Armotheus.tscn` no editor
- [ ] Remover script C# antigo
- [ ] Adicionar `armotheus.gd`
- [ ] Configurar propriedades exportadas:
  - [ ] `arena_left` = 16
  - [ ] `arena_right` = 464
  - [ ] `arena_top` = 16
  - [ ] `arena_floor` = 252
  - [ ] `attack_cooldown` = 3.5
  - [ ] `laser_scene` → LaserEscarlate.tscn
  - [ ] `fire_hazard_scene` → FireHazard.tscn

### **Fase 4: Atualizar boss_teste.tscn**
- [ ] Abrir `Mundos/teste/boss_teste.tscn`
- [ ] Verificar se Armotheus está usando o novo script
- [ ] Testar a cena

### **Fase 5: Testes**
- [ ] Rodar o jogo
- [ ] Testar ataque Pêndulo U
- [ ] Testar ataque Laser Escarlate
- [ ] Testar sistema de counter no laser
- [ ] Testar sistema de stagger
- [ ] Testar morte do boss
- [ ] Verificar UI (barras de HP e stagger)

### **Fase 6: Limpeza**
- [ ] Deletar arquivos C# antigos
- [ ] Deletar arquivos `.csproj` e `.sln`
- [ ] Limpar diretório `.mono` (se existir)
- [ ] Commit no Git com mensagem descritiva

---

## 🐛 Possíveis Problemas e Soluções

### **Problema 1: "Invalid call. Nonexistent function 'initialize'"**
**Causa:** A cena LaserEscarlate não foi criada ou o script não está anexado.
**Solução:** Criar a cena LaserEscarlate.tscn com o script laser_escarlate.gd.

### **Problema 2: "Attempt to call function 'take_damage' in base 'null instance'"**
**Causa:** Player não foi encontrado ou foi deletado.
**Solução:** Verificar se o player tem o grupo "player" configurado.

### **Problema 3: Animações não tocam**
**Causa:** AnimatedSprite2D não tem as animações corretas.
**Solução:** Verificar se as animações existem: idle, attack, laser_warn, laser_fire, staggered, dead.

### **Problema 4: Laser não aparece**
**Causa:** Line2D não está sendo criado corretamente.
**Solução:** Verificar se a função initialize() está sendo chamada ANTES de add_child().

---

## 📝 Observações Importantes

### **Sistema de Initialize()**
Em GDScript, não podemos garantir a ordem de execução entre `_ready()` e propriedades.
Por isso, usamos o padrão `initialize()`:

```gdscript
# NO SCRIPT QUE INSTANCIA:
var laser = laser_scene.instantiate()
laser.initialize(params...)  # ← ANTES de add_child
get_parent().add_child(laser)

# NO SCRIPT DO LASER:
func initialize(params...) -> void:
    _origin = origin
    # ... salva os parâmetros

func _ready() -> void:
    # Usa os parâmetros salvos
    global_position = _origin
```

### **Tipagem Estática**
Todo o código usa tipagem estática do GDScript:
```gdscript
var _hp : float = 0.0
func take_damage(amount: float) -> void:
```

Isso oferece:
- ✅ Melhor performance
- ✅ Autocomplete no editor
- ✅ Detecção de erros em tempo de edição

### **Convenções de Nome**
- Constantes: `SNAKE_CASE_CAPS`
- Variáveis privadas: `_snake_case` (prefixo `_`)
- Funções públicas: `snake_case`
- Funções privadas: `_snake_case`
- Enums: `PascalCase { CAPS_VALUES }`

---

## 🚀 Próximos Passos Sugeridos

Após validar a refatoração do Armotheus:

1. **Otimizações de Performance:**
   - Pool de objetos para FireHazard (reutilizar em vez de instanciar/destruir)
   - Cache de referências (get_node só uma vez)

2. **Melhorias de Código:**
   - Sistema de states mais robusto (State Pattern)
   - Separar lógica de ataques em arquivos próprios

3. **Features:**
   - Efeitos visuais (particles, shaders)
   - Efeitos sonoros
   - Mais padrões de ataque

4. **Refatorar Silvana:**
   - Aplicar o mesmo processo de migração
   - Manter consistência de código

---

**Data da Refatoração:** 2026-05-16
**Criado por:** Claude (Sonnet 4.5)
**Projeto:** As Astral - Godot 4.x
