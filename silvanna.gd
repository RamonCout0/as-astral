# silvanna.gd
# ============================================================================
# BOSS: Silvanna, a Maga de Prata  —  luta completa (Armateus + Silvanna)
# ----------------------------------------------------------------------------
# UM boss só, HP único, dirigido por limiares de HP:
#   FASE 1  (304x -> 280x)  Armateus chapéu : Pêndulo, Varredura, Chuva de Gelo
#   TRANS 1 (280x)          Vórtice de Sucção  (gate de stagger)
#   FASE 2  (280x -> 192x)  Armateus lâmina : Corte Fantasma, Duelo, Chuva de Espadas
#   TRANS 2 (192x)          Fortificando a Neve (lasers + gate de stagger)
#   FASE 3  (192x -> 15x)   Silvanna : Facas, Mãos de Dragão, Vassoura(175x), Espelhos(140x)
#   FINAL   (15x -> 0)      Zero Absoluto : DPS check
#
# >>> COMO TROCAR OS PLACEHOLDERS E CONFIGURAR: veja Entidades/Silvana/COMO_USAR.md
# ============================================================================
extends CharacterBody2D

# --- ARENA --------------------------------------------------------------------
@export_group("Arena")
@export var arena_left  : float = 16.0
@export var arena_right : float = 464.0
@export var arena_top   : float = 16.0
@export var arena_floor : float = 252.0
## Altura em que o boss flutua parado, ACIMA do chão. Menor = mais perto do chão.
@export var hover_height : float = 40.0
## Velocidade de deslocamento do boss entre posições.
@export var move_speed : float = 260.0

# --- ÁUDIO --------------------------------------------------------------------
@export_group("Áudio")
## Música das fases iniciais (Armateus). Vazio = usa a que já estiver tocando na cena.
@export var initial_music : AudioStream
## Música que toca quando a SILVANNA surge (Transição 2). Arraste o arquivo aqui.
@export var silvanna_music : AudioStream
## (Opcional) AudioStreamPlayer cuja faixa será trocada. Vazio = acha sozinho na cena.
@export var music_player : NodePath
## Duração do crossfade (s) entre a música antiga e a da Silvanna.
@export var music_fade_time : float = 2.5

# --- VIDA / STAGGER -----------------------------------------------------------
@export_group("Vida e Stagger")
@export var max_hp      : float = 304_000.0
@export var hp_per_bar  : float = 1_000.0
@export var max_stagger : float = 5_000.0
## Quanto de stagger some por segundo quando o boss não está em transição.
@export var stagger_decay : float = 250.0
## Tempo (s) que o boss fica atordoado ao QUEBRAR o stagger.
@export var stagger_stun_time : float = 4.0
## Multiplicador de dano enquanto o boss está atordoado (quebra de stagger).
@export var stagger_stun_dmg_mult : float = 2.0

# --- LIMIARES DE FASE (HP) ----------------------------------------------------
@export_group("Limiares de Fase (HP)")
@export var th_trans1   : float = 280_000.0
@export var th_trans2   : float = 192_000.0
@export var th_vassoura : float = 175_000.0
@export var th_espelhos : float = 140_000.0
@export var th_final    : float =  15_000.0

# --- RITMO --------------------------------------------------------------------
@export_group("Ritmo (pausa entre ataques)")
@export var pause_fase1 : float = 1.2
@export var pause_fase2 : float = 1.0
@export var pause_fase3 : float = 1.4

# --- PÊNDULO ------------------------------------------------------------------
@export_group("Ataque: Pêndulo")
## Maior = arco mais rápido.
@export var pendulo_speed  : float = 1.8
@export var pendulo_damage : float = 2_000.0
@export var pendulo_range  : float = 30.0
@export var pendulo_dmg_interval : float = 0.3   # intervalo entre danos do pêndulo

# --- VARREDURA ESCARLATE ------------------------------------------------------
@export_group("Ataque: Varredura Escarlate")
@export var laser_telegraph : float = 0.8
@export var laser_speed     : float = 170.0
@export var laser_damage    : float = 1_800.0
@export var skin_laser      : PackedScene

# --- CHUVA DE GELO ------------------------------------------------------------
@export_group("Ataque: Chuva de Gelo")
@export var gelo_count    : int   = 3
@export var gelo_duration : float = 25.0
@export var skin_gelo     : PackedScene

# --- CORTE FANTASMA -----------------------------------------------------------
@export_group("Ataque: Corte Fantasma")
@export var corte_telegraph : float = 0.8
@export var corte_active    : float = 0.2
@export var corte_damage    : float = 2_800.0
@export var skin_corte      : PackedScene

# --- DUELO DE SOMBRAS ---------------------------------------------------------
@export_group("Ataque: Duelo de Sombras")
@export var duelo_window : float = 0.8
@export var duelo_damage : float = 2_500.0

# --- CHUVA DE ESPADAS ---------------------------------------------------------
@export_group("Ataque: Chuva de Espadas")
@export var espadas_telegraph : float = 1.0
@export var espadas_active    : float = 0.5
@export var espadas_damage    : float = 3_000.0
@export var espadas_gaps      : int   = 2
@export var skin_espada       : PackedScene

# --- VÓRTICE (TRANSIÇÃO 1) ----------------------------------------------------
@export_group("Transição 1: Vórtice")
@export var vortice_time : float = 25.0
@export var vortice_pull : float = 200.0
## Stagger necessário pra QUEBRAR o vórtice no tempo (senão é wipe).
@export var vortice_stagger : float = 5_000.0
@export var skin_nucleo  : PackedScene

# --- LASERS DE ESPELHO (TRANSIÇÃO 2) ------------------------------------------
@export_group("Transição 2: Lasers de Espelho")
@export var trans2_time            : float = 20.0
## Stagger necessário pra QUEBRAR a transição no tempo (senão é wipe).
@export var trans2_stagger         : float = 5_000.0
@export var espelho_laser_telegraph: float = 0.8
@export var espelho_laser_active   : float = 0.5
@export var espelho_laser_damage   : float = 1_500.0
@export var espelho_laser_interval : float = 1.1
@export var skin_espelho_laser     : PackedScene

# --- FACAS / DRAGÃO -----------------------------------------------------------
@export_group("Ataque: Facas de Ricochete")
@export var facas_count   : int   = 5
@export var facas_spread  : float = 80.0     # ângulo (graus) do leque
@export var faca_speed    : float = 380.0
@export var faca_damage   : float = 800.0
@export var faca_bounces  : int   = 3        # quantos quiques antes de sumir
@export var faca_lifetime : float = 6.0
@export var skin_faca     : PackedScene

@export_group("Ataque: Mãos de Dragão")
@export var dragao_count : int = 1          # quantas spawnam por ataque
@export var dragao_max   : int = 2          # máximo simultâneo na arena
@export var dragao_speed : float = 130.0
@export var dragao_damage : float = 1_200.0
@export var dragao_lifetime : float = 5.0
@export var dragao_counter_range : float = 130.0   # alcance pra destruir com counter
@export var skin_dragao  : PackedScene

# --- VASSOURA / ESPELHOS GÊMEOS -----------------------------------------------
@export_group("Evento: Vassoura (175x)")
@export var vassoura_wind           : float = 240.0
@export var vassoura_time           : float = 3.0
@export var vassoura_counter_window : float = 1.2
@export var vassoura_damage         : float = 3_000.0
@export var skin_espinho            : PackedScene

@export_group("Evento: Espelhos Gêmeos (140x)")
@export var espelhos_window : float = 5.0
@export var espelhos_damage : float = 2_000.0

# --- FASE FINAL ---------------------------------------------------------------
@export_group("Fase Final: Zero Absoluto")
@export var final_time          : float = 40.0
@export var final_dps_check     : float = 15_000.0
@export var hipotermia_pct      : float = 0.02
@export var final_knife_interval: float = 1.3
@export var final_cut_interval  : float = 1.8
## Cena opcional de nevasca (tela cheia). Se vazio, usa o shader de neve interno.
@export var skin_blizzard       : PackedScene
## Intensidade da neve no shader interno (densidade de partículas).
@export var blizzard_density    : float = 320.0


# --- ESTADO -------------------------------------------------------------------
enum State { INTRO, FIGHT, STAGGERED, DEAD }
var state : State = State.INTRO

var current_hp : float = 0.0
var stagger    : float = 0.0
var _stagger_cap : float = 5_000.0   # teto/meta atual do stagger (muda nas transições)
var is_immune  : bool  = false

var _did_vassoura := false
var _did_espelhos := false
var _counter_flag := false
var _stun_pending := false
var _flashing     := false

# --- FORMAS (sprites por fase) ------------------------------------------------
# Adicione nós-filho com estes nomes para usar SEUS sprites (veja COMO_USAR.md):
#   Forma_Chapeu, Forma_Lamina, Forma_Bruxa, Forma_Final
var _forms        : Dictionary = {}
var _cur_form     : Node = null
var _cur_form_key : String = ""
var _cur_cube_color : Color = Color.WHITE
var _rect      : ColorRect = null
var _body_cube : ColorRect = null
var _player    : CharacterBody2D = null

const HAZARD := preload("res://Entidades/Silvana/silvanna_hazard.gd")
const KNIFE  := preload("res://Entidades/Silvana/silvanna_knife.gd")
const DRAGON := preload("res://Entidades/Silvana/silvanna_dragon_hand.gd")
const SNOW_SHADER   := preload("res://Shaders_Efeitos/tempestade_neve.gdshader")
const PERIGO_SHADER := preload("res://Shaders_Efeitos/perigo.gdshader")
const NUCLEO_FX     := preload("res://Entidades/Silvana/nucleo_fx.tscn")
const VENTO_SHADER  := preload("res://Shaders_Efeitos/vento.gdshader")


# =============================================================================
# INIT
# =============================================================================
func _ready() -> void:
	randomize()
	add_to_group("boss")

	_forms = {
		"chapeu": get_node_or_null("Forma_Chapeu"),
		"lamina": get_node_or_null("Forma_Lamina"),
		"bruxa":  get_node_or_null("Forma_Bruxa"),
		"final":  get_node_or_null("Forma_Final"),
	}
	if _forms["chapeu"] == null:
		_forms["chapeu"] = get_node_or_null("AnimatedSprite2D")
	for k in _forms:
		if _forms[k]:
			_forms[k].visible = false

	_rect = get_node_or_null("Sprite")
	if _rect:
		_body_cube = _rect
	else:
		_body_cube = ColorRect.new()
		_body_cube.size     = Vector2(44.0, 44.0)
		_body_cube.position = Vector2(-22.0, -22.0)
		add_child(_body_cube)
	_body_cube.visible = false

	_player = get_tree().get_first_node_in_group("player")
	if _player == null:
		push_warning("[Silvanna] Player não encontrado no grupo 'player'!")

	current_hp = max_hp
	_stagger_cap = max_stagger
	EventBus.boss_max_health_set.emit(max_hp, hp_per_bar)
	EventBus.boss_stagger_updated.emit(0.0, _stagger_cap)

	if EventBus.has_signal("player_counter_pressed"):
		EventBus.player_counter_pressed.connect(func(): _counter_flag = true)

	global_position = _idle_pos()
	_set_body("chapeu", Color(0.6, 0.1, 0.1))
	_play_anim("idle")

	_play_initial_music()
	_fight()


func _physics_process(delta: float) -> void:
	if state == State.DEAD:
		return
	# Decaimento natural do stagger (só na luta normal, não em transição/atordoado)
	if state == State.FIGHT and not is_immune and stagger > 0.0:
		stagger = max(0.0, stagger - stagger_decay * delta)
		EventBus.boss_stagger_updated.emit(stagger, _stagger_cap)


# =============================================================================
# CORROTINA MESTRA
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
# FASE 1 — CHAPÉU
# ─────────────────────────────────────────────────────────────────────────
func _phase_1() -> void:
	_banner("FASE 1: O Prelúdio")
	_set_body("chapeu", Color(0.6, 0.1, 0.1))
	var i := 0
	while _alive() and current_hp > th_trans1:
		match i % 3:
			0:
				await _atk_pendulo()
			1:
				await _atk_varredura_escarlate()
			2:
				await _atk_chuva_de_gelo()
		i += 1
		await _after_attack(pause_fase1)


func _atk_pendulo() -> void:
	var from_left := randf() > 0.5
	var start := Vector2(arena_left + 16.0 if from_left else arena_right - 16.0, arena_top + 16.0)
	var end_x : float = clampf(_player.global_position.x, arena_left, arena_right) if _player else _arena_center().x
	var peak := arena_floor - 6.0

	await _move_to(start, move_speed)
	if not _alive(): return

	_play_anim("attack")
	var t := 0.0
	var dmg_cd := 0.0
	var dt := get_physics_process_delta_time()
	while _alive() and t < 1.0:
		t += dt * pendulo_speed
		var tt := clampf(t, 0.0, 1.0)
		var x := lerpf(start.x, end_x, tt)
		var curve := pow(sin(tt * PI), 0.6)
		var y := lerpf(start.y, peak, curve)
		global_position = Vector2(clampf(x, arena_left, arena_right), clampf(y, arena_top, arena_floor))

		dmg_cd -= dt
		if _player and is_instance_valid(_player):
			if global_position.distance_to(_player.global_position) < pendulo_range and dmg_cd <= 0.0 and not _player.get("is_dashing"):
				_player.take_damage(pendulo_damage)
				dmg_cd = pendulo_dmg_interval
		await get_tree().physics_frame

	_play_anim("idle")
	await _move_to(_idle_pos(), move_speed)


func _atk_varredura_escarlate() -> void:
	var from_left := randf() > 0.5
	var corner := Vector2(arena_left + 16.0 if from_left else arena_right - 16.0, arena_top + 16.0)
	await _move_to(corner, move_speed)
	if not _alive(): return

	_play_anim("laser_warn")
	var beam_root := Node2D.new()
	var beam : ColorRect = null
	if skin_laser:
		beam_root.add_child(skin_laser.instantiate())
	else:
		beam = ColorRect.new()
		beam.size     = Vector2(6.0, arena_floor - arena_top)
		beam.position = Vector2(-3.0, 0.0)
		beam.color    = Color(1.0, 0.1, 0.05, 0.35)
		var bmat := ShaderMaterial.new()
		bmat.shader = PERIGO_SHADER
		beam.material = bmat
		beam_root.add_child(beam)
	get_parent().add_child(beam_root)
	var x := corner.x
	beam_root.global_position = Vector2(x, arena_top)

	await _sleep(laser_telegraph)
	if not _alive():
		beam_root.queue_free(); return
	_play_anim("laser_fire")
	if beam:
		beam.color = Color(1.0, 0.1, 0.05, 0.9)

	var target_x : float = _player.global_position.x if _player else _arena_center().x
	var dir : float = signf(target_x - x)
	if dir == 0.0: dir = 1.0

	var dt := get_physics_process_delta_time()
	while _alive():
		x += dir * laser_speed * dt
		beam_root.global_position.x = x
		if _player and is_instance_valid(_player):
			if absf(_player.global_position.x - x) < 10.0 and not _player.get("is_dashing"):
				_player.take_damage(laser_damage)
		if x <= arena_left + 8.0 or x >= arena_right - 8.0:
			break
		await get_tree().physics_frame

	beam_root.queue_free()


func _atk_chuva_de_gelo() -> void:
	await _move_to(_idle_pos(), move_speed)
	for n in gelo_count:
		var px := randf_range(arena_left + 30.0, arena_right - 30.0)
		# TODO: gelo deveria reduzir o atrito do player (precisa de hook no player.gd)
		_spawn_hazard(Vector2(px, arena_floor - 6.0), Vector2(56.0, 12.0),
			Color(0.4, 0.8, 1.0), 0.0, 0.5, gelo_duration, 0.0, true, false, skin_gelo)
		await _sleep(0.25)


# ─────────────────────────────────────────────────────────────────────────
# TRANSIÇÃO 1 — VÓRTICE
# ─────────────────────────────────────────────────────────────────────────
func _trans_1() -> void:
	_banner("TRANSIÇÃO 1: O Vórtice de Sucção")
	is_immune = true
	await _move_to(Vector2(_arena_center().x, arena_floor - 20.0), move_speed)
	_hide_body()   # esconde o chapéu — o sprite do núcleo (vórtice) é o visual aqui
	_stagger_cap = vortice_stagger
	_reset_stagger()

	var wind := _spawn_wind()   # vendaval convergindo pro centro (atrás do núcleo)

	# Núcleo letal: coluna de altura total no centro. Encostar no centro = morte.
	var core := _spawn_hazard(
		Vector2(_arena_center().x, (arena_top + arena_floor) * 0.5),
		Vector2(44.0, arena_floor - arena_top),
		Color(0.6, 0.0, 0.8),
		0.0, 0.3, vortice_time + 5.0, 0.0, false, true, skin_nucleo if skin_nucleo else NUCLEO_FX)

	var dt := get_physics_process_delta_time()
	var t := 0.0
	var success := false
	while _alive() and t < vortice_time:
		t += dt
		if _player and is_instance_valid(_player):
			_player.global_position.x = move_toward(_player.global_position.x, _arena_center().x, vortice_pull * dt)
		if stagger >= _stagger_cap:
			success = true
			break
		await get_tree().physics_frame

	if is_instance_valid(core): core.queue_free()
	if is_instance_valid(wind): wind.queue_free()
	if not success and _alive():
		_wipe()
	_stagger_cap = max_stagger
	_reset_stagger()
	is_immune = false


# ─────────────────────────────────────────────────────────────────────────
# FASE 2 — LÂMINA
# ─────────────────────────────────────────────────────────────────────────
func _phase_2() -> void:
	_banner("FASE 2: A Lâmina Sombria")
	_set_body("lamina", Color(0.2, 0.3, 0.9))
	var i := 0
	while _alive() and current_hp > th_trans2:
		match i % 3:
			0:
				await _atk_corte_fantasma()
			1:
				await _atk_duelo_de_sombras()
			2:
				await _atk_chuva_de_espadas()
		i += 1
		await _after_attack(pause_fase2)


func _atk_corte_fantasma() -> void:
	await _move_to(Vector2(arena_left + 12.0, arena_floor - 30.0), move_speed * 1.25)
	_play_anim("attack")
	var low := randf() > 0.5
	var y : float = (arena_floor - 12.0) if low else (arena_floor - 60.0)
	_spawn_hazard(Vector2(_arena_center().x, y), Vector2(arena_right - arena_left, 10.0),
		Color(1.0, 0.0, 0.0), corte_damage, corte_telegraph, corte_active, 0.0, true, false, skin_corte)
	await _sleep(corte_telegraph + corte_active + 0.2)


func _atk_duelo_de_sombras() -> void:
	var real_left := randf() > 0.5
	var lx := arena_left + 34.0
	var rx := arena_right - 34.0
	var real_x : float = lx if real_left else rx

	var clone_l := _make_cube(Vector2(lx, arena_floor - 20.0), Vector2(30, 40), Color(0.1, 0.3, 1.0) if real_left else Color(0.3, 0.3, 0.3))
	var clone_r := _make_cube(Vector2(rx, arena_floor - 20.0), Vector2(30, 40), Color(0.1, 0.3, 1.0) if not real_left else Color(0.3, 0.3, 0.3))

	var valid := func() -> bool:
		return _player != null and absf(_player.global_position.x - real_x) < 140.0
	var ok := await _await_counter(duelo_window, valid)

	if ok:
		_parry_feedback()
		add_stagger(max_stagger * 0.4)   # recompensa por acertar o counter
	elif _alive() and _player:
		_player.take_damage(duelo_damage)

	clone_l.queue_free()
	clone_r.queue_free()


func _atk_chuva_de_espadas() -> void:
	await _move_to(_arena_center() + Vector2(0, -50), move_speed)
	var step := 38.0
	var n := int((arena_right - arena_left) / step)
	var gaps := {}
	var safety := 0
	while gaps.size() < mini(espadas_gaps, n) and safety < 50:
		gaps[randi() % n] = true
		safety += 1
	for c in n:
		if gaps.has(c):
			continue
		var cx := arena_left + step * 0.5 + c * step
		_spawn_hazard(Vector2(cx, (arena_top + arena_floor) * 0.5), Vector2(24.0, arena_floor - arena_top),
			Color(0.8, 0.1, 0.1), espadas_damage, espadas_telegraph, espadas_active, 0.0, true, false, skin_espada)
	await _sleep(espadas_telegraph + espadas_active + 0.5)


# ─────────────────────────────────────────────────────────────────────────
# TRANSIÇÃO 2 — LASERS DE ESPELHO
# ─────────────────────────────────────────────────────────────────────────
func _trans_2() -> void:
	_banner("TRANSIÇÃO 2: A Fúria da Bruxa")
	_set_body("bruxa", Color(0.0, 0.5, 0.6))
	_switch_to_silvanna_music()   # <<< troca de música ao surgir a Silvanna
	is_immune = true
	await _move_to(_idle_pos(), move_speed)   # ao alcance do melee
	_stagger_cap = trans2_stagger
	_reset_stagger()
	# is_immune fica TRUE durante o gate: HP congelado e stagger NÃO decai.

	var dt := get_physics_process_delta_time()
	var t := 0.0
	var laser_cd := 0.0
	var success := false
	while _alive() and t < trans2_time:
		t += dt
		laser_cd -= dt
		if laser_cd <= 0.0:
			laser_cd = espelho_laser_interval
			# alturas dentro da zona de jogo (perto do chão), não no topo da arena
			var h := randf_range(arena_floor - 130.0, arena_floor - 8.0)
			# Desvie pulando/agachando OU com dash (I-frame).
			_spawn_hazard(Vector2(_arena_center().x, h), Vector2(arena_right - arena_left, 8.0),
				Color(1.0, 0.2, 0.2), espelho_laser_damage, espelho_laser_telegraph,
				espelho_laser_active, 0.0, true, false, skin_espelho_laser)
		if stagger >= _stagger_cap:
			success = true
			break
		await get_tree().physics_frame

	if not success and _alive():
		_wipe()
	_stagger_cap = max_stagger
	_reset_stagger()
	is_immune = false


# ─────────────────────────────────────────────────────────────────────────
# FASE 3 — TEMPESTADE
# ─────────────────────────────────────────────────────────────────────────
func _phase_3() -> void:
	_banner("FASE 3: A Tempestade Prateada")
	_set_body("bruxa", Color(0.85, 0.85, 0.95))
	var i := 0
	while _alive() and current_hp > th_final:
		if not _did_vassoura and current_hp <= th_vassoura:
			_did_vassoura = true
			await _event_vassoura()
			continue
		if not _did_espelhos and current_hp <= th_espelhos:
			_did_espelhos = true
			await _event_espelhos_gemeos()
			continue

		if i % 2 == 0:
			await _atk_facas_ricochete()
		else:
			await _atk_maos_de_dragao()
		i += 1
		await _after_attack(pause_fase3)


func _atk_facas_ricochete() -> void:
	var base := (_player.global_position - global_position).angle() if _player else 0.0
	for k in facas_count:
		var frac := (float(k) / float(maxi(1, facas_count - 1))) - 0.5
		var ang := base + deg_to_rad(facas_spread * frac)
		var knife := KNIFE.new()
		knife.set_meta("direction", Vector2.RIGHT.rotated(ang))
		knife.set_meta("arena", _arena_rect())
		knife.set_meta("speed", faca_speed)
		knife.set_meta("damage", faca_damage)
		knife.set_meta("bounces", faca_bounces)
		knife.set_meta("lifetime", faca_lifetime)
		if skin_faca:
			knife.set_meta("skin", skin_faca)
		get_parent().add_child(knife)
		knife.global_position = global_position
	await _sleep(0.4)


func _atk_maos_de_dragao() -> void:
	for h in dragao_count:
		# Não passa do máximo simultâneo (evita spam impossível).
		if get_tree().get_nodes_in_group("dragon_hand").size() >= dragao_max:
			break
		var hand := DRAGON.new()
		hand.set_meta("speed", dragao_speed)
		hand.set_meta("damage", dragao_damage)
		hand.set_meta("lifetime", dragao_lifetime)
		hand.set_meta("counter_range", dragao_counter_range)
		if skin_dragao:
			hand.set_meta("skin", skin_dragao)
		get_parent().add_child(hand)
		hand.global_position = Vector2(randf_range(arena_left + 30.0, arena_right - 30.0), arena_floor - 14.0)
		await _sleep(0.6)
	await _sleep(2.5)


func _event_vassoura() -> void:
	_banner("Vassoura Empurradora")
	await _move_to(Vector2(arena_right - 20.0, arena_floor - 20.0), move_speed)
	var spikes := _spawn_hazard(Vector2(arena_left + 8.0, (arena_top + arena_floor) * 0.5),
		Vector2(16.0, arena_floor - arena_top), Color(0.7, 0.7, 0.7),
		0.0, 0.3, vassoura_time + 3.0, 0.0, false, true, skin_espinho)

	var dt := get_physics_process_delta_time()
	var t := 0.0
	while _alive() and t < vassoura_time:
		t += dt
		if _player and is_instance_valid(_player):
			_player.global_position.x += vassoura_wind * dt
		await get_tree().physics_frame

	_set_color(Color(1.0, 1.0, 0.4))   # brilha = janela de counter
	var valid := func() -> bool:
		return _player != null and _player.global_position.x > _arena_center().x
	var ok := await _await_counter(vassoura_counter_window, valid)
	if ok:
		_parry_feedback()
		_stun_pending = true   # rebateu -> atordoa
	elif _alive() and _player:
		_player.take_damage(vassoura_damage)

	if is_instance_valid(spikes): spikes.queue_free()
	_set_body("bruxa", Color(0.85, 0.85, 0.95))
	await _check_stun()


func _event_espelhos_gemeos() -> void:
	_banner("Os Espelhos Gêmeos")
	await _move_to(_arena_center(), move_speed)
	var icon_red := randf() > 0.5
	var left_cube  := _make_cube(Vector2(arena_left + 34.0, arena_floor - 20.0), Vector2(30, 40), Color(0.9, 0.1, 0.1))
	var right_cube := _make_cube(Vector2(arena_right - 34.0, arena_floor - 20.0), Vector2(30, 40), Color(0.85, 0.85, 0.9))
	var icon := _make_cube(global_position + Vector2(0, -30), Vector2(14, 14), Color(0.9, 0.1, 0.1) if icon_red else Color(0.85, 0.85, 0.9))

	# Placeholder: lado válido = cor oposta ao ícone (counter no lado certo passa).
	var valid_x : float = (arena_right - 34.0) if icon_red else (arena_left + 34.0)
	var valid := func() -> bool:
		return _player != null and absf(_player.global_position.x - valid_x) < 140.0
	var ok := await _await_counter(espelhos_window, valid)
	if ok:
		_parry_feedback()
	elif _alive() and _player:
		_player.take_damage(espelhos_damage)

	left_cube.queue_free()
	right_cube.queue_free()
	icon.queue_free()


# ─────────────────────────────────────────────────────────────────────────
# FASE FINAL
# ─────────────────────────────────────────────────────────────────────────
func _phase_final() -> void:
	_banner("FASE FINAL: O Zero Absoluto")
	_set_body("final", Color(0.7, 0.95, 1.0))
	await _move_to(_idle_pos(), move_speed)   # ao alcance do melee (DPS check)

	var blizzard := _spawn_blizzard()

	# Pool de enrage: a vida vira exatamente o DPS check. Vence quem zerar em final_time.
	current_hp = final_dps_check
	EventBus.boss_health_updated.emit(current_hp)

	var dt := get_physics_process_delta_time()
	var t := 0.0
	var hypo_cd := 0.0
	var knife_cd := 0.0
	var cut_cd := 0.0
	var success := false

	while _alive() and t < final_time:
		t += dt
		hypo_cd -= dt
		if hypo_cd <= 0.0 and _player and is_instance_valid(_player):
			hypo_cd = 1.0
			var pmax : float = _player.get("max_health")
			_player.take_damage(pmax * hipotermia_pct)
		knife_cd -= dt
		if knife_cd <= 0.0:
			knife_cd = final_knife_interval
			_atk_facas_ricochete()
		cut_cd -= dt
		if cut_cd <= 0.0:
			cut_cd = final_cut_interval
			var y := randf_range(arena_floor - 130.0, arena_floor - 12.0)
			_spawn_hazard(Vector2(_arena_center().x, y), Vector2(arena_right - arena_left, 10.0),
				Color(1, 0, 0), corte_damage, 0.7, 0.2, 0.0, true, false, skin_corte)
		if current_hp <= 0.0:
			success = true
			break
		await get_tree().physics_frame

	if is_instance_valid(blizzard): blizzard.queue_free()
	if success:
		_die()
	elif _alive():
		_wipe()


# =============================================================================
# DANO / STAGGER / MORTE
# =============================================================================
func take_damage(amount: float) -> void:
	if state == State.DEAD:
		return
	var amt := amount
	if state == State.STAGGERED:
		amt *= stagger_stun_dmg_mult   # leva mais dano enquanto atordoado
	if not is_immune:
		current_hp = max(0.0, current_hp - amt)
		EventBus.boss_health_updated.emit(current_hp)
		_flash(Color(1.0, 0.5, 0.5))   # feedback de dano
	# O stagger vem do golpe do player (add_stagger), não automático daqui.


# Público: o player chama isto junto do dano base para encher a barra de stagger.
func add_stagger(amount: float) -> void:
	if state == State.DEAD or state == State.STAGGERED:
		return
	stagger = min(_stagger_cap, stagger + amount)
	EventBus.boss_stagger_updated.emit(stagger, _stagger_cap)
	if stagger >= _stagger_cap and not is_immune and state == State.FIGHT:
		_stun_pending = true


func _reset_stagger() -> void:
	stagger = 0.0
	EventBus.boss_stagger_updated.emit(0.0, _stagger_cap)


# Quebra de stagger -> atordoamento (janela de dano dobrado).
func _check_stun() -> void:
	if _stun_pending and _alive():
		await _do_stun()


func _do_stun() -> void:
	_stun_pending = false
	state = State.STAGGERED
	EventBus.boss_staggered.emit()
	_play_anim("staggered")
	_set_color(Color(1.0, 1.0, 0.2))   # amarelo = atordoado

	var dt := get_physics_process_delta_time()
	var t := 0.0
	while _alive() and state == State.STAGGERED and t < stagger_stun_time:
		t += dt
		await get_tree().physics_frame

	if state == State.STAGGERED:
		state = State.FIGHT
	_reset_stagger()
	_restore_body_color()
	_play_anim("idle")


func _die() -> void:
	state = State.DEAD
	current_hp = 0.0
	EventBus.boss_health_updated.emit(0.0)
	_set_color(Color(0.2, 0.2, 0.2))
	await _sleep(1.0)
	queue_free()


func _wipe() -> void:
	if _player and is_instance_valid(_player):
		_player.take_damage(999999.0)


# Feedback visual de parry/counter bem-sucedido (mais forte que o flash de dano).
func _parry_feedback() -> void:
	_flashing = true
	_set_color(Color(0.4, 0.85, 1.0))
	await _sleep(0.18)
	_restore_body_color()
	_flashing = false


func _flash(c: Color) -> void:
	if _flashing:
		return
	_flashing = true
	_set_color(c)
	await _sleep(0.08)
	_restore_body_color()
	_flashing = false


# =============================================================================
# HELPERS
# =============================================================================
func _alive() -> bool:
	return state != State.DEAD and is_inside_tree()


func _sleep(t: float) -> void:
	await get_tree().create_timer(t).timeout


# Pausa entre ataques + checa quebra de stagger.
func _after_attack(t: float) -> void:
	_play_anim("idle")
	await _check_stun()
	await _sleep(t)


func _move_to(target: Vector2, speed: float) -> void:
	var dt := get_physics_process_delta_time()
	while _alive() and global_position.distance_to(target) > 2.0:
		global_position = global_position.move_toward(target, speed * dt)
		await get_tree().physics_frame


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


# Cria um perigo (telegrafo -> ativo -> some). `skin` opcional troca o cubo por arte.
func _spawn_hazard(pos: Vector2, size: Vector2, color: Color, damage: float,
		telegraph: float, active: float, tick: float = 0.0,
		respect_dash: bool = true, instakill: bool = false, skin: PackedScene = null) -> Node:
	var h = HAZARD.new()
	h.setup(size, color, damage, telegraph, active, tick, respect_dash, instakill, skin)
	get_parent().add_child(h)
	h.global_position = pos
	return h


# Nevasca de tela cheia (CanvasLayer). Usa skin_blizzard se houver, senão o shader de neve.
func _spawn_blizzard() -> CanvasLayer:
	var layer := CanvasLayer.new()
	layer.layer = 1
	if skin_blizzard:
		layer.add_child(skin_blizzard.instantiate())
	else:
		# Branco de fundo (whiteout) leve
		var fog := ColorRect.new()
		fog.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		fog.color = Color(0.85, 0.92, 1.0, 0.15)
		fog.mouse_filter = Control.MOUSE_FILTER_IGNORE
		layer.add_child(fog)
		# Neve forte por cima (shader)
		var snow := ColorRect.new()
		snow.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		snow.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var mat := ShaderMaterial.new()
		mat.shader = SNOW_SHADER
		mat.set_shader_parameter("layers", 4)
		mat.set_shader_parameter("density", blizzard_density)
		mat.set_shader_parameter("wind_direction", Vector2(-2.2, 0.6))
		mat.set_shader_parameter("speed", 4.0)
		mat.set_shader_parameter("wave_amplitude", 0.7)
		mat.set_shader_parameter("wave_frequency", 2.5)
		mat.set_shader_parameter("particle_size", 0.12)
		mat.set_shader_parameter("snow_color", Color(1, 1, 1, 0.95))
		snow.material = mat
		layer.add_child(snow)
	get_parent().add_child(layer)
	return layer


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


# Vendaval (ColorRect com shader) cobrindo a arena; o centro = o vórtice.
func _spawn_wind() -> ColorRect:
	var w := ColorRect.new()
	w.size     = Vector2(arena_right - arena_left, arena_floor - arena_top)
	w.position = Vector2(arena_left, arena_top)
	w.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var mat := ShaderMaterial.new()
	mat.shader = VENTO_SHADER
	mat.set_shader_parameter("wind_color", Color(0.88, 0.94, 1.0))   # branco-gelo
	w.material = mat
	get_parent().add_child(w)
	return w


# Esconde o corpo do boss (todas as formas e o cubo). Usado no Vórtice.
func _hide_body() -> void:
	for k in _forms:
		if _forms[k]:
			_forms[k].visible = false
	if _body_cube:
		_body_cube.visible = false
	_cur_form = null


# Troca a forma do boss. Mostra o sprite da forma se existir; senão o cubo `color`.
func _set_body(form: String, color: Color) -> void:
	_cur_form_key   = form
	_cur_cube_color = color
	for k in _forms:
		if _forms[k]:
			_forms[k].visible = false
	if _body_cube:
		_body_cube.visible = false

	_cur_form = _forms.get(form)
	if _cur_form:
		_cur_form.visible = true
		if _cur_form is CanvasItem:
			_cur_form.modulate = Color.WHITE
		_play_anim("idle")
	elif _body_cube:
		_body_cube.visible = true
		_body_cube.color = color


# Tinta momentânea (dano/parry/atordoado) na forma atual.
func _set_color(c: Color) -> void:
	if _cur_form and _cur_form.visible and _cur_form is CanvasItem:
		_cur_form.modulate = c
	elif _body_cube and _body_cube.visible:
		_body_cube.color = c


# Volta à cor base da forma atual (após um flash).
func _restore_body_color() -> void:
	if _cur_form and _cur_form.visible and _cur_form is CanvasItem:
		_cur_form.modulate = Color.WHITE
	elif _body_cube and _body_cube.visible:
		_body_cube.color = _cur_cube_color


func _play_anim(anim_name: String) -> void:
	if _cur_form is AnimatedSprite2D:
		var sf : SpriteFrames = _cur_form.sprite_frames
		if sf and sf.has_animation(anim_name):
			_cur_form.play(anim_name)


func _banner(text: String) -> void:
	print("[Silvanna] >>> ", text)


# Troca a música quando a Silvanna surge. Usa o player indicado, ou acha um na cena,
# ou cria um interno. Se `silvanna_music` estiver vazio, não faz nada.
func _play_initial_music() -> void:
	if initial_music == null:
		return
	var p := _get_music_player()
	p.stream = initial_music
	p.play()


# Acha o player de música (campo, ou na cena) ou cria um interno.
func _get_music_player() -> AudioStreamPlayer:
	var p : AudioStreamPlayer = null
	if music_player != NodePath(""):
		p = get_node_or_null(music_player) as AudioStreamPlayer
	if p == null:
		p = _find_audio_player(get_tree().current_scene)
	if p == null:
		p = AudioStreamPlayer.new()
		add_child(p)
	return p


func _switch_to_silvanna_music() -> void:
	if silvanna_music == null:
		return

	# Acha a música atual (pra fazer fade-out nela).
	var old : AudioStreamPlayer = null
	if music_player != NodePath(""):
		old = get_node_or_null(music_player) as AudioStreamPlayer
	if old == null:
		old = _find_audio_player(get_tree().current_scene)

	var target_db : float = old.volume_db if old else 0.0

	# Cria um player novo pra Silvanna e sobe o volume dele.
	var np := AudioStreamPlayer.new()
	add_child(np)
	np.stream = silvanna_music
	np.volume_db = -40.0
	np.play()

	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(np, "volume_db", target_db, music_fade_time)   # sobe a nova
	if old:
		tw.tween_property(old, "volume_db", -40.0, music_fade_time)  # baixa a antiga
		tw.chain().tween_callback(old.stop)


func _find_audio_player(node: Node) -> AudioStreamPlayer:
	if node == null:
		return null
	for c in node.get_children():
		if c is AudioStreamPlayer:
			return c
		var found := _find_audio_player(c)
		if found:
			return found
	return null
