extends CharacterBody2D

# --- CONFIGURAÇÕES ---
const SPEED = 250.0
const JUMP_VELOCITY = -450.0
const WALL_CLIMB_SPEED = 160.0
const WALL_SLIDE_SPEED = 100.0
const DASH_SPEED = 850.0

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

# --- ESTADOS ---
var is_attacking = false
var is_dashing = false
var is_grabbing = false
var can_dash = true

# --- COMBO ---
var combo_step = 0
var combo_timer = 0.0
const COMBO_WINDOW = 0.6

@onready var anim = $AnimationPlayer
@onready var sprite = $Sprite2D
@onready var dash_timer = $DashTimer
@onready var hitbox_area = $AttackHitbox
@onready var attack_hitbox = $AttackHitbox/CollisionShape2D

func _ready():
	attack_hitbox.disabled = true

func _physics_process(delta):
	if combo_timer > 0:
		combo_timer -= delta
	else:
		combo_step = 0

	if is_dashing:
		handle_attack()     # pode atacar durante dash
		handle_jump()       # pulo pode cancelar dash
		# SEM handle_movement() aqui — ele matava a velocidade do dash
		move_and_slide()
		update_animations()
		return

	if not is_on_floor() and not is_grabbing:
		velocity.y += gravity * delta

	handle_wall_grab()
	handle_jump()
	handle_dash()
	handle_attack()
	handle_movement()

	move_and_slide()
	update_animations()

func handle_movement():
	var direction = Input.get_axis("ui_left", "ui_right")
	
	if direction:
		velocity.x = direction * SPEED
		if direction > 0:
			sprite.flip_h = false
			hitbox_area.scale.x = 1
		elif direction < 0:
			sprite.flip_h = true
			hitbox_area.scale.x = -1
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

func handle_jump():
	if Input.is_action_just_pressed("ui_accept"):
		if is_on_floor():
			velocity.y = JUMP_VELOCITY
		elif is_on_wall_only():
			velocity.y = JUMP_VELOCITY
			velocity.x = -Input.get_axis("ui_left", "ui_right") * SPEED * 1.5
		elif is_dashing:        # pulo cancela o dash
			is_dashing = false
			dash_timer.stop()   # para o timer junto pra não bugar o cooldown
			velocity.y = JUMP_VELOCITY

func handle_wall_grab():
	if is_on_wall_only() and Input.is_action_pressed("grab"):
		is_grabbing = true
		velocity.y = Input.get_axis("ui_up", "ui_down") * WALL_CLIMB_SPEED
	else:
		is_grabbing = false
		if is_on_wall_only() and velocity.y > 0:
			velocity.y = min(velocity.y, WALL_SLIDE_SPEED)

func handle_dash():
	if Input.is_action_just_pressed("dash") and can_dash and not is_dashing:
		is_dashing = true
		can_dash = false
		velocity.y = 0
		velocity.x = -DASH_SPEED if sprite.flip_h else DASH_SPEED
		
		dash_timer.wait_time = 0.2
		dash_timer.one_shot = true
		dash_timer.start()

func _on_dash_timer_timeout():
	print("Dash acabou!")
	is_dashing = false
	await get_tree().create_timer(0.4).timeout
	can_dash = true

func handle_attack():
	if Input.is_action_just_pressed("attack"):
		if is_attacking:
			return

		is_attacking = true
		combo_timer = COMBO_WINDOW
		
		if combo_step == 0:
			combo_step = 1
			anim.play("attack1")
		elif combo_step == 1:
			combo_step = 2
			anim.play("attack2")
		else:
			combo_step = 1
			anim.play("attack1")

# --- FUNÇÕES DE ANIMAÇÃO (Call Method Track) ---
func ativar_hitbox():
	attack_hitbox.disabled = false

func desativar_hitbox():
	attack_hitbox.disabled = true

func finalizar_ataque():
	is_attacking = false
	desativar_hitbox()

func update_animations():
	if is_attacking:
		return

	if is_dashing:
		anim.play("Dash")
		return
		
	if is_grabbing:
		anim.play("Grab")
	elif is_on_floor():
		if velocity.x != 0:
			anim.play("walkking")
		else:
			anim.play("idle")
	else:
		if velocity.y < 0:
			anim.play("Jump")
		else:
			anim.play("fall")


func _on_attack_hitbox_area_entered(area):
	# Se a área que atingimos for a 'Hurtbox' de um Boss
	if area.name == "Hurtbox":
		var boss = area.get_parent() # Pega o nó BossTeste
		if boss.has_method("take_damage"):
			# Golpe normal dá 20, se for o segundo golpe do combo dá 40!
			var damage = 100.0 if combo_step == 1 else 200
			boss.take_damage(damage)


func _on_attack_hitbox_body_entered(body):
	# Verifica se o corpo que entrou está no grupo "boss"
	if body.is_in_group("boss"):
		if body.has_method("take_damage"):
			var damage = 100.0 if combo_step <= 1 else 200.0
			body.take_damage(damage)
			print("Bateu no corpo do Boss! Dano: ", damage)
