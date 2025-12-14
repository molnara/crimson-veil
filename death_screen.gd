extends Control
class_name DeathScreen

## Death Screen UI Controller
## Shows "YOU DIED" with death counter and respawn button
## Features: Fade-to-black animation, 2-second respawn delay, M+KB + controller support

signal respawn_requested

@onready var fade_overlay: ColorRect = $FadeOverlay
@onready var panel: Panel = $Panel
@onready var title_label: Label = $Panel/VBoxContainer/TitleLabel
@onready var death_counter_label: Label = $Panel/VBoxContainer/DeathCounterLabel
@onready var respawn_button: Button = $Panel/VBoxContainer/RespawnButton

var respawn_ready: bool = false
var respawn_timer: float = 0.0
const RESPAWN_DELAY: float = 2.0

func _ready() -> void:
	visible = false
	respawn_button.pressed.connect(_on_respawn_button_pressed)
	
	# Set initial alpha to 0 for fade animation
	fade_overlay.modulate.a = 0.0
	panel.modulate.a = 0.0

func show_death_screen(death_count: int) -> void:
	"""Show death screen with fade-in animation and death counter"""
	visible = true
	respawn_ready = false
	respawn_timer = 0.0
	
	# Update death counter
	death_counter_label.text = "Deaths: %d" % death_count
	
	# Play death sound
	AudioManager.play_sound("player_death", "sfx", false, false)
	
	# Start fade-in animation
	animate_fade_in()
	
	# Disable respawn button initially
	respawn_button.disabled = true
	respawn_button.text = "Respawn (2s)"
	
	print("[DeathScreen] Shown with %d deaths" % death_count)

func animate_fade_in() -> void:
	"""Animate fade to black effect"""
	var tween = create_tween()
	tween.set_parallel(true)
	
	# Fade in black overlay
	tween.tween_property(fade_overlay, "modulate:a", 0.85, 0.5).set_trans(Tween.TRANS_CUBIC)
	
	# Fade in panel (slightly delayed)
	tween.tween_property(panel, "modulate:a", 1.0, 0.8).set_delay(0.3).set_trans(Tween.TRANS_CUBIC)

func _process(delta: float) -> void:
	if not visible:
		return
	
	# Handle respawn delay countdown
	if not respawn_ready:
		respawn_timer += delta
		
		# Update button text with countdown
		var remaining = RESPAWN_DELAY - respawn_timer
		if remaining > 0:
			respawn_button.text = "Respawn (%.1fs)" % remaining
		else:
			# Delay complete - enable respawn
			respawn_ready = true
			respawn_button.disabled = false
			respawn_button.text = "Respawn"
			respawn_button.grab_focus()  # Auto-focus for controller
			print("[DeathScreen] Respawn button enabled")

func _input(event: InputEvent) -> void:
	if not visible or not respawn_ready:
		return
	
	# Allow Enter key or Controller A button to respawn
	if event.is_action_pressed("ui_accept"):
		_on_respawn_button_pressed()
		get_viewport().set_input_as_handled()

func _on_respawn_button_pressed() -> void:
	"""Handle respawn button click"""
	if not respawn_ready:
		return
	
	print("[DeathScreen] Respawn requested")
	
	# Play UI sound
	AudioManager.play_sound("ui_select", "ui", false, false)
	
	# Emit respawn signal
	respawn_requested.emit()
	
	# Hide death screen
	hide_death_screen()

func hide_death_screen() -> void:
	"""Hide death screen with fade-out animation"""
	var tween = create_tween()
	tween.set_parallel(true)
	
	# Fade out overlay and panel
	tween.tween_property(fade_overlay, "modulate:a", 0.0, 0.3)
	tween.tween_property(panel, "modulate:a", 0.0, 0.3)
	
	# Hide after animation
	tween.tween_callback(func(): visible = false)
