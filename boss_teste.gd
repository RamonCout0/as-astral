extends CharacterBody2D

# --- Variáveis de Vida (Sistema Personalizado) ---
@export_group("Configurações de Vida")
@export var max_health: float = 304000.0
@export var health_per_segment: float = 1000.0 # Quantidade de vida por "barra" ou segmento
var current_health: float

# --- Outras Variáveis ---
var is_immune: bool = false

# --- Funções Iniciais ---
func _ready():
	# Adiciona o boss ao grupo para que o player/projéteis o encontrem
	add_to_group("boss")
	await get_tree().process_frame
	initialize_health_system()

func initialize_health_system():
	current_health = max_health
	# Envia os dados iniciais para a UI através do EventBus
	if EventBus.has_signal("boss_max_health_set"):
		EventBus.boss_max_health_set.emit(max_health, health_per_segment)
	else:
		push_error("ERRO: Sinal 'boss_max_health_set' não encontrado no EventBus!")

# --- Sistema de Dano ---
func take_damage(amount: float):
	if is_immune or current_health <= 0:
		return
		
	current_health -= amount
	current_health = max(0, current_health) # Garante que não fique negativo
	
	# Atualiza a barra de vida via EventBus
	EventBus.boss_health_updated.emit(current_health)
	
	print("Boss recebeu dano! Vida atual: ", current_health)
	
	if current_health <= 0:
		die()

func die():
	print("Boss derrotado!")
	# Aqui você pode tocar uma animação antes de deletar
	queue_free()

# --- Física Básica (Opcional para o teste não cair no infinito) ---
func _physics_process(delta):
	if not is_on_floor():
		velocity.y += ProjectSettings.get_setting("physics/2d/default_gravity") * delta
	
	move_and_slide()
