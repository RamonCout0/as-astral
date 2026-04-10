extends CanvasLayer

# --- CONECTE NO INSPETOR ---
@export var bar_count_label: Label
@export var segment_progress_bar: TextureProgressBar
@export var stagger_progress_bar: TextureProgressBar  # barra amarela de stagger

# Ciclo de cores da barra de vida (vermelho, azul, verde, amarelo...)
@export var cycle_textures: Array[Texture2D]
# Texturas das últimas barras (fase final de vida)
@export var final_textures: Array[Texture2D]

# --- Variáveis Internas ---
var health_per_segment: float = 1.0
var display_health:     float = 0.0
var health_tween:       Tween
var total_bar_count:    int   = 1

func _ready():
	EventBus.boss_max_health_set.connect(set_boss_max_health)
	EventBus.boss_health_updated.connect(update_boss_health)
	EventBus.boss_stagger_updated.connect(update_stagger_bar)

	# Começa com stagger zerado
	if stagger_progress_bar:
		stagger_progress_bar.value = 0

func set_boss_max_health(max_health, p_health_per_segment):
	health_per_segment = p_health_per_segment
	if health_per_segment <= 0:
		return

	segment_progress_bar.max_value = health_per_segment
	display_health  = float(max_health)
	total_bar_count = int(ceil(float(max_health) / health_per_segment))

	update_hud_visuals(display_health)
	show()

func update_boss_health(current_health):
	if health_tween and health_tween.is_running():
		health_tween.kill()

	health_tween = create_tween()
	health_tween.tween_method(update_hud_visuals, display_health, float(current_health), 1.0)

# Atualiza a barra de stagger — sem ciclo de cores, só amarelo (definido no inspetor)
func update_stagger_bar(current_stagger: float, max_stagger: float) -> void:
	if stagger_progress_bar == null:
		return
	stagger_progress_bar.max_value = max_stagger
	stagger_progress_bar.value     = current_stagger

func update_hud_visuals(health_value):
	if health_per_segment <= 0:
		return

	var current_bar_count = int(ceil(health_value / health_per_segment))
	bar_count_label.text  = str(current_bar_count) + "x"

	# Fase final (última barra)
	if current_bar_count <= 1 and final_textures.size() > 0:
		var final_index = mini(1 - current_bar_count, final_textures.size() - 1)
		if final_index >= 0:
			segment_progress_bar.texture_progress = final_textures[final_index]

	# Ciclo normal de cores
	elif cycle_textures.size() > 0:
		var cycle_index = (total_bar_count - current_bar_count) % cycle_textures.size()
		if cycle_index >= 0 and cycle_index < cycle_textures.size():
			segment_progress_bar.texture_progress = cycle_textures[cycle_index]

	# Valor da barra (quanto da barra atual está preenchida)
	if health_value <= 0:
		segment_progress_bar.value = 0
	else:
		var health_in_previous_bars = (current_bar_count - 1) * health_per_segment
		segment_progress_bar.value  = health_value - health_in_previous_bars

	display_health = health_value
