extends CharacterBody3D
class_name Enemy

## Base class for all enemy types in Crimson Veil
## Provides state machine, health, combat, and loot drop systems
## All enemy variants should extend this class

enum State { IDLE, CHASE, ATTACK, DEATH }

# Inspector-editable parameters
@export_group("Stats")
@export var max_health: int = 50
@export var damage: int = 10
@export var move_speed: float = 3.0

@export_group("AI Behavior")
@export var detection_range: float = 10.0
@export var deaggro_range: float = 20.0  ## Distance at which enemy stops chasing (0 = never stop)
@export var attack_range: float = 2.0
@export var attack_cooldown_duration: float = 1.5
@export var attack_telegraph_duration: float = 0.3

@export_group("Loot Drops")
## Array of dictionaries: [{item: "item_name", chance: 0.5}, ...]
@export var drop_table: Array[Dictionary] = []

# Internal state
var current_state: State = State.IDLE
var current_health: int
var player: Node3D = null
var attack_cooldown: float = 0.0
var telegraph_timer: float = 0.0
var is_telegraphing: bool = false

# Visual components (created by subclasses)
var visual_mesh: MeshInstance3D = null
var original_material: Material = null

# Collision setup
var collision_shape: CollisionShape3D = null

func _ready() -> void:
	current_health = max_health
	add_to_group("enemies")
	
	# Set collision layers (Layer 9 for enemy identification)
	collision_layer = 1 << 8  # Layer 9
	collision_mask = 1  # Only collide with world (Layer 1)
	
	# Get player reference
	player = get_tree().get_first_node_in_group("player")
	if not player:
		push_warning("Enemy: No player found in scene")
	
	# Check if collision shape exists in scene (from .tscn file)
	collision_shape = get_node_or_null("CollisionShape3D")
	
	# Setup collision shape if not already added by scene
	if not collision_shape:
		collision_shape = CollisionShape3D.new()
		var shape = CapsuleShape3D.new()
		shape.radius = 1.0  # Default fallback size
		shape.height = 3.0
		collision_shape.shape = shape
		add_child(collision_shape)
		print("[Enemy] Warning: No CollisionShape3D in scene, using default")
	
	# Let subclasses create their visuals
	create_enemy_visual()
	
	# DEBUG: Temporarily disabled to see CSG visuals clearly
	# var debug_marker = MeshInstance3D.new()
	# debug_marker.name = "DebugMarker"
	# var sphere_mesh = SphereMesh.new()
	# sphere_mesh.radius = 0.5
	# sphere_mesh.height = 1.0
	# debug_marker.mesh = sphere_mesh
	# 
	# var debug_mat = StandardMaterial3D.new()
	# debug_mat.albedo_color = Color(1, 0, 1)  # Bright magenta
	# debug_mat.emission_enabled = true
	# debug_mat.emission = Color(1, 0, 1)
	# debug_mat.emission_energy_multiplier = 2.0
	# debug_marker.set_surface_override_material(0, debug_mat)
	# 
	# add_child(debug_marker)
	# debug_marker.position = Vector3(0, 1, 0)  # Float above ground
	
	# Store original material for damage flash
	if visual_mesh and visual_mesh.get_surface_override_material_count() > 0:
		original_material = visual_mesh.get_surface_override_material(0)

func _physics_process(delta: float) -> void:
	if current_state == State.DEATH:
		return
	
	# Update attack timers
	if attack_cooldown > 0:
		attack_cooldown -= delta
	
	if is_telegraphing:
		telegraph_timer -= delta
		if telegraph_timer <= 0:
			is_telegraphing = false
			execute_attack()
	
	# Update AI state machine
	update_ai(delta)
	
	# Apply gravity
	if not is_on_floor():
		velocity.y -= 20.0 * delta
	
	move_and_slide()

func update_ai(delta: float) -> void:
	"""Core AI state machine logic"""
	if not player or current_state == State.DEATH:
		return
	
	var distance = global_position.distance_to(player.global_position)
	
	match current_state:
		State.IDLE:
			# Detect player in range
			if distance < detection_range:
				current_state = State.CHASE
		
		State.CHASE:
			# Check if player escaped (de-aggro)
			if deaggro_range > 0 and distance > deaggro_range:
				current_state = State.IDLE
				velocity = Vector3.ZERO
			# Check if in attack range
			elif distance < attack_range:
				current_state = State.ATTACK
				velocity = Vector3.ZERO  # Stop moving when attacking
			else:
				chase_player()
		
		State.ATTACK:
			# Return to chase if player escapes
			if distance > attack_range * 1.5:
				current_state = State.CHASE
			else:
				# Attempt attack if not on cooldown
				if attack_cooldown <= 0 and not is_telegraphing:
					start_attack_telegraph()

func chase_player() -> void:
	"""Move toward player at move_speed"""
	if not player:
		return
	
	var direction = (player.global_position - global_position).normalized()
	direction.y = 0  # Don't chase vertically
	
	velocity.x = direction.x * move_speed
	velocity.z = direction.z * move_speed
	
	# Face the player
	if direction.length() > 0.01:
		look_at(global_position + direction, Vector3.UP)

func start_attack_telegraph() -> void:
	"""Begin attack telegraph phase"""
	is_telegraphing = true
	telegraph_timer = attack_telegraph_duration
	velocity = Vector3.ZERO  # Stop moving during telegraph
	
	# Visual feedback (subclasses can override)
	on_attack_telegraph()

func execute_attack() -> void:
	"""Execute the actual attack after telegraph"""
	if not player:
		return
	
	var distance = global_position.distance_to(player.global_position)
	
	# Deal damage if player is still in range
	if distance <= attack_range:
		attack_player()
	
	# Start cooldown
	attack_cooldown = attack_cooldown_duration

func attack_player() -> void:
	"""Deal damage to player - override for unique attack patterns"""
	if not player or not player.has_method("take_damage"):
		return
	
	# Basic melee attack
	player.take_damage(damage)
	
	# Play attack sound (subclasses should implement)
	on_attack_execute()

func take_damage(amount: int) -> void:
	"""
	Simplified damage system (no is_heavy parameter)
	Called by CombatSystem when hit by player
	"""
	if current_state == State.DEATH:
		return
	
	current_health -= amount
	flash_white()
	on_hit()  # Call virtual function for enemy-specific hit sound
	
	# Interrupt idle state on damage
	if current_state == State.IDLE:
		current_state = State.CHASE
	
	if current_health <= 0:
		die()

func flash_white() -> void:
	"""Visual feedback for taking damage - 0.1s white flash"""
	if not visual_mesh:
		return
	
	# Create white material
	var white_mat = StandardMaterial3D.new()
	white_mat.albedo_color = Color.WHITE
	white_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	
	# Apply white flash
	visual_mesh.set_surface_override_material(0, white_mat)
	
	# Restore original material after 0.1s
	await get_tree().create_timer(0.1).timeout
	if visual_mesh and original_material:
		visual_mesh.set_surface_override_material(0, original_material)

func die() -> void:
	"""Handle enemy death - drop loot, play effects, remove enemy"""
	if current_state == State.DEATH:
		return
	
	current_state = State.DEATH
	collision_layer = 0  # Disable collision
	collision_mask = 0
	
	# Drop loot
	drop_loot()
	
	# Play death effect
	on_death()
	
	# Rumble feedback for enemy kill
	if RumbleManager:
		RumbleManager.play("enemy_death")
	
	# Fade out and remove
	fade_out()

func drop_loot() -> void:
	"""Process drop table and spawn items"""
	for drop_entry in drop_table:
		if not drop_entry.has("item") or not drop_entry.has("chance"):
			continue
		
		var roll = randf()
		if roll <= drop_entry.get("chance", 0.0):
			spawn_item(drop_entry.get("item", ""))

func spawn_item(item_name: String) -> void:
	"""Spawn a dropped item at enemy position"""
	# This will integrate with your existing item system
	# For now, just print for testing
	print("Enemy dropped: ", item_name, " at ", global_position)
	
	# TODO: Integration with actual item spawning system
	# Example: ItemManager.spawn_item(item_name, global_position)

func fade_out() -> void:
	"""Death animation - 0.5s dissolve effect"""
	if not visual_mesh:
		queue_free()
		return
	
	# Create fade tween
	var tween = create_tween()
	tween.set_parallel(true)
	
	# Fade out visual
	if visual_mesh.get_surface_override_material_count() > 0:
		var mat = visual_mesh.get_surface_override_material(0)
		if mat:
			tween.tween_property(mat, "albedo_color:a", 0.0, 0.5)
	
	# Sink into ground
	tween.tween_property(self, "global_position:y", global_position.y - 1.0, 0.5)
	
	# Remove after animation
	await tween.finished
	queue_free()

# Virtual methods for subclasses to override
func create_enemy_visual() -> void:
	"""Override in subclasses to create unique enemy appearance"""
	# Default: Simple cube
	visual_mesh = MeshInstance3D.new()
	var mesh = BoxMesh.new()
	mesh.size = Vector3(1, 1.5, 1)
	visual_mesh.mesh = mesh
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color.RED
	visual_mesh.set_surface_override_material(0, mat)
	
	add_child(visual_mesh)
	original_material = mat

func on_attack_telegraph() -> void:
	"""Override for telegraph visual effects (e.g., wind-up animation)"""
	pass

func on_attack_execute() -> void:
	"""Override for attack execution effects (e.g., sound, particles)"""
	pass

func on_hit() -> void:
	"""Override for hit/damage effects (e.g., hit sound)"""
	pass

func on_death() -> void:
	"""Override for death effects (e.g., sound, particles)"""
	pass
