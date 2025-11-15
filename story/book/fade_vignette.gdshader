shader_type canvas_item;
uniform float power : hint_range(0.2, 4.0, 0.1) = 1.0;
uniform float up : hint_range(0.0, 1.0, 0.001) = 0.1;
uniform float down : hint_range(0.0, 1.0, 0.001) = 0.1;
uniform float left : hint_range(0.0, 1.0, 0.001) = 0.1;
uniform float right : hint_range(0.0, 1.0, 0.001) = 0.1;
uniform float up_clip : hint_range(0.0, 1.0, 0.001) = 0.0;
uniform float down_clip : hint_range(0.0, 1.0, 0.001) = 0.0;
uniform float left_clip : hint_range(0.0, 1.0, 0.001) = 0.0;
uniform float right_clip : hint_range(0.0, 1.0, 0.001) = 0.0;

void fragment() {
	float horizontal = 1.0;
	if (UV.x < left) {
		if (left_clip < left && left_clip > 0.0) {
			if (UV.x < left_clip) {horizontal = 0.0;}
			else {horizontal *= pow((UV.x - left_clip) / (left - left_clip), power);}
		}
		else{
			horizontal *= pow(UV.x / left, power);
		}
	}
	if (UV.x > 1.0 - right) {
		if (right_clip < right && right_clip > 0.0) {
			if (1.0 - UV.x < right_clip) {horizontal = 0.0;}
			else {horizontal *= pow((1.0 - UV.x - right_clip) / (right - right_clip), power);}
		}
		else{
			horizontal *= pow( (1.0 - UV.x) / right, power);
		}
	}

	float vertical = 1.0;
	if (UV.y < up) {
		if (up_clip < up && up_clip > 0.0) {
			if (UV.y < up_clip) {vertical = 0.0;}
			else {vertical *= pow((UV.y - up_clip) / (up - up_clip), power);}
		}
		else{
			vertical *= pow(UV.y / up, power);
		}
	}
	if (UV.y > 1.0-down) {
		if (right_clip < down && down_clip > 0.0) {
			if (1.0 - UV.y < down_clip) {vertical = 0.0;}
			else {vertical = pow((1.0 - UV.y - down_clip) / (down - down_clip), power);}
		}
		else {
			vertical *= pow((1.0 - UV.y) / down, power);
		}
	}
	
	COLOR = texture(TEXTURE, UV);
	COLOR.a = min(horizontal * vertical, texture(TEXTURE, UV).a);
}
