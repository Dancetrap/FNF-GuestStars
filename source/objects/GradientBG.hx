package objects;

import flixel.system.FlxAssets.FlxShader;

class GradientBG extends FlxSprite
{
    var gradient:GradientEffect = null;

    public var startColor:FlxColor = FlxColor.WHITE;
    public var endColor:FlxColor = FlxColor.BLACK;
    public var time(default, set):Float = 8;

    var curStart:FlxColor;
    var curEnd:FlxColor;

    public function new(x:Float,y:Float,width:Int,height:Int, start:FlxColor = FlxColor.WHITE, end:FlxColor = FlxColor.BLACK)
    {
        super(x,y);
        makeGraphic(width,height,FlxColor.WHITE);

        gradient = new GradientEffect();
        shader = gradient.shader;

        startColor = curStart = start;
        endColor = curEnd = end;

        gradient.startColor = [startColor.redFloat, startColor.greenFloat, startColor.blueFloat, 1.0];
        gradient.endColor = [endColor.redFloat, endColor.greenFloat, endColor.blueFloat, 1.0];
    }

    override function update(elapsed) {
        super.update(elapsed);

        curStart.redFloat = FlxMath.lerp(curStart.redFloat, startColor.redFloat, elapsed * time);
        curStart.greenFloat = FlxMath.lerp(curStart.greenFloat, startColor.greenFloat, elapsed * time);
        curStart.blueFloat = FlxMath.lerp(curStart.blueFloat, startColor.blueFloat, elapsed * time);

        curEnd.redFloat = FlxMath.lerp(curEnd.redFloat, endColor.redFloat, elapsed * time);
        curEnd.greenFloat = FlxMath.lerp(curEnd.greenFloat, endColor.greenFloat, elapsed * time);
        curEnd.blueFloat = FlxMath.lerp(curEnd.blueFloat, endColor.blueFloat, elapsed * time);

        setGradientShader(curStart, curEnd);
    }

    public function setGradient(start:FlxColor, end:FlxColor)
    {
        startColor = start;
        endColor = end;
    }

    public function setGradientImmediate(start:FlxColor, end:FlxColor)
    {
        startColor = curStart = start;
        endColor = curEnd = end;
        setGradientShader(curStart, curEnd);
    }

    private function setGradientShader(start:FlxColor, end:FlxColor)
    {
        gradient.startColor = [start.redFloat, start.greenFloat, start.blueFloat, 1.0];
        gradient.endColor = [end.redFloat, end.greenFloat, end.blueFloat, 1.0];
    }

    private function set_time(value:Float):Float
    {
        time = value;
        return time;
    }
}

class GradientEffect
{
    public var shader(default, null):GradientShader = new GradientShader();
    public var startColor(default, set):Array<Float> = [0.0,0.0,0.0,1.0];
    public var endColor(default, set):Array<Float> = [1.0,1.0,1.0,1.0];

    private function set_startColor(value:Array<Float>)
    {
        startColor = value;
        shader.startColor.value = value;
        return startColor;
    }

    private function set_endColor(value:Array<Float>)
    {
        endColor = value;
        shader.endColor.value = value;
        return endColor;
    }

    public function new()
    {
        shader.startColor.value = [0.0,0.0,0.0,1.0];
        shader.endColor.value = [1.0,1.0,1.0,1.0];
    }
}

class GradientShader extends FlxShader {
	@:glFragmentSource('
// Automatically converted with https://github.com/TheLeerName/ShadertoyToFlixel

#pragma header

#define round(a) floor(a + 0.5)
#define iResolution vec3(openfl_TextureSize, 0.)
uniform float iTime;
#define iChannel0 bitmap
uniform sampler2D iChannel1;
uniform sampler2D iChannel2;
uniform sampler2D iChannel3;
#define texture flixel_texture2D

// third argument fix
vec4 flixel_texture2D(sampler2D bitmap, vec2 coord, float bias) {
	vec4 color = texture2D(bitmap, coord, bias);
	if (!hasTransform)
	{
		return color;
	}
	if (color.a == 0.0)
	{
		return vec4(0.0, 0.0, 0.0, 0.0);
	}
	if (!hasColorTransform)
	{
		return color * openfl_Alphav;
	}
	color = vec4(color.rgb / color.a, color.a);
	mat4 colorMultiplier = mat4(0);
	colorMultiplier[0][0] = openfl_ColorMultiplierv.x;
	colorMultiplier[1][1] = openfl_ColorMultiplierv.y;
	colorMultiplier[2][2] = openfl_ColorMultiplierv.z;
	colorMultiplier[3][3] = openfl_ColorMultiplierv.w;
	color = clamp(openfl_ColorOffsetv + (color * colorMultiplier), 0.0, 1.0);
	if (color.a > 0.0)
	{
		return vec4(color.rgb * color.a * openfl_Alphav, color.a * openfl_Alphav);
	}
	return vec4(0.0, 0.0, 0.0, 0.0);
}

// variables which is empty, they need just to avoid crashing shader
uniform float iTimeDelta;
uniform float iFrameRate;
uniform int iFrame;
#define iChannelTime float[4](iTime, 0., 0., 0.)
#define iChannelResolution vec3[4](iResolution, vec3(0.), vec3(0.), vec3(0.))
uniform vec4 iMouse;
uniform vec4 iDate;

uniform vec4 startColor = vec4(1.0, 0.0, 0.0, 1.0);
uniform vec4 endColor = vec4(0.0, 1.0, 0.0, 1.0);
    
void mainImage( out vec4 fragColor, in vec2 fragCoord )
{   
    vec2 uv = fragCoord.xy / iResolution.xy;
    
    vec2 origin = vec2(0.5, 0.5);
    uv -= origin;
    
    float angle = radians(-90.0) + atan(uv.y, uv.x);

    float len = length(uv);
    uv = vec2(cos(angle) * len, sin(angle) * len) + origin;
	    
    fragColor = mix(startColor, endColor, smoothstep(0.0, 1.0, uv.x));
}

void main() {
	mainImage(gl_FragColor,openfl_TextureCoordv*openfl_TextureSize);
}
    ')
    public function new()
    {
        super();
    }
}

