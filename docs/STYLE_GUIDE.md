# Crimson Veil - Style Guide

**Reference this when writing code to maintain consistency.**

---

## Code Conventions

### General Principles
1. **Readability over cleverness** - Clear code > short code
2. **Explicit over implicit** - Clear intent in naming and structure
3. **Comments explain why, not what** - Code should be self-documenting
4. **Consistency matters** - Follow existing patterns in the codebase

---

## Naming Conventions

### Variables
```gdscript
# Use snake_case for variables and functions
var player_health: float = 100.0
var max_inventory_slots: int = 32
var is_building_mode_active: bool = false

# Use descriptive names
var tree_height: float  # Good
var h: float            # Bad

# Boolean variables use is_, has_, can_ prefix
var is_grounded: bool
var has_axe: bool
var can_harvest: bool
```

### Constants
```gdscript
# Use SCREAMING_SNAKE_CASE for constants
const MAX_HEALTH: float = 100.0
const STACK_LIMITS = {
    "wood": 100,
    "stone": 50
}
const HARVEST_DISTANCE: float = 3.0
```

### Functions
```gdscript
# Use snake_case for functions
func calculate_damage(base_damage: float, multiplier: float) -> float:
    return base_damage * multiplier

# Private functions use underscore prefix
func _process_movement(delta: float) -> void:
    # Internal logic
    pass

# Signal handlers use _on_ prefix
func _on_resource_harvested(resource_type: String, amount: int) -> void:
    # Handle signal
    pass
```

### Signals
```gdscript
# Use past tense or present tense based on when it fires
signal resource_harvested(resource_type: String, amount: int)  # Past - after action
signal item_added(item_type: String, amount: int)              # Past - after action
signal health_changed(old_value: float, new_value: float)      # Past - after change
```

### Classes and Nodes
```gdscript
# Use PascalCase for class names and node types
class_name HarvestableResource extends RigidBody3D
class_name InventoryItem extends Resource

# Scene/script file names use snake_case
# harvestable_resource.gd
# inventory_item.gd
```

---

## Type Annotations

### Always Use Type Hints
```gdscript
# Good - explicit types
var health: float = 100.0
var inventory_slots: Array[Dictionary] = []
var current_tool: String = "axe"

func add_item(item_type: String, amount: int) -> bool:
    # Function body
    return true

# Bad - no types
var health = 100.0
var inventory_slots = []
var current_tool = "axe"

func add_item(item_type, amount):
    return true
```

### Function Return Types
```gdscript
# Always specify return type
func get_player_position() -> Vector3:
    return global_position

func calculate_distance() -> float:
    return position.distance_to(target_position)

func is_valid_placement() -> bool:
    return raycast.is_colliding()

# Use void for functions that don't return
func play_sound(sound_name: String) -> void:
    audio_player.play()
```

---

## Code Organization

### File Structure
```gdscript
# 1. Class declaration
class_name ClassName extends BaseClass

# 2. Signals
signal something_happened(data: int)
signal state_changed(old_state: String, new_state: String)

# 3. Constants
const MAX_VALUE: int = 100
const DEFAULT_SPEED: float = 5.0

# 4. Exported variables (@export)
@export var health: float = 100.0
@export var speed: float = 5.0

# 5. Public variables
var is_active: bool = false
var current_state: String = "idle"

# 6. Private variables (underscore prefix)
var _cached_value: float = 0.0
var _timer: float = 0.0

# 7. Onready variables
@onready var mesh_instance: MeshInstance3D = $MeshInstance3D
@onready var collision_shape: CollisionShape3D = $CollisionShape3D

# 8. Built-in callbacks (_ready, _process, etc.)
func _ready() -> void:
    # Initialization
    pass

func _process(delta: float) -> void:
    # Per-frame logic
    pass

# 9. Public methods
func public_method() -> void:
    pass

# 10. Private methods (underscore prefix)
func _private_method() -> void:
    pass

# 11. Signal callbacks (_on_ prefix)
func _on_button_pressed() -> void:
    pass
```

### Function Length
- **Target:** Functions under 50 lines
- **Warning:** 100+ lines (consider breaking up)
- **Critical:** 200+ lines (definitely refactor)

### File Length
- **Target:** Files under 500 lines
- **Warning:** 800+ lines (consider refactoring)
- **Critical:** 1500+ lines (definitely refactor)

---

## Comments and Documentation

### When to Comment
```gdscript
# Good - explain WHY
# Use lerp instead of direct assignment to prevent camera jitter
camera_position = lerp(camera_position, target_position, 0.1)

# Good - explain complex logic
# Calculate biome based on temperature (-1 to 1) and moisture (0 to 1)
# Temperature affects north-south gradient, moisture affects density
var temperature = biome_noise.get_noise_2d(x, z)
var moisture = abs(biome_noise.get_noise_2d(x + 1000, z + 1000))

# Bad - explain WHAT (code is self-explanatory)
# Set health to 100
health = 100.0

# Bad - outdated comment
# TODO: Add sound effect  <- sound effect already added
play_sound("axe_chop")
```

### Function Documentation
```gdscript
## Harvests a resource and adds items to inventory.
##
## This function checks tool requirements, deals damage to the resource,
## plays appropriate sounds, and adds items to the player's inventory
## when the resource is fully harvested.
##
## @param resource: The harvestable resource node
## @param tool_type: The tool being used (e.g., "axe", "pickaxe")
## @return: true if harvest was successful, false otherwise
func harvest_resource(resource: Node, tool_type: String) -> bool:
    # Implementation
    pass
```

---

## Signal Usage

### Declaring Signals
```gdscript
# Use descriptive names with relevant parameters
signal resource_harvested(resource_type: String, amount: int, position: Vector3)
signal health_changed(old_value: float, new_value: float)
signal container_opened(container: Node)

# Not just generic signals
signal event_occurred()  # Bad - too vague
```

### Emitting Signals
```gdscript
# Emit with all required parameters
resource_harvested.emit("wood", 5, tree_position)
health_changed.emit(old_health, new_health)

# Emit at the right time (after state change)
func take_damage(amount: float) -> void:
    var old_health = health
    health -= amount
    health_changed.emit(old_health, health)  # After change
```

### Connecting Signals
```gdscript
# Connect in _ready with type-safe syntax
func _ready() -> void:
    harvesting_system.resource_harvested.connect(_on_resource_harvested)
    player_inventory.item_added.connect(_on_item_added)

# Use descriptive callback names
func _on_resource_harvested(resource_type: String, amount: int, position: Vector3) -> void:
    # Handle the signal
    pass
```

---

## Error Handling

### Null Checks
```gdscript
# Always check for null before accessing
func interact_with_container(container: Node) -> void:
    if container == null:
        push_warning("Attempted to interact with null container")
        return
    
    container.open()

# Check node existence before getting
func get_mesh_instance() -> MeshInstance3D:
    if not has_node("MeshInstance3D"):
        push_error("MeshInstance3D not found")
        return null
    
    return get_node("MeshInstance3D") as MeshInstance3D
```

### Bounds Checking
```gdscript
# Check array bounds
func get_inventory_slot(index: int) -> Dictionary:
    if index < 0 or index >= inventory_slots.size():
        push_warning("Invalid inventory slot index: %d" % index)
        return {}
    
    return inventory_slots[index]

# Clamp values to valid ranges
func set_health(value: float) -> void:
    health = clamp(value, 0.0, max_health)
```

### Assertions for Development
```gdscript
# Use assert for conditions that should never fail
func add_item_to_slot(slot: int, item: Dictionary) -> void:
    assert(slot >= 0 and slot < max_slots, "Slot index out of bounds")
    assert(item.has("type"), "Item must have a type")
    
    inventory[slot] = item
```

---

## Performance Best Practices

### Avoid in Hot Paths
```gdscript
# Bad - creating strings in _process
func _process(delta: float) -> void:
    var debug_text = "Position: " + str(position)  # Avoid
    label.text = debug_text

# Good - only update when changed
func _process(delta: float) -> void:
    if position != last_position:
        label.text = "Position: " + str(position)
        last_position = position
```

### Cache Node References
```gdscript
# Bad - getting node every frame
func _process(delta: float) -> void:
    get_node("MeshInstance3D").visible = true

# Good - cache in _ready
@onready var mesh_instance: MeshInstance3D = $MeshInstance3D

func _process(delta: float) -> void:
    mesh_instance.visible = true
```

### Object Pooling
```gdscript
# For frequently created/destroyed objects
var particle_pool: Array[GPUParticles3D] = []

func get_particle_from_pool() -> GPUParticles3D:
    for particle in particle_pool:
        if not particle.emitting:
            return particle
    
    # Create new if none available
    var new_particle = particle_scene.instantiate()
    particle_pool.append(new_particle)
    return new_particle
```

---

## Godot-Specific Patterns

### Node Tree Access
```gdscript
# Use @onready for child nodes
@onready var collision_shape: CollisionShape3D = $CollisionShape3D
@onready var mesh_instance: MeshInstance3D = $MeshInstance3D

# Use get_node() for dynamic access
var player = get_node("/root/World/Player")

# Use find_child() for searching
var audio_player = find_child("AudioPlayer", true, false)
```

### Scene Instantiation
```gdscript
# Preload scenes
const TREE_SCENE = preload("res://scenes/resources/tree.tscn")

func spawn_tree(position: Vector3) -> void:
    var tree = TREE_SCENE.instantiate()
    tree.global_position = position
    add_child(tree)
```

### Input Handling
```gdscript
# Use Input.is_action_pressed for continuous
func _process(delta: float) -> void:
    if Input.is_action_pressed("move_forward"):
        move_forward(delta)

# Use _input or _unhandled_input for single events
func _input(event: InputEvent) -> void:
    if event.is_action_pressed("jump"):
        jump()
```

---

## Anti-Patterns to Avoid

### Don't Use Magic Numbers
```gdscript
# Bad
if health < 20:
    play_low_health_sound()

# Good
const LOW_HEALTH_THRESHOLD: float = 20.0

if health < LOW_HEALTH_THRESHOLD:
    play_low_health_sound()
```

### Don't Nest Deeply
```gdscript
# Bad - deep nesting
func process_inventory() -> void:
    if is_inventory_open:
        if has_items:
            for item in items:
                if item.is_valid():
                    if item.can_stack():
                        stack_item(item)

# Good - early returns
func process_inventory() -> void:
    if not is_inventory_open:
        return
    
    if not has_items:
        return
    
    for item in items:
        if not item.is_valid():
            continue
        
        if item.can_stack():
            stack_item(item)
```

### Don't Duplicate Code
```gdscript
# Bad - duplicated logic
func add_wood(amount: int) -> void:
    if inventory.has("wood"):
        inventory["wood"] += amount
    else:
        inventory["wood"] = amount

func add_stone(amount: int) -> void:
    if inventory.has("stone"):
        inventory["stone"] += amount
    else:
        inventory["stone"] = amount

# Good - reusable function
func add_item(item_type: String, amount: int) -> void:
    if inventory.has(item_type):
        inventory[item_type] += amount
    else:
        inventory[item_type] = amount
```

---

## Project-Specific Patterns

### Resource Harvesting Pattern
```gdscript
# Standard pattern for harvestable resources
class_name HarvestableResource extends RigidBody3D

signal health_changed(new_health: float, max_health: float)
signal destroyed()

@export var resource_type: String = "wood"
@export var max_health: float = 100.0
@export var required_tool: String = "axe"

var health: float = max_health

func take_damage(amount: float) -> void:
    health -= amount
    health_changed.emit(health, max_health)
    
    if health <= 0:
        _on_destroyed()

func _on_destroyed() -> void:
    destroyed.emit()
    queue_free()
```

### Signal-Based System Communication
```gdscript
# Systems communicate through signals, not direct calls

# Bad - direct dependency
func harvest_tree() -> void:
    player.inventory.add_item("wood", 5)  # Direct coupling

# Good - signal-based
signal resource_harvested(resource_type: String, amount: int)

func harvest_tree() -> void:
    resource_harvested.emit("wood", 5)

# In player script
func _ready() -> void:
    harvesting_system.resource_harvested.connect(_on_resource_harvested)

func _on_resource_harvested(resource_type: String, amount: int) -> void:
    inventory.add_item(resource_type, amount)
```

### AutoLoad Singleton Pattern
```gdscript
# For truly global systems only
# autoload/audio_manager.gd

extends Node

var sound_library: Dictionary = {}
var active_sounds: Array[AudioStreamPlayer] = []

func _ready() -> void:
    _load_sound_library()

func play_sound(sound_name: String) -> void:
    if not sound_library.has(sound_name):
        push_warning("Sound not found: " + sound_name)
        return
    
    var player = _get_available_player()
    player.stream = sound_library[sound_name]
    player.play()

# Access from anywhere
AudioManager.play_sound("axe_chop")
```

---

## Git Commit Conventions

### Commit Message Format
```
type: brief description (50 chars max)

Optional detailed explanation (wrap at 72 chars)
- Why the change was made
- What problem it solves
- Any breaking changes
```

### Commit Types
- `feat:` - New feature
- `fix:` - Bug fix
- `refactor:` - Code restructuring (no behavior change)
- `perf:` - Performance improvement
- `docs:` - Documentation changes
- `style:` - Code style changes (formatting, etc.)
- `test:` - Adding or updating tests
- `chore:` - Maintenance tasks (dependencies, config)

### Examples
```bash
feat: add biome-aware footstep system

Implemented footstep sounds that change based on terrain type.
Supports grass, stone, sand, and snow surfaces.

fix: prevent log despawn sound spam

Removed audio from log despawn to avoid overwhelming the player
when multiple logs disappear simultaneously.

refactor: extract tree visuals to separate file

Reduced vegetation_spawner.gd from 2,075 to 1,457 lines by
extracting TreeVisual class to tree_visual.gd.
```

---

## Testing Guidelines

### Manual Testing Checklist
Before committing changes:
- [ ] Run the project (F5) - no errors in console
- [ ] Test new feature with keyboard + mouse
- [ ] Test new feature with controller
- [ ] Check for unintended side effects
- [ ] Verify audio plays correctly (if audio change)
- [ ] Check performance (60 FPS target)

### Code Review Self-Checklist
- [ ] Code follows style guide
- [ ] Type hints on all variables/functions
- [ ] No magic numbers (use constants)
- [ ] Comments explain why, not what
- [ ] No deep nesting (< 4 levels)
- [ ] Functions under 50 lines
- [ ] Files under 500 lines

---

**For more information:**
- **Architecture:** See `docs/ARCHITECTURE.md`
- **Technical details:** See `docs/TECHNICAL_DETAILS.md`
- **Quick start:** See `SESSION_START.md`
