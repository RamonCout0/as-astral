# silvanna.gd
# ============================================================================
# BOSS: Silvanna, a Maga de Prata  —  PLACEHOLDER COMPLETO (tudo com cubos)
# ----------------------------------------------------------------------------
# Implementa, como placeholder visual (ColorRect), TODAS as fases/mecânicas
# descritas no GDD. A progressão é dirigida por limiares de HP.
#
#  FASE 1  (304x -> 280x)  Armateus (chapéu): Pêndulo, Varredura Escarlate, Chuva de Gelo
#  TRANS 1 (280x)          Vórtice de Sucção  (stagger check 5.000)
#  FASE 2  (280x -> 192x)  Armateus (lâmina): Corte Fantasma, Duelo de Sombras, Chuva de Espadas
#  TRANS 2 (192x)          Fortificando a Neve (espelhos + stagger check 20s)
#  FASE 3  (192x -> 15x)   Silvanna: Facas de Ricochete, Mãos de Dragão,
#                          Vassoura (gatilho 175x), Espelhos Gêmeos (gatilho 140x)
#  FINAL   (15x -> 0)      Zero Absoluto: enrage, DPS check 15.000 em 40s
#
# Muitas mecânicas que exigem suporte do player (atrito do gelo, ícone de cor)
# estão marcadas com TODO e simplificadas — o objetivo aqui é o esqueleto jogável.
# ============================================================================
extends CharacterBody2D

# --- ARENA --------------------------------------------------------------------
@export_group("Arena")
@export var arena_left  : float = 16.0
@export var arena_right : float = 464.0
@export var arena_top   : float = 16.0
@export var arena_floor : float = 252.0
## Altura em que o boss flutua parado, medida ACIMA do arena_floor.
## Menor = mais perto do chão (melhor para personagens melee/baixinhas).
@export var hover_height : float = 40.0

# --- VIDA / STAGGER -----------------------------------------------------------
const MAX_HP      := 304_000.0
const HP_PER_BAR  := 1_000.0
const MAX_STAGGER := 5_000.0
const STAGGER_DECAY := 250.0     # decaimento por segundo

# Limiares de fase (em HP absoluto)
const TH_TRANS1   := 280_000.0
const TH_TRANS2   := 192_000.0
const TH_VASSOURA := 175_000.0
const TH_ESPELHOS := 140_000.0
const TH_FINAL    :=  15_000.0

var current_hp : float = MAX_HP
var stagger    : float = 0.0
var is_immune  : bool  = false   # true durante transições / enrage no chão

# --- ESTADO -------------------------------------------------------------------
enum State { INTRO, FIGHT, STAGGERED, DEAD }
var state : State = State.INTRO

var _did_vassoura := false
var _did_espelhos := false
var _counter_flag := false

# --- REFERÊNCIAS --------------------------------------------------------------
# Visual: aceita tanto AnimatedSprite2D (arte do chapéu Armateus na Fase 1)
# quanto um ColorRect "Sprite" (placeholder em cubo).
var _anim      : AnimatedSprite2D = null
var _rect      : ColorRect = null
var _body_cube : ColorRect = null   # cubo placeholder de corpo por fase
var _player    : CharacterBody2D = null

const HAZARD := preload("res://Entidades/Silvana/silvanna_hazard.gd")
const KNIFE  := preload("res://Entidades/Silvana/silvanna_knife.gd")
const DRAGON := preload("res://Entidades/Silvana/silvanna_dragon_hand.gd")


# =============================================================================
# INIT
# =============================================================================
func _ready() -> void:
	randomize()
	add_to_group("boss")

	_anim = get_node_or_null("AnimatedSprite2D")
	_rect = get_node_or_null("Sprite")

	# Corpo placeholder: reusa o ColorRect "Sprite" se existir, senão cria um cubo.
	if _rect:
		_body_cube = _rect
	else:
		_body_cube = ColorRect.new()
		_body_cube.size     = Vector2(44.0, 44.0)
		_body_cube.position = Vector2(-22.0, -22.0)
		add_child(_body_cube)
	_body_cube.visible = (_anim == null)   # com arte, começa escondido (Fase 1 usa o chapéu)

	_player = get_tree().get_first_node_in_group("player")
	if _player == null:
		push_warning("[Silvanna] Player não encontrado no grupo 'player'!")

	EventBus.boss_max_health_set.emit(MAX_HP, HP_PER_BAR)
	EventBus.boss_stagger_updated.emit(0.0, MAX_STAGGER)

	if EventBus.has_signal("player_counter_pressed"):
		EventBus.player_counter_pressed.connect(func(): _counter_flag = true)

	global_position = _idle_pos()
	_play_anim("idle")

	_fight()   # corrotina mestra


func _physics_process(delta: float) -> void:
	if state == State.DEAD:
		return
	# Decaimento natural do stagger fora das transições
	if not is_immune and stagger > 0.0:
		stagger = max(0.0, stagger - STAGGER_DECAY * delta)
		EventBus.boss_stagger_updated.emit(stagger, MAX_STAGGER)


# =============================================================================
# CORROTINA MESTRA DO COMBATE
# =============================================================================
func _fight() -> void:
	await _sleep(0.5)
	state = State.FIGHT

	await _phase_1()
	if not _alive(): return
	await _trans_1()
	if not _alive(): return
	await _phase_2()
	if not _alive(): return
	await _trans_2()
	if not _alive(): return
	await _phase_3()
	if not _alive(): return
	await _phase_final()


# ─────────────────────────────────────────────────────────────────────────
# FASE 1 — O PRELÚDIO (chapéu)
# ─────────────────────────────────────────────────────────────────────────
func _phase_1() -> void:
	_banner("FASE 1: O Prelúdio", Color(0.6, 0.1, 0.1))
	_set_body(true, Color(0.6, 0.1, 0.1))   # chapéu Armateus (arte)
	var i := 0
	while _alive() and current_hp > TH_TRANS1:
		match i % 3:
			0:
				await _atk_pendulo()
			1:
				await _atk_varredura_escarlate()
			2:
				await _atk_chuva_de_gelo()
		i += 1
		await _between_attacks(1.2)


# Pêndulo Mortal: o chapéu varre o chão num arco em "U".
func _atk_pendulo() -> void:
	var from_left := randf() > 0.5
	var start := Vector2(arena_left + 16.0 if from_left else arena_right - 16.0, arena_top + 16.0)
	var end_x : float = clamp(_player.global_position.x, arena_left, arena_right) if _player else _arena_center().x
	var peak := arena_floor - 6.0

	await _move_to(start, 260.0)
	if not _alive(): return

	_play_anim("attack")
	var t := 0.0
	var dmg_cd := 0.0
	var dt := get_physics_process_delta_time()
	while _alive() and t < 1.0:
		t += dt * 1.8
		var tt := clampf(t, 0.0, 1.0)
		var x := lerpf(start.x, end_x, tt)
		var curve := pow(sin(tt * PI), 0.6)
		var y := lerpf(start.y, peak, curve)
		global_position = Vector2(clamp(x, arena_left, arena_right), clamp(y, arena_top, arena_floor))

		dmg_cd -= dt
		if _player and is_instance_valid(_player):
			if global_position.distance_to(_player.global_position) < 30.0 and dmg_cd <= 0.0 and not _player.get("is_dashing"):
				_player.take_damage(2000.0)
				dmg_cd = 0.3
		await get_tree().physics_frame

	_play_anim("idle")
	await _move_to(_idle_pos(), 260.0)


# Varredura Escarlate: laser desce de um canto e varre o chão até o player.
func _atk_varredura_escarlate() -> void:
	var from_left := randf() > 0.5
	var corner := Vector2(arena_left + 16.0 if from_left else arena_right - 16.0, arena_top + 16.0)
	await _move_to(corner, 240.0)
	if not _alive(): return

	_play_anim("laser_warn")
	# Coluna de laser (telegrafo)
	var beam := ColorRect.new()
	beam.size     = Vector2(6.0, arena_floor - arena_top)
	beam.position = Vector2(-3.0, 0.0)
	beam.color    = Color(1.0, 0.1, 0.05, 0.35)
	var beam_root := Node2D.new()
	beam_root.add_child(beam)
	get_parent().add_child(beam_root)
	var x := corner.x
	beam_root.global_position = Vector2(x, arena_top)

	await _sleep(0.8)
	if not _alive():
		beam_root.queue_free(); return
	_play_anim("laser_fire")
	beam.color = Color(1.0, 0.1, 0.05, 0.9)

	var target_x : float = _player.global_position.x if _player else _arena_center().x
	var dir : float = sign(target_x - x)
	if dir == 0.0: dir = 1.0

	var dt := get_physics_process_delta_time()
	while _alive():
		x += dir * 170.0 * dt
		beam_root.global_position.x = x
		# Só passa ileso com dash (I-frame)
		if _player and is_instance_valid(_player):
			if abs(_player.global_position.x - x) < 10.0 and not _player.get("is_dashing"):
				_player.take_damage(1800.0)
		if x <= arena_left + 8.0 or x >= arena_right - 8.0:
			break
		await get_tree().physics_frame

	beam_root.queue_free()


# Chuva de Gelo: 3 poças de gelo permanentes (placeholder visual).
func _atk_chuva_de_gelo() -> void:
	await _move_to(_idle_pos(), 220.0)
	for n in 3:
		var px := randf_range(arena_left + 30.0, arena_right - 30.0)
		# TODO: gelo deveria reduzir atrito/velocidade do player (precisa de suporte no player.gd)
		var ice := _spawn_hazard(
			Vector2(px, arena_floor - 6.0),
			Vector2(56.0, 12.0), Color(0.4, 0.8, 1.0),
			0.0, 0.5, 25.0)     # dano 0, só visual
		await _sleep(0.25)


# ─────────────────────────────────────────────────────────────────────────
# TRANSIÇÃO 1 — VÓRTICE DE SUCÇÃO (stagger check)
# ─────────────────────────────────────────────────────────────────────────
func _trans_1() -> void:
	_banner("TRANSIÇÃO 1: O Vórtice de Sucção", Color(0.3, 0.0, 0.5))
	_set_body(false, Color(0.5, 0.1, 0.7))   # roxo
	is_immune = true
	await _move_to(Vector2(_arena_center().x, arena_floor - 20.0), 200.0)
	_reset_stagger()

	# Núcleo letal no centro (encostar = wipe)
	var core := _spawn_hazard(global_position, Vector2(34.0, 34.0), Color(0.6, 0.0, 0.8), 0.0, 30.0, 0.0, false, true)

	var dt := get_physics_process_delta_time()
	var t := 0.0
	var success := false
	while _alive() and t < 25.0:
		t += dt
		# Sucção: puxa o player no eixo X em direção ao centro
		if _player and is_instance_valid(_player):
			var cx := _arena_center().x
			_player.global_position.x = move_toward(_player.global_position.x, cx, 60.0 * dt)
		if stagger >= MAX_STAGGER:
			success = true
			break
		await get_tree().physics_frame

	if is_instance_valid(core): core.queue_free()

	if not success and _alive():
		_wipe()   # falhou o check -> punição
	_reset_stagger()
	is_immune = false


# ─────────────────────────────────────────────────────────────────────────
# FASE 2 — A LÂMINA SOMBRIA (espadachim)
# ─────────────────────────────────────────────────────────────────────────
func _phase_2() -> void:
	_banner("FASE 2: A Lâmina Sombria", Color(0.1, 0.2, 0.7))
	_set_body(false, Color(0.2, 0.3, 0.9))   # azul (espadachim)
	var i := 0
	while _alive() and current_hp > TH_TRANS2:
		match i % 3:
			0:
				await _atk_corte_fantasma()
			1:
				await _atk_duelo_de_sombras()
			2:
				await _atk_chuva_de_espadas()
		i += 1
		await _between_attacks(1.0)


# Corte Fantasma: linha horizontal alta (não pula) ou baixa (pula).
func _atk_corte_fantasma() -> void:
	await _move_to(Vector2(arena_left + 12.0, arena_floor - 30.0), 320.0)
	var low := randf() > 0.5
	var y : float = (arena_floor - 12.0) if low else (arena_floor - 60.0)
	# Bar horizontal cobrindo a arena
	_spawn_hazard(
		Vector2(_arena_center().x, y),
		Vector2(arena_right - arena_left, 10.0),
		Color(1.0, 0.0, 0.0),
		2800.0, 0.8, 0.2)   # telegrafo 0.8s, golpe rápido 0.2s
	await _sleep(1.2)


# Duelo de Sombras: 2 clones, só o verdadeiro brilha azul -> counter no lado certo.
func _atk_duelo_de_sombras() -> void:
	var real_left := randf() > 0.5
	var lx := arena_left + 34.0
	var rx := arena_right - 34.0
	var real_x : float = lx if real_left else rx

	var clone_l := _make_cube(Vector2(lx, arena_floor - 20.0), Vector2(30, 40), Color(0.1, 0.3, 1.0) if real_left else Color(0.3, 0.3, 0.3))
	var clone_r := _make_cube(Vector2(rx, arena_floor - 20.0), Vector2(30, 40), Color(0.1, 0.3, 1.0) if not real_left else Color(0.3, 0.3, 0.3))

	var valid := func() -> bool:
		return _player != null and abs(_player.global_position.x - real_x) < 140.0
	var ok := await _await_counter(0.8, valid)

	if not ok and _alive() and _player:
		_player.take_damage(2500.0)

	clone_l.queue_free()
	clone_r.queue_free()


# Chuva de Espadas: colunas verticais com brechas seguras (padrão Tetris).
func _atk_chuva_de_espadas() -> void:
	await _move_to(_arena_center() + Vector2(0, -50), 300.0)
	var step := 38.0
	var n := int((arena_right - arena_left) / step)
	# escolhe 2 brechas seguras
	var gap_a := randi() % n
	var gap_b := (gap_a + 2 + randi() % maxi(1, n - 3)) % n
	for c in n:
		if c == gap_a or c == gap_b:
			continue
		var cx := arena_left + step * 0.5 + c * step
		_spawn_hazard(
			Vector2(cx, (arena_top + arena_floor) * 0.5),
			Vector2(24.0, arena_floor - arena_top),
			Color(0.8, 0.1, 0.1),
			3000.0, 1.0, 0.5)
	await _sleep(2.0)


# ─────────────────────────────────────────────────────────────────────────
# TRANSIÇÃO 2 — FORTIFICANDO A NEVE (espelhos + stagger 20s)
# ─────────────────────────────────────────────────────────────────────────
func _trans_2() -> void:
	_banner("TRANSIÇÃO 2: A Fúria da Bruxa", Color(0.0, 0.4, 0.6))
	_set_body(false, Color(0.0, 0.5, 0.6))   # teal
	is_immune = true
	await _move_to(_arena_center(), 220.0)
	# Durante a janela fica vulnerável para o player encher o stagger
	is_immune = false
	_reset_stagger()

	var dt := get_physics_process_delta_time()
	var t := 0.0
	var laser_cd := 0.0
	var success := false
	while _alive() and t < 20.0:
		t += dt
		laser_cd -= dt
		# Espelhos disparam lasers horizontais intermitentes em alturas variadas
		if laser_cd <= 0.0:
			laser_cd = 1.1
			var h := randf_range(arena_top + 30.0, arena_floor - 10.0)
			_spawn_hazard(
				Vector2(_arena_center().x, h),
				Vector2(arena_right - arena_left, 8.0),
				Color(1.0, 0.2, 0.2),
				1500.0, 0.5, 0.6, true, false)
		if stagger >= MAX_STAGGER:
			success = true
			break
		await get_tree().physics_frame

	if not success and _alive():
		_wipe()
	_reset_stagger()
	is_immune = false


# ─────────────────────────────────────────────────────────────────────────
# FASE 3 — A TEMPESTADE PRATEADA (bullet hell)
# ─────────────────────────────────────────────────────────────────────────
func _phase_3() -> void:
	_banner("FASE 3: A Tempestade Prateada", Color(0.7, 0.7, 0.8))
	_set_body(false, Color(0.85, 0.85, 0.95))   # prata (Silvanna)
	var i := 0
	while _alive() and current_hp > TH_FINAL:
		# Gatilhos únicos por HP
		if not _did_vassoura and current_hp <= TH_VASSOURA:
			_did_vassoura = true
			await _event_vassoura()
			continue
		if not _did_espelhos and current_hp <= TH_ESPELHOS:
			_did_espelhos = true
			await _event_espelhos_gemeos()
			continue

		if i % 2 == 0:
			await _atk_facas_ricochete()
		else:
			await _atk_maos_de_dragao()
		i += 1
		await _between_attacks(1.4)


# Facas de Ricochete: leque de 5 facas que quicam nas paredes.
func _atk_facas_ricochete() -> void:
	var base := (_player.global_position - global_position).angle() if _player else 0.0
	for k in 5:
		var ang := base + deg_to_rad(-40.0 + 20.0 * k)
		var knife := KNIFE.new()
		knife.set_meta("direction", Vector2.RIGHT.rotated(ang))
		knife.set_meta("arena", _arena_rect())
		get_parent().add_child(knife)
		knife.global_position = global_position
	await _sleep(0.4)


# Mãos de Dragão: perseguem o player, só morrem com counter.
func _atk_maos_de_dragao() -> void:
	for h in 2:
		var hand := DRAGON.new()
		get_parent().add_child(hand)
		hand.global_position = Vector2(
			randf_range(arena_left + 30.0, arena_right - 30.0), arena_floor - 14.0)
		await _sleep(0.5)
	await _sleep(2.0)


# Vassoura Empurradora (gatilho 175x): vento + espinhos na esquerda + counter.
func _event_vassoura() -> void:
	_banner("Vassoura Empurradora", Color(0.6, 0.8, 0.9))
	await _move_to(Vector2(arena_right - 20.0, arena_floor - 20.0), 260.0)
	# Espinhos letais na parede esquerda
	var spikes := _spawn_hazard(
		Vector2(arena_left + 8.0, (arena_top + arena_floor) * 0.5),
		Vector2(16.0, arena_floor - arena_top),
		Color(0.7, 0.7, 0.7), 0.0, 8.0, 0.0, false, true)

	var dt := get_physics_process_delta_time()
	var t := 0.0
	# Empurra o player para a direita (TODO: chão escorregadio precisa de suporte no player)
	while _alive() and t < 3.0:
		t += dt
		if _player and is_instance_valid(_player):
			_player.global_position.x += 70.0 * dt
		await get_tree().physics_frame

	# A vassoura brilha -> janela de counter
	_set_color(Color(1.0, 1.0, 0.4))
	var valid := func() -> bool:
		return _player != null and _player.global_position.x > _arena_center().x
	var ok := await _await_counter(1.2, valid)
	if ok:
		_add_stagger(MAX_STAGGER)   # atordoa
	elif _alive() and _player:
		_player.take_damage(3000.0)

	if is_instance_valid(spikes): spikes.queue_free()
	_set_body(false, Color(0.85, 0.85, 0.95))   # volta à prata


# Espelhos Gêmeos (gatilho 140x): só pode bater no clone da cor OPOSTA ao ícone.
func _event_espelhos_gemeos() -> void:
	_banner("Os Espelhos Gêmeos", Color(0.8, 0.2, 0.5))
	await _move_to(_arena_center(), 240.0)
	# ícone do player: vermelho ou prata; deve atingir a cor OPOSTA
	var icon_red := randf() > 0.5
	var left_cube  := _make_cube(Vector2(arena_left + 34.0, arena_floor - 20.0), Vector2(30, 40), Color(0.9, 0.1, 0.1))
	var right_cube := _make_cube(Vector2(arena_right - 34.0, arena_floor - 20.0), Vector2(30, 40), Color(0.85, 0.85, 0.9))
	# Indicador do ícone acima do boss
	var icon := _make_cube(global_position + Vector2(0, -30), Vector2(14, 14),
		Color(0.9, 0.1, 0.1) if icon_red else Color(0.85, 0.85, 0.9))

	# TODO: detecção real de "atacar a cor errada reflete dano" precisa de hook no player.
	# Placeholder: o lado válido é o da cor oposta ao ícone; counter no lado certo passa.
	var valid_x : float = (arena_right - 34.0) if icon_red else (arena_left + 34.0)
	var valid := func() -> bool:
		return _player != null and abs(_player.global_position.x - valid_x) < 140.0
	var ok := await _await_counter(5.0, valid)
	if not ok and _alive() and _player:
		_player.take_damage(2000.0)   # refletiu / errou

	left_cube.queue_free()
	right_cube.queue_free()
	icon.queue_free()


# ─────────────────────────────────────────────────────────────────────────
# FASE FINAL — ZERO ABSOLUTO (enrage / DPS check 15.000 em 40s)
# ─────────────────────────────────────────────────────────────────────────
func _phase_final() -> void:
	_banner("FASE FINAL: O Zero Absoluto", Color(0.85, 0.95, 1.0))
	_set_body(false, Color(0.7, 0.95, 1.0))   # gelo
	await _move_to(_arena_center() + Vector2(0, -30), 240.0)

	# Nevasca visual (cubo translúcido cobrindo a arena)
	var blizzard := _make_cube(_arena_center(), Vector2(arena_right - arena_left, arena_floor - arena_top), Color(1, 1, 1, 0.22))

	var hp_start := current_hp
	var dt := get_physics_process_delta_time()
	var t := 0.0
	var hypo_cd := 0.0
	var knife_cd := 0.0
	var cut_cd := 0.0
	var success := false

	while _alive() and t < 40.0:
		t += dt
		# Hipotermia: 2% do HP máx do player por segundo
		hypo_cd -= dt
		if hypo_cd <= 0.0 and _player and is_instance_valid(_player):
			hypo_cd = 1.0
			var pmax : float = _player.get("max_health")
			_player.take_damage(pmax * 0.02)
		# Facas constantes
		knife_cd -= dt
		if knife_cd <= 0.0:
			knife_cd = 1.3
			_atk_facas_ricochete()
		# Linhas de corte aleatórias
		cut_cd -= dt
		if cut_cd <= 0.0:
			cut_cd = 1.8
			var y := randf_range(arena_top + 30.0, arena_floor - 12.0)
			_spawn_hazard(Vector2(_arena_center().x, y),
				Vector2(arena_right - arena_left, 10.0), Color(1, 0, 0),
				2500.0, 0.7, 0.2)

		if (hp_start - current_hp) >= 15_000.0:
			success = true
			break
		await get_tree().physics_frame

	if is_instance_valid(blizzard): blizzard.queue_free()

	if success:
		_die()
	elif _alive():
		_wipe()   # tempo acabou -> estilhaça (wipe)


# =============================================================================
# DANO / STAGGER / MORTE
# =============================================================================
func take_damage(amount: float) -> void:
	if state == State.DEAD:
		return
	if not is_immune:
		current_hp = max(0.0, current_hp - amount)
		EventBus.boss_health_updated.emit(current_hp)
	# Stagger acumula sempre (inclusive nas transições, que são gates de stagger)
	_add_stagger(amount * 0.5)


func _add_stagger(amount: float) -> void:
	stagger = min(MAX_STAGGER, stagger + amount)
	EventBus.boss_stagger_updated.emit(stagger, MAX_STAGGER)


func _reset_stagger() -> void:
	stagger = 0.0
	EventBus.boss_stagger_updated.emit(0.0, MAX_STAGGER)


func _die() -> void:
	state = State.DEAD
	current_hp = 0.0
	EventBus.boss_health_updated.emit(0.0)
	EventBus.boss_staggered.emit()
	_set_color(Color(0.2, 0.2, 0.2))
	await _sleep(1.0)
	queue_free()


func _wipe() -> void:
	# Punição de falha de check (Hit Kill / Wipe)
	if _player and is_instance_valid(_player):
		_player.take_damage(999999.0)


# =============================================================================
# HELPERS
# =============================================================================
func _alive() -> bool:
	return state != State.DEAD and is_inside_tree()


func _sleep(t: float) -> void:
	await get_tree().create_timer(t).timeout


func _between_attacks(t: float) -> void:
	await _sleep(t)


# Move o boss até um alvo (corrotina).
func _move_to(target: Vector2, speed: float) -> void:
	var dt := get_physics_process_delta_time()
	while _alive() and global_position.distance_to(target) > 2.0:
		global_position = global_position.move_toward(target, speed * dt)
		await get_tree().physics_frame


# Aguarda um counter válido dentro de uma janela. `valid` é um Callable -> bool.
func _await_counter(window: float, valid: Callable) -> bool:
	_counter_flag = false
	var dt := get_physics_process_delta_time()
	var t := 0.0
	while _alive() and t < window:
		if _counter_flag:
			_counter_flag = false
			if valid.call():
				return true
		t += dt
		await get_tree().physics_frame
	return false


# Cria um cubo de perigo (telegrafo -> ativo -> some).
func _spawn_hazard(pos: Vector2, size: Vector2, color: Color, damage: float,
		telegraph: float, active: float, tick: float = 0.0,
		respect_dash: bool = true, instakill: bool = false) -> Node:
	var h = HAZARD.new()
	h.setup(size, color, damage, telegraph, active, tick, respect_dash, instakill)
	get_parent().add_child(h)
	h.global_position = pos
	return h


# Cubo puramente visual (sem dano).
func _make_cube(pos: Vector2, size: Vector2, color: Color) -> Node2D:
	var root := Node2D.new()
	var rect := ColorRect.new()
	rect.size = size
	rect.position = -size * 0.5
	rect.color = color
	root.add_child(rect)
	get_parent().add_child(root)
	root.global_position = pos
	return root


func _arena_center() -> Vector2:
	return Vector2((arena_left + arena_right) * 0.5, (arena_top + arena_floor) * 0.5)


func _arena_rect() -> Rect2:
	return Rect2(arena_left, arena_top, arena_right - arena_left, arena_floor - arena_top)


func _idle_pos() -> Vector2:
	return Vector2((arena_left + arena_right) * 0.5, arena_floor - hover_height)


# Troca a "forma" do boss: arte (chapéu) ou cubo de cor por fase.
# Se não houver arte, sempre mostra o cubo. `color` só é usado quando o cubo aparece.
func _set_body(use_art: bool, color: Color) -> void:
	var show_art := use_art and _anim != null
	if _anim:
		_anim.visible = show_art
		_anim.modulate = Color.WHITE
	if _body_cube:
		_body_cube.visible = not show_art
		if not show_art:
			_body_cube.color = color


# Tinta momentânea (brilho de counter, morte) na forma atualmente visível.
func _set_color(c: Color) -> void:
	if _anim and _anim.visible:
		_anim.modulate = c
	if _body_cube and _body_cube.visible:
		_body_cube.color = c


func _play_anim(anim_name: String) -> void:
	if not _anim:
		return
	if _anim.sprite_frames and _anim.sprite_frames.has_animation(anim_name):
		_anim.play(anim_name)


func _banner(text: String, c: Color) -> void:
	print("[Silvanna] >>> ", text)
	# Tinta só o cubo placeholder; a arte (AnimatedSprite2D) fica na cor natural.
	if _rect:
		_rect.color = c
	if _anim:
		_anim.modulate = Color.WHITE
