shader_type canvas_item;
uniform float center: hint_range(0.1, 1.0) = 0.85;
uniform float slope : hint_range(0.0, 8.0) = 4.0;
uniform float width : hint_range(0.0, 1.0) = 1.0;
uniform float height : hint_range(0.0, 1.0) = 1.0;

void fragment() {
	float shrink_width = 2.0 / width;
	float shrink_height = 2.0 / height;
	float dist = distance(vec2(UV.x * shrink_width, UV.y * shrink_height) / center, vec2(shrink_width, shrink_height) * 0.5 / center);
	float fade = pow(dist, slope) - dist;
	
	COLOR = texture(TEXTURE, UV);
	COLOR.a = min(1.0 - fade, texture(TEXTURE, UV).a);
}
