uniform float time;
uniform float progress;
uniform float uDisplacementStrength;
uniform float uMouse;
uniform sampler2D uDiffuse;
uniform sampler2D uMotion;
uniform sampler2D uPosition;
uniform sampler2D uData;
uniform vec4 resolution;
varying vec2 vUv;
varying vec3 vPosition;
float PI = 3.141592653589793238;

vec2 getSubUV(vec2 _dimensions, vec2 _uv, float _index) {
    float index = _index * (1.0 / _dimensions.x);
    vec2 uv = _uv;
    uv /= _dimensions;
    uv.y += (1.0 / _dimensions.y) * (_dimensions.y - 1.0);
    uv.x += floor(fract(index) * _dimensions.x) / _dimensions.x;
    uv.y -= floor(fract(index / _dimensions.y) * _dimensions.y) / _dimensions.y;
    return uv;
}
float range(float oldValue, float oldMin, float oldMax, float newMin, float newMax) {
    vec3 sub = vec3(oldValue, newMax, oldMax) - vec3(oldMin, newMin, oldMin);
    return sub.x * sub.y / sub.z + newMin;
}
vec2 range(vec2 oldValue, vec2 oldMin, vec2 oldMax, vec2 newMin, vec2 newMax) {
    vec2 oldRange = oldMax - oldMin;
    vec2 newRange = newMax - newMin;
    vec2 val = oldValue - oldMin;
    return val * newRange / oldRange + newMin;
}
vec3 range(vec3 oldValue, vec3 oldMin, vec3 oldMax, vec3 newMin, vec3 newMax) {
    vec3 oldRange = oldMax - oldMin;
    vec3 newRange = newMax - newMin;
    vec3 val = oldValue - oldMin;
    return val * newRange / oldRange + newMin;
}
float crange(float oldValue, float oldMin, float oldMax, float newMin, float newMax) {
    return clamp(range(oldValue, oldMin, oldMax, newMin, newMax), min(newMin, newMax), max(newMin, newMax));
}
vec2 crange(vec2 oldValue, vec2 oldMin, vec2 oldMax, vec2 newMin, vec2 newMax) {
    return clamp(range(oldValue, oldMin, oldMax, newMin, newMax), min(newMin, newMax), max(newMin, newMax));
}
vec3 crange(vec3 oldValue, vec3 oldMin, vec3 oldMax, vec3 newMin, vec3 newMax) {
    return clamp(range(oldValue, oldMin, oldMax, newMin, newMax), min(newMin, newMax), max(newMin, newMax));
}
vec4 getMap(sampler2D _tMap, float _blend, vec2 _subUv, vec2 _subUvNext, vec2 _displacement, vec2 _displacementNext) {
    vec4 color = texture(_tMap, _subUv - _displacement * _blend);
    vec4 colorNext = texture(_tMap, _subUvNext + _displacementNext * (1.0 - _blend));
    return mix(color, colorNext, _blend);
}
vec2 remap(vec2 _displacement, float displacementStrength) {
    vec2 displacement;
    displacement.rg = crange(_displacement.rg, vec2(0.0), vec2(1.0), vec2(-1.0), vec2(1.0));
    return displacement * displacementStrength;
}

vec2 getDisplacement(sampler2D _tMotion, vec2 _uv, float _displacement) {
    vec2 displacement = texture(_tMotion, _uv).rg;
    return remap(displacement, _displacement);
}

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
	// vec2 newUV = (vUv - vec2(0.5))*resolution.zw + vec2(0.5);
	float index = mix(1.,15.,uMouse);
	float blend = fract(index);

	vec2 subUV = getSubUV(vec2(4.),vUv, index);
	vec2 subUVNext = getSubUV(vec2(4.),vUv, index+1.);


	vec2 displacement = getDisplacement(uMotion, subUV, uDisplacementStrength);
	vec2 displacementNext = getDisplacement(uMotion, subUVNext, uDisplacementStrength);
	

	vec4 tData = texture2D(uData, subUV);
	vec4 tPosition = texture2D(uPosition, subUV);
	vec4 tMotion = texture2D(uMotion, subUV);

	vec4 def = getMap(uDiffuse, blend, subUV, subUVNext,displacement,displacementNext);

	vec4 position = getMap(uPosition, blend, subUV, subUVNext,displacement,displacementNext);




	float trans = smoothstep(0.0, 1.0,
	position.y + (1. - 2.*progress) +
	sin(position.x * 4. + progress*6. + time)*mix(0.3,.1, abs(0.5-position.x))*0.5*smoothstep(0.,0.2,progress)
	);

	// pixellation
	float pixellation = 200.0;
	
	float mixForUVS = (1. - trans)*50.*progress;

	vec2 subUV1 = mix(subUV, floor(subUV * pixellation) / pixellation, mixForUVS);
	vec2 subUVNext1 = mix(subUVNext, floor(subUVNext * pixellation + 1.0) / pixellation, mixForUVS);

	vec4 color = getMap(uDiffuse, blend, subUV1, subUVNext1,displacement,displacementNext);

	color.a = trans*def.a;



	vec3 rainbow = vec3(1.,0.15,0.15);
	vec3 hsv = rgb2hsv(rainbow);
	hsv.x += 0.8*(vUv.y + trans - progress);
	// hsv.x += 0.1;
	rainbow = hsv2rgb(hsv);

	color.rgb = mix(color.rgb, rainbow, 0.5*smoothstep(0.5,0., abs(0.5 - color.a)));








	gl_FragColor = getMap(uDiffuse, blend, subUV, subUVNext,displacement,displacementNext);
	gl_FragColor = color;
	// gl_FragColor = vec4(rainbow,1.);
	// gl_FragColor.a = def.a;
	// gl_FragColor = vec4(vec3(mixForUVS),1.);
	// gl_FragColor = vec4(vec3(trans),1.);
	// gl_FragColor = vec4(vec3(displacement*1000.,1.),1.);
}