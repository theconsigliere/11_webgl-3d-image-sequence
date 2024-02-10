uniform float time;
uniform float progress;
uniform float uDisplacementStrength;
uniform sampler2D texture1;
uniform sampler2D uDiffuse;
uniform sampler2D uMotion;
uniform sampler2D uPosition;
uniform sampler2D uData;

uniform vec4 resolution;
uniform float uMouse;

varying vec2 vUv;
varying vec3 vPosition;

float PI = 3.141592653589793238;

// function to get the sub uv of the sprite sheet
vec2 getSubUv (vec2 uv, float index) {
	float newIndex = index / 4.;
	vec2 newUv = uv/4.;
	newUv.y += 3./4.;
	newUv.x += floor(fract(newIndex) * 4.) / 4.;
	newUv.y -= floor(fract(newIndex /4.) * 4.) / 4.;
	return newUv;
}


// final blend function between current and next frame and overlaping opacity
vec4 getMap (sampler2D map, float blend, vec2 uv, vec2 uvNext, vec2 displacement, vec2 displacementNext) {
	// get the current and next frame
	vec4 mapData = texture2D(map, uv - displacement*blend);
	vec4 mapDataNext = texture2D(map, uvNext + displacementNext*(1. - blend));
	return mix(mapData, mapDataNext, blend);
} 

// function to get the displacement
vec2 getDisplacement (sampler2D map, vec2 uv, float strength) {
	vec4 tData = texture2D(map, uv);
	vec2 displacement = tData.rg;
	// displacement = (displacement - 0.5) * 2.;
	displacement *= strength;
	return displacement;
}


// rainbow GLSL

vec3 rgb2hsv(vec3 c) {
    vec4 K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
    vec4 p = mix(vec4(c.bg, K.wz), vec4(c.gb, K.xy), step(c.b, c.g));
    vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));
    float d = q.x - min(q.w, q.y);
    float e = 1.0e-10;
    return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}
vec3 hsv2rgb(vec3 c) {
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

void main()	{

	// there is 16 frames in the sprite sheet, uMouse is a float between 0 and 1
	// we can use it to select the frame to display
	float index = mix(1.,15., uMouse);

	
    // sprite sheet is 16 images, to show just one we need to divide the uv by 4
	//	vec2 subUv = vUv / 4.;

	vec2 subUv = getSubUv(vUv, index);

	// smoothly animate between the frames
	// get the next frame
	vec2 subUvNext = getSubUv(vUv, index + 1.);
	// get the blend
	float blend = fract(index);

	// calculate the displacement
	vec2 displacement = getDisplacement(uMotion, subUv, -uDisplacementStrength);
	vec2 displacementNext = getDisplacement(uMotion, subUvNext, -uDisplacementStrength);

	// get the uniforms

	// this described the difference between the frames
	vec4 tMotion = texture2D(uMotion, subUv);
	vec4 tPosition = texture2D(uPosition, subUv);
	vec4 tData = texture2D(uData, subUv);

	vec4 defaultMap = getMap(uDiffuse, blend, subUv, subUvNext, displacement, displacementNext);

	// TRANSITION
    vec4 position = getMap(uPosition, blend, subUv, subUvNext, displacement, displacementNext);

	// transitional value between pixelation and smoothness
	// sin curves move when we have a transition
	float transitional = smoothstep(0.0,1.0, 
	position.y + (1. - 2.* progress) + 
	sin(position.x * 4. + progress * 6. + time) * mix(0.3,.1, abs(0.5 - position.x)) *0.5
	*smoothstep(0.,0.2, progress));

	// pixelifation
	float pixellation = 200.0;
	// geting the uv and lowiering the number to render the pixelation
	// vec2 subUV1 = floor(subUv * pixellation) / pixellation;
	// vec2 subUvNext1 = floor(subUvNext * pixellation + 1.) / pixellation;

	float mixPixellation = (1. - transitional) * 50. * progress;

	vec2 subUV1 = mix(subUv, floor(subUv * pixellation) / pixellation, mixPixellation);
	vec2 subUVNext1 = mix(subUvNext, floor(subUvNext * pixellation + 1.) / pixellation, mixPixellation);

	vec4 color = getMap(uDiffuse, blend, subUV1, subUVNext1, displacement, displacementNext);

	// add rainbow color
	color.a = transitional*defaultMap.a;

	vec3 rainbow = vec3(1., 0.15, .15);
	vec3 hsv = rgb2hsv(rainbow);
	// this is the hue
	hsv.x += 0.4 * (vUv.x + transitional - progress);
	rainbow = hsv2rgb(hsv);

	// mix rainbow intopixel transition
	// mix into the transparency
	color.rgb = mix(color.rgb, rainbow, 0.5 * smoothstep(0.5, 0., abs(0.5 - color.a)));





	gl_FragColor = getMap(uDiffuse, blend, subUv, subUvNext, displacement, displacementNext);

	gl_FragColor = vec4(vec3(mixPixellation), 1.);
	gl_FragColor = color;
	// use the opacity of the original getmap texture (stops pixelation from touching the background)
	gl_FragColor.a = defaultMap.a;
	//gl_FragColor = vec4(vec3(displacement, 1.), 1.);
}