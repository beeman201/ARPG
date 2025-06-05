shader_type canvas_item;

uniform vec4 old_color : source_color = vec4(1.0, 0.0, 0.0, 1.0); // Red
uniform vec4 new_color : source_color = vec4(0.0, 0.0, 1.0, 1.0); // Blue

void fragment() {
    vec4 original_color = texture(TEXTURE, UV);
    if (distance(original_color.rgb, old_color.rgb) < 1.0) { // Tolerance for matching
        COLOR = new_color;
    } else {
        COLOR = original_color;
    }
}

void vertex() {
	// Called for every vertex the material is visible on.
}

//void light() {
	// Called for every pixel for every light affecting the CanvasItem.
	// Uncomment to replace the default light processing function with this one.
//}


//void light() {
	// Called for every pixel for every light affecting the CanvasItem.
	// Uncomment to replace the default light processing function with this one.
//}
