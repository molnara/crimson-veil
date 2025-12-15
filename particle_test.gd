extends Node3D
## Standalone particle test - attach this to any Node3D in your scene
## Or create a new scene with just this script to test particles

var test_particles: GPUParticles3D

func _ready():
	print("=== PARTICLE TEST STARTING ===")
	_create_test_particles()
	
func _create_test_particles():
	test_particles = GPUParticles3D.new()
	test_particles.name = "TestParticles"
	add_child(test_particles)
	
	# Position above origin
	test_particles.position = Vector3(0, 20, 0)
	
	# Basic settings
	test_particles.amount = 500
	test_particles.lifetime = 3.0
	test_particles.preprocess = 0.0
	test_particles.emitting = true
	test_particles.visible = true
	
	# Simple process material
	var mat = ParticleProcessMaterial.new()
	mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	mat.emission_box_extents = Vector3(10, 0.1, 10)
	mat.gravity = Vector3(0, -10, 0)
	test_particles.process_material = mat
	
	# Big red cube so we can see it
	var mesh = BoxMesh.new()
	mesh.size = Vector3(0.5, 0.5, 0.5)
	var mesh_mat = StandardMaterial3D.new()
	mesh_mat.albedo_color = Color.RED
	mesh_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mesh.material = mesh_mat
	test_particles.draw_pass_1 = mesh
	
	print("Test particles created:")
	print("  - Position: ", test_particles.global_position)
	print("  - Amount: ", test_particles.amount)
	print("  - Lifetime: ", test_particles.lifetime)
	print("  - Emitting: ", test_particles.emitting)
	print("  - Visible: ", test_particles.visible)
	print("  - Process material: ", test_particles.process_material)
	print("  - Draw pass 1: ", test_particles.draw_pass_1)

func _process(_delta):
	# Press P to print particle status
	if Input.is_action_just_pressed("ui_text_completion_query"):  # Tab key
		_print_status()

func _input(event):
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_P:
				_print_status()
			KEY_R:
				_restart_particles()
			KEY_T:
				_toggle_particles()

func _print_status():
	if test_particles:
		print("\n=== PARTICLE STATUS ===")
		print("  Global Position: ", test_particles.global_position)
		print("  Emitting: ", test_particles.emitting)
		print("  Visible: ", test_particles.visible)
		print("  Amount: ", test_particles.amount)
		print("  In Tree: ", test_particles.is_inside_tree())
		print("  Parent: ", test_particles.get_parent().name if test_particles.get_parent() else "NONE")
	else:
		print("NO TEST PARTICLES!")

func _restart_particles():
	if test_particles:
		test_particles.restart()
		print("Particles restarted")

func _toggle_particles():
	if test_particles:
		test_particles.emitting = !test_particles.emitting
		print("Particles emitting: ", test_particles.emitting)
