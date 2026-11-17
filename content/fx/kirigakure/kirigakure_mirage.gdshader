// Kirigakure (hiding in mist) - mirage shader for the character sprite.
// Each pixel row of the sprite slides sideways on a travelling wave (whole pixels only, so the pixel art stays
// crisp), and the sprite fades out with an ordered dither instead of smooth transparency.
// Drive `amount` and `visibility` from code over time (see kirigakure.json for the curves).
shader_type canvas_item;

// 0 = still, 1 = full wobble
uniform float amount : hint_range(0.0, 1.0) = 0.0;
// 1 = fully visible, 0 = gone. 0.25 while invisible lets the player still see themself.
uniform float visibility : hint_range(0.0, 1.0) = 1.0;
// max sideways shift in texture pixels at amount = 1
uniform float wave_px = 2.5;
// how quickly the wave changes from row to row (radians per pixel row)
uniform float wave_freq = 0.55;
// how fast the wave travels (radians per second)
uniform float wave_speed = 7.0;
// a second, slower wave mixed in so the wobble does not look mechanical
uniform float wave2_mix : hint_range(0.0, 1.0) = 0.4;
// pale haze tint while fading
uniform vec4 haze_color : source_color = vec4(0.80, 0.88, 1.0, 1.0);
uniform float haze_strength : hint_range(0.0, 1.0) = 0.35;
// false: smooth transparency (reads as a mirage). true: ordered-dither fade (retro screen-door look).
uniform bool dither_fade = false;

const float BAYER[16] = float[16](
	0.0 / 16.0,  8.0 / 16.0,  2.0 / 16.0, 10.0 / 16.0,
	12.0 / 16.0, 4.0 / 16.0, 14.0 / 16.0,  6.0 / 16.0,
	3.0 / 16.0, 11.0 / 16.0,  1.0 / 16.0,  9.0 / 16.0,
	15.0 / 16.0, 7.0 / 16.0, 13.0 / 16.0,  5.0 / 16.0
);

// the sprite's modulate / vertex color, kept apart from the texture (in fragment, COLOR already includes the texture)
varying vec4 v_modulate;

void vertex() {
	v_modulate = COLOR;
}

void fragment() {
	vec2 texel = floor(UV / TEXTURE_PIXEL_SIZE);               // this pixel in texture pixels
	float row = texel.y;
	float w = sin(row * wave_freq + TIME * wave_speed)
	        + wave2_mix * sin(row * wave_freq * 0.37 - TIME * wave_speed * 0.6 + 1.7);
	w /= (1.0 + wave2_mix);
	float shift = round(w * wave_px * amount);                  // whole pixels only
	vec2 uv = (texel + vec2(-shift, 0.0) + 0.5) * TEXTURE_PIXEL_SIZE;
	vec4 c = texture(TEXTURE, uv);

	// pale haze as it fades
	float haze = haze_strength * (1.0 - visibility) * amount;
	c.rgb = mix(c.rgb, haze_color.rgb, haze);

	if (dither_fade) {
		int i = int(mod(texel.x, 4.0)) + int(mod(texel.y, 4.0)) * 4;
		if (visibility < 1.0 && BAYER[i] >= visibility) discard;
	} else {
		c.a *= visibility;
	}
	COLOR = c * v_modulate;
}
