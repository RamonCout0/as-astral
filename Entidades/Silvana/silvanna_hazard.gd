# silvanna_hazard.gd
# Cubo de perigo genérico (PLACEHOLDER trocável). Node2D + visual.
# Detecção por AABB manual contra o player (não depende de camadas de colisão).
#
# Fluxo: TELEGRAFO (aviso, sem dano) -> ATIVO (dá dano) -> some.
#
# VISUAL:
#   - Por padrão desenha um ColorRect do tamanho do perigo.
#   - Se você passar uma `skin` (PackedScene), ela é instanciada no lugar do cubo
#     (centralizada). Útil para trocar o placeholder pela sua arte.
extends Node2D

var _size        : Vector2 = Vector2(32, 32)
var _color       : Color   = Color(1, 0, 0)
var _damage      : float   = 500.0
var _telegraph   : float   = 0.6     # tempo de aviso antes de ativar
var _active      : float   = 0.4     # tempo causando dano (-1 = permanente)
var _tick        : float   = 0.0     # 0 = dano único; >0 = dano contínuo a cada _tick s
var _respect_dash: bool    = true    # se true, dash do player anula o dano (I-frame)
var _instakill   : bool    = false
var _skin        : PackedScene = null

const PERIGO_SHADER := preload("res://Shaders_Efeitos/perigo.gdshader")

var _vis       : CanvasItem = null   # ColorRect (placeholder) ou skin instanciada
var _is_rect   : bool  = true
var _phase     : int   = 0           # 0 = telegrafo, 1 = ativo
var _timer     : float = 0.0
var _dmg_cd    : float = 0.0
var _hit_once  : bool  = false
var _player    : Node2D = null

signal expired


func setup(size: Vector2, color: Color, damage: float, telegraph: float,
		active: float, tick: float = 0.0, respect_dash: bool = true,
		instakill: bool = false, skin: PackedScene = null) -> void:
	_size         = size
	_color        = color
	_damage       = damage
	_telegraph    = telegraph
	_active       = active
	_tick         = tick
	_respect_dash = respect_dash
	_instakill    = instakill
	_skin         = skin


func _ready() -> void:
	_player = get_tree().get_first_node_in_group("player") as Node2D

	if _skin:
		var inst := _skin.instantiate()
		# Se a skin for um Control (TextureRect/NinePatchRect/ColorRect), ela se ajusta
		# ao tamanho do perigo (útil pros ataques largos: laser, corte, espada, etc).
		if inst is Control:
			var ctl := inst as Control
			ctl.size = _size
			ctl.position = -_size * 0.5
		add_child(inst)
		if inst is AnimatedSprite2D:
			(inst as AnimatedSprite2D).play()
		if inst is CanvasItem:
			_vis = inst
		_is_rect = false
	else:
		var r := ColorRect.new()
		r.size     = _size
		r.position = -_size * 0.5
		r.color    = _color
		var mat := ShaderMaterial.new()   # brilho/pulso de energia
		mat.shader = PERIGO_SHADER
		r.material = mat
		add_child(r)
		_vis = r
		_is_rect = true

	_phase = 0
	_timer = _telegraph
	_apply_look(false)
	if _telegraph <= 0.0:
		_activate()


func _activate() -> void:
	_phase = 1
	_timer = _active
	_apply_look(true)


func _apply_look(is_active: bool) -> void:
	if _vis == null:
		return
	if _is_rect:
		(_vis as ColorRect).color = Color(_color.r, _color.g, _color.b, 0.85 if is_active else 0.30)
	else:
		_vis.modulate.a = 1.0 if is_active else 0.4


func _physics_process(delta: float) -> void:
	_dmg_cd -= delta

	if _phase == 0:
		# Pisca o telegrafo (só no cubo placeholder)
		if _is_rect and _vis:
			(_vis as ColorRect).color.a = 0.20 + 0.20 * (sin(_timer * 18.0) * 0.5 + 0.5)
		_timer -= delta
		if _timer <= 0.0:
			_activate()
		return

	# --- FASE ATIVA ---
	_try_damage()

	if _active >= 0.0:
		_timer -= delta
		if _timer <= 0.0:
			expired.emit()
			queue_free()


func _try_damage() -> void:
	if not _player or not is_instance_valid(_player):
		return

	# AABB: player dentro do perigo?
	var half := _size * 0.5
	var p := _player.global_position
	if abs(p.x - global_position.x) > half.x or abs(p.y - global_position.y) > half.y:
		return

	# I-frame de dash
	if _respect_dash and _player.get("is_dashing"):
		return

	if _instakill:
		_player.take_damage(999999.0)
		return

	if _tick <= 0.0:
		if not _hit_once:
			_hit_once = true
			_player.take_damage(_damage)
	else:
		if _dmg_cd <= 0.0:
			_dmg_cd = _tick
			_player.take_damage(_damage)
