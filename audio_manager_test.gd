extends Node

# AudioManager Test Script
# Attach this to a test scene to verify AudioManager functionality

func _ready():
	print("\n============================================================")
	print("AUDIO MANAGER TEST SUITE")
	print("============================================================\n")
	
	# Wait for AudioManager to initialize
	await get_tree().process_frame
	
	# Test 1: Check if AudioManager exists
	test_singleton_exists()
	
	# Test 2: Check volume levels
	test_volume_levels()
	
	# Test 3: Check sound pool
	test_sound_pool()
	
	# Test 4: Test volume setters
	test_volume_setters()
	
	# Test 5: Check music player
	test_music_player()
	
	# Test 6: Test category volume calculation
	test_category_volumes()
	
	print("\n============================================================")
	print("ALL TESTS COMPLETED")
	print("============================================================\n")

func test_singleton_exists():
	print("[TEST 1] Checking AudioManager singleton...")
	
	if AudioManager:
		print("  ✓ AudioManager exists")
		print("  ✓ Accessible as global singleton")
	else:
		print("  ✗ AudioManager not found!")
	
	print("")

func test_volume_levels():
	print("[TEST 2] Checking default volume levels...")
	
	assert(AudioManager.master_volume == 1.0, "Master volume incorrect")
	print("  ✓ Master: %.2f" % AudioManager.master_volume)
	
	assert(AudioManager.sfx_volume == 0.75, "SFX volume incorrect")
	print("  ✓ SFX: %.2f" % AudioManager.sfx_volume)
	
	assert(AudioManager.music_volume == 0.35, "Music volume incorrect")
	print("  ✓ Music: %.2f" % AudioManager.music_volume)
	
	assert(AudioManager.ambient_volume == 0.25, "Ambient volume incorrect")
	print("  ✓ Ambient: %.2f" % AudioManager.ambient_volume)
	
	assert(AudioManager.ui_volume == 0.60, "UI volume incorrect")
	print("  ✓ UI: %.2f" % AudioManager.ui_volume)
	
	print("")

func test_sound_pool():
	print("[TEST 3] Checking sound pool creation...")
	
	var pool_size = AudioManager.sound_pool.size()
	assert(pool_size == 10, "Pool size incorrect")
	print("  ✓ Pool created with %d players" % pool_size)
	
	var active_count = AudioManager.active_sounds.size()
	assert(active_count == 0, "Active sounds should be 0")
	print("  ✓ Active sounds: %d" % active_count)
	
	# Check that all players are children of AudioManager
	var child_players = 0
	for child in AudioManager.get_children():
		if child is AudioStreamPlayer and child.name.begins_with("PooledPlayer"):
			child_players += 1
	
	assert(child_players == 10, "Not all pool players are children")
	print("  ✓ All pool players are child nodes")
	
	print("")

func test_volume_setters():
	print("[TEST 4] Testing volume setter functions...")
	
	# Test master volume
	AudioManager.set_master_volume(0.8)
	assert(AudioManager.master_volume == 0.8, "Master volume setter failed")
	print("  ✓ Master volume setter works")
	
	# Test SFX volume
	AudioManager.set_sfx_volume(0.9)
	assert(AudioManager.sfx_volume == 0.9, "SFX volume setter failed")
	print("  ✓ SFX volume setter works")
	
	# Test music volume
	AudioManager.set_music_volume(0.5)
	assert(AudioManager.music_volume == 0.5, "Music volume setter failed")
	print("  ✓ Music volume setter works")
	
	# Test category setter (generic)
	AudioManager.set_category_volume("ambient", 0.3)
	assert(AudioManager.ambient_volume == 0.3, "Category setter failed")
	print("  ✓ Category volume setter works")
	
	# Reset to defaults
	AudioManager.set_master_volume(1.0)
	AudioManager.set_sfx_volume(0.75)
	AudioManager.set_music_volume(0.35)
	AudioManager.set_ambient_volume(0.25)
	print("  ✓ Reset to default volumes")
	
	print("")

func test_music_player():
	print("[TEST 5] Checking music player...")
	
	if AudioManager.music_player:
		print("  ✓ Music player exists")
		assert(AudioManager.music_player.name == "MusicPlayer", "Wrong music player name")
		print("  ✓ Music player named correctly")
		assert(not AudioManager.music_player.playing, "Music should not be playing")
		print("  ✓ Music player idle (not playing)")
	else:
		print("  ✗ Music player not found!")
	
	print("")

func test_category_volumes():
	print("[TEST 6] Testing category volume calculations...")
	
	# Test _get_category_volume (internal function)
	var sfx_vol = AudioManager._get_category_volume("sfx")
	assert(sfx_vol == 0.75, "SFX category volume incorrect")
	print("  ✓ SFX category: %.2f" % sfx_vol)
	
	var music_vol = AudioManager._get_category_volume("music")
	assert(music_vol == 0.35, "Music category volume incorrect")
	print("  ✓ Music category: %.2f" % music_vol)
	
	var ambient_vol = AudioManager._get_category_volume("ambient")
	assert(ambient_vol == 0.25, "Ambient category volume incorrect")
	print("  ✓ Ambient category: %.2f" % ambient_vol)
	
	var ui_vol = AudioManager._get_category_volume("ui")
	assert(ui_vol == 0.60, "UI category volume incorrect")
	print("  ✓ UI category: %.2f" % ui_vol)
	
	print("")

# Manual tests (require audio files)
func _input(event):
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_1:
				print("\n[MANUAL TEST] Attempting to play 'test_sound'...")
				AudioManager.play_sound("test_sound", "sfx")
				print("  Note: Will warn if sound not found (expected before Task 1.2)\n")
			
			KEY_2:
				print("\n[MANUAL TEST] Attempting sound pool stress test...")
				print("  Playing 15 sounds rapidly (pool max = 10)...")
				for i in range(15):
					AudioManager.play_sound("test_sound", "sfx")
					await get_tree().create_timer(0.05).timeout
				print("  Active sounds: %d" % AudioManager.get_active_sound_count())
				print("  Note: Should see warnings about pool being full\n")
			
			KEY_3:
				print("\n[MANUAL TEST] AudioManager status:")
				AudioManager.print_status()
			
			KEY_0:
				print("\n[MANUAL TEST] Stopping all audio...")
				AudioManager.stop_all_sounds()
				print("  All audio stopped\n")

func _exit_tree():
	print("\n[INFO] Test script ending")
	print("  Press 1: Test play_sound() (will warn until files exist)")
	print("  Press 2: Test sound pool stress (15 sounds)")
	print("  Press 3: Print AudioManager status")
	print("  Press 0: Stop all audio\n")
