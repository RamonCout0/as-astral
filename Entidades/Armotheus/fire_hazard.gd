# fire_hazard.gd
# Chama de queimadura — persiste 3 segundos no chão após laser não ser parado.
# Dano contínuo ao player, respeita I-frame de dash.
extends Area2D

const LIFETIME        := 3.0
const DAMAGE_PER_TICK := 400.0
const DAMAGE_COOLDOWN := 0.5

var _life  : float = LIFETIME
var _dmg_cd : float = 0.0


func _ready() -> void:
	collision_layer = 0
	collision_mask  = 1  # layer do player (CharacterBody2D usa a layer 1 padrão)

	# Visual: base laranja
	var base := ColorRect.new()
	base.size     = Vector2(48.0, 18.0)
	base.position = Vector2(-24.0, -18.0)
	base.color    = Color(1.0, 0.35, 0.0, 0.85)
	add_child(base)

	# Visual: brilho amarelo
	var glow := ColorRect.new()
	glow.size     = Vector2(28.0, 10.0)
	glow.position = Vector2(-14.0, -26.0)
	glow.color    = Color(1.0, 0.78, 0.0, 0.7)
	add_child(glow)

	# Collision shape
	var shape := CollisionShape2D.new()
	var rect_shape := RectangleShape2D.new()
	rect_shape.size = Vector2(48.0, 18.0)
	shape.shape    = rect_shape
	shape.position = Vector2(0.0, -9.0)
	add_child(shape)

	body_entered.connect(_on_body_entered)


func _physics_process(delta: float) -> void:
	_life  -= delta
	_dmg_cd -= delta

	# Efeito de piscar no final da vida
	if _life < 0.8:
		modulate = Color(1, 1, 1, sin(_life * 22.0) * 0.5 + 0.5)

	if _life <= 0.0:
		queue_free()


func _on_body_entered(body: Node2D) -> void:
	if _dmg_cd > 0.0:
		return
	
	if not body.is_in_group("player"):
		return
	
	if not body.has_method("take_damage"):
		return
	
	# Respeita I-frame do dash
	if body.get("is_dashing"):
		return

	body.take_damage(DAMAGE_PER_TICK)
	_dmg_cd = DAMAGE_COOLDOWN
