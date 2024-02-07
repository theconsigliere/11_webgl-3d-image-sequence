uniform float time;
uniform float progress;
uniform sampler2D texture1;
uniform sampler2D uDiffuse;
uniform vec4 resolution;
varying vec2 vUv;
varying vec3 vPosition;
float PI = 3.141592653589793238;
void main()	{
	// vec2 newUV = (vUv - vec2(0.5))*resolution.zw + vec2(0.5);
	vec4 diffuse = texture2D(uDiffuse, vUv);
	gl_FragColor = vec4(vUv,0.0,1.);
	gl_FragColor = diffuse;
}