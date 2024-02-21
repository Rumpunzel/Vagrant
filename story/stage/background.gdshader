shader_type canvas_item;

uniform float size = 10.0;

void fragment() {
	vec4 color = textureLod(TEXTURE, UV, 0.0);
	for (float x = -size; x < size; x++) {
		for (float y = -size; y < size; y++) {
			if (x * x + y * y > size * size) continue;
			vec4 new_color = texture(TEXTURE, UV + TEXTURE_PIXEL_SIZE * vec2(x, y));
			if (length(new_color) > length(color)) color = new_color * new_color * 1.25;
		}
	}
	COLOR = color;
}
