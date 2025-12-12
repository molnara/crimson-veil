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
	
	# NEW: Test 7-13: Automatic audio playback tests
	await test_sound_playback()
	
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

# Automatic audio playback tests
func test_sound_playback():
	print("\n============================================================")
	print("AUDIO PLAYBACK TESTS (Listen for sounds!)")
	print("============================================================\n")
	
	# Test 7: Harvesting sounds
	print("[TEST 7] Testing harvesting sounds...")
	print("  Playing axe_chop...")
	AudioManager.play_sound("axe_chop", "sfx")
	await get_tree().create_timer(1.5).timeout
	
	print("  Playing pickaxe_hit...")
	AudioManager.play_sound("pickaxe_hit", "sfx")
	await get_tree().create_timer(1.5).timeout
	
	print("  Playing mushroom_pick...")
	AudioManager.play_sound("mushroom_pick", "sfx")
	await get_tree().create_timer(1.5).timeout
	print("  ✓ Harvesting sounds tested\n")
	
	# Test 8: Footstep variants
	print("[TEST 8] Testing footstep variants...")
	print("  Playing random grass footsteps (3 variants)...")
	for i in range(4):
		AudioManager.play_sound_variant("footstep_grass", 3, "sfx")
		await get_tree().create_timer(0.4).timeout
	print("  ✓ Footstep variants tested\n")
	
	# Test 9: Building sounds
	print("[TEST 9] Testing building sounds...")
	print("  Playing block_place...")
	AudioManager.play_sound("block_place", "sfx")
	await get_tree().create_timer(1.0).timeout
	
	print("  Playing block_remove...")
	AudioManager.play_sound("block_remove", "sfx")
	await get_tree().create_timer(1.5).timeout
	print("  ✓ Building sounds tested\n")
	
	# Test 10: UI sounds
	print("[TEST 10] Testing UI sounds...")
	print("  Playing inventory_toggle...")
	AudioManager.play_sound("inventory_toggle", "ui")
	await get_tree().create_timer(1.0).timeout
	
	print("  Playing craft_complete...")
	AudioManager.play_sound("craft_complete", "ui")
	await get_tree().create_timer(1.5).timeout
	print("  ✓ UI sounds tested\n")
	
	# Test 11: Container sounds
	print("[TEST 11] Testing container sounds...")
	print("  Playing chest_open...")
	AudioManager.play_sound("chest_open", "sfx")
	await get_tree().create_timer(1.5).timeout
	
	print("  Playing chest_close...")
	AudioManager.play_sound("chest_close", "sfx")
	await get_tree().create_timer(1.5).timeout
	print("  ✓ Container sounds tested\n")
	
	# Test 12: Music tracks
	print("[TEST 12] Testing music playback...")
	print("  Playing ambient_day_1 with 2 second fade...")
	AudioManager.play_music("ambient_day_1", 2.0)
	await get_tree().create_timer(5.0).timeout
	
	print("  Crossfading to ambient_night_1...")
	AudioManager.play_music("ambient_night_1", 2.0)
	await get_tree().create_timer(5.0).timeout
	
	print("  Stopping music...")
	AudioManager.stop_music(2.0)
	await get_tree().create_timer(3.0).timeout
	print("  ✓ Music system tested\n")
	
	# Test 13: Ambient loops
	print("[TEST 13] Testing ambient loops...")
	print("  Starting wind_light loop...")
	AudioManager.play_ambient_loop("wind_light")
	await get_tree().create_timer(3.0).timeout
	
	print("  Starting ocean_waves loop (layering)...")
	AudioManager.play_ambient_loop("ocean_waves")
	await get_tree().create_timer(3.0).timeout
	
	print("  Stopping wind_light...")
	AudioManager.stop_ambient_loop("wind_light", 1.0)
	await get_tree().create_timer(2.0).timeout
	
	print("  Stopping ocean_waves...")
	AudioManager.stop_ambient_loop("ocean_waves", 1.0)
	await get_tree().create_timer(2.0).timeout
	print("  ✓ Ambient loops tested\n")
	
	print("\n============================================================")
	print("ALL AUDIO TESTS COMPLETED!")
	print("============================================================\n")
	print("Press ESC to exit, or use manual test keys below...")

# Manual tests (require audio files)
func _input(event):
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_1:
				print("\n[MANUAL TEST] Playing harvesting sounds...")
				AudioManager.play_sound("axe_chop", "sfx")
				await get_tree().create_timer(0.5).timeout
				AudioManager.play_sound("pickaxe_hit", "sfx")
			
			KEY_2:
				print("\n[MANUAL TEST] Sound pool stress test...")
				print("  Playing 15 sounds rapidly (pool max = 10)...")
				for i in range(15):
					AudioManager.play_sound("axe_chop", "sfx")
					await get_tree().create_timer(0.05).timeout
				print("  Active sounds: %d" % AudioManager.get_active_sound_count())
			
			KEY_3:
				print("\n[MANUAL TEST] Testing all footstep surfaces...")
				print("  Grass...")
				AudioManager.play_sound_variant("footstep_grass", 3, "sfx")
				await get_tree().create_timer(0.5).timeout
				print("  Stone...")
				AudioManager.play_sound_variant("footstep_stone", 3, "sfx")
				await get_tree().create_timer(0.5).timeout
				print("  Sand...")
				AudioManager.play_sound_variant("footstep_sand", 3, "sfx")
				await get_tree().create_timer(0.5).timeout
				print("  Snow...")
				AudioManager.play_sound_variant("footstep_snow", 3, "sfx")
			
			KEY_4:
				print("\n[MANUAL TEST] Playing day music...")
				AudioManager.play_music("ambient_day_1", 2.0)
			
			KEY_5:
				print("\n[MANUAL TEST] Playing night music...")
				AudioManager.play_music("ambient_night_1", 2.0)
			
			KEY_6:
				print("\n[MANUAL TEST] Starting ambient loops...")
				AudioManager.play_ambient_loop("wind_light")
				AudioManager.play_ambient_loop("birds_day")
			
			KEY_7:
				print("\n[MANUAL TEST] AudioManager status:")
				AudioManager.print_status()
			
			KEY_8:
				print("\n[MANUAL TEST] Run full audio test suite...")
				test_sound_playback()
			
			KEY_0:
				print("\n[MANUAL TEST] Stopping all audio...")
				AudioManager.stop_all_sounds()
				print("  All audio stopped\n")

func _exit_tree():
	print("\n[INFO] Manual test controls:")
	print("  Press 1: Play harvesting sounds")
	print("  Press 2: Sound pool stress test")
	print("  Press 3: Test all footstep surfaces")
	print("  Press 4: Play day music")
	print("  Press 5: Play night music")
	print("  Press 6: Start ambient loops")
	print("  Press 7: Print AudioManager status")
	print("  Press 8: Run full audio test suite")
	print("  Press 0: Stop all audio\n")
