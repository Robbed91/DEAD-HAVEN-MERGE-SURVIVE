extends SceneTree
## Converts the generated magenta-backed source renders into transparent,
## consistently-sized source and runtime PNGs. The edge calculation also
## removes magenta spill from antialiased pixels without erasing dark shadows.

const SOURCE_SIZE := 1024
const RUNTIME_SIZE := 256

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() != 3:
		push_error("Usage: --script tools/process_icon_chroma.gd -- <input> <source-output> <runtime-output>")
		quit(2)
		return
	var image := Image.load_from_file(args[0])
	if image == null or image.is_empty():
		push_error("Could not load %s" % args[0])
		quit(3)
		return
	image.convert(Image.FORMAT_RGBA8)
	image.resize(SOURCE_SIZE, SOURCE_SIZE, Image.INTERPOLATE_LANCZOS)
	_remove_magenta(image)
	var source_error: Error = image.save_png(args[1])
	var runtime := image.duplicate()
	runtime.resize(RUNTIME_SIZE, RUNTIME_SIZE, Image.INTERPOLATE_LANCZOS)
	var runtime_error: Error = runtime.save_png(args[2])
	if source_error != OK or runtime_error != OK:
		push_error("PNG export failed: source=%s runtime=%s" % [source_error, runtime_error])
		quit(4)
		return
	print("ICON_PROCESSED %s -> %s, %s" % [args[0], args[1], args[2]])
	quit()

func _remove_magenta(image: Image) -> void:
	for y in image.get_height():
		for x in image.get_width():
			var c := image.get_pixel(x, y)
			# Magenta compositing is identified by red and blue both exceeding
			# green. Neutral steel, timber, cloth, rust and soft black shadows
			# remain opaque because they do not have this paired dominance.
			var dominance := minf(c.r, c.b) - c.g
			if dominance <= 0.035:
				c.a = 1.0
			else:
				var alpha := 1.0 - smoothstep(0.035, 0.42, dominance)
				if alpha < 0.015:
					c = Color(0, 0, 0, 0)
				else:
					# Undo the magenta matte approximately for clean scaled edges.
					c.r = clampf((c.r - (1.0 - alpha)) / alpha, 0.0, 1.0)
					c.g = clampf(c.g / alpha, 0.0, 1.0)
					c.b = clampf((c.b - (1.0 - alpha)) / alpha, 0.0, 1.0)
					c.a = alpha
			image.set_pixel(x, y, c)
