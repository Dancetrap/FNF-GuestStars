package backend;

import flash.geom.Point;
import flash.geom.Matrix;
import flixel.math.FlxAngle;
import flixel.FlxCamera;
import flixel.FlxObject;

//Original Lua Script by Raltyro

//According to the zCameraFix script, the point and matrix sections are based on these
//Point: https://api.haxeflixel.com/flash/geom/Point.html
//Matrix: https://api.haxeflixel.com/flash/geom/Matrix.html


/**
    How to use

    1. Call in initialize to add in a camera. I would reccomend doing that in create
    2. Call updateCamera or updateCameras under the update function in your state to run it
    3. Call the destroy function to clear out any camera in the map
    
**/

class FlxCameraFix
{
    static var cameras:Map<FlxCamera, CamMatrix> = new Map<FlxCamera, CamMatrix>();
    static var isReady:Bool = false;

    public static var betterShake:Bool = true;
	public static var betterShakeHardness:Float = .5; //from 0 to 1
	public static var betterShakeFadeTime:Float = .15;
	public static var useScrollForShake:Bool = true;

    public static var selectedCam:FlxCamera = null;
    public static var selectedObject:FlxObject = null;

    //Add in a camera to apply the filter to
    public static function initialize(cams:Array<FlxCamera>)
    {
        isReady = false;
        for(camera in cams) if(!cameras.exists(camera)) cameras.set(camera, new CamMatrix());
        isReady = true;
    }

    //Update a single camera
    public static function updateCamera(camera:FlxCamera, elapsed:Float)
    {
        if(!isReady || !cameras.exists(camera)) return;

        //Set up variables
        var scaleModeX = cameras[camera].ignoreScaleMode ? 1 : FlxG.scaleMode.scale.x;
        var scaleModeY = cameras[camera].ignoreScaleMode ? 1 : FlxG.scaleMode.scale.y;
        var initialZoom = camera.initialZoom;
        var x = camera.x;
        var y = camera.y;

        cameras[camera].zoom = camera.zoom;
        cameras[camera].angle = camera.angle;
        cameras[camera].width = camera.width;
        cameras[camera].height = camera.height;

        //Shake Duration

        var cool = betterShake ? -betterShakeFadeTime : 0;

        cameras[camera].fxShakeDuration = cameras[camera].fxShakeDuration > cool ? cameras[camera].fxShakeDuration - elapsed : cool;

        var _fxShakeIntensity:Float = 0;
        var _fxShakeDuration:Float = 0;
        @:privateAccess _fxShakeIntensity = camera._fxShakeIntensity;
        @:privateAccess _fxShakeDuration = camera._fxShakeDuration;

        if(_fxShakeIntensity > 0 && _fxShakeDuration > 0)
        {
            cameras[camera].fxShakeIntensity = _fxShakeIntensity;
            cameras[camera].fxShakeDuration = _fxShakeDuration;

            @:privateAccess camera._fxShakeIntensity = 0;
        }

        cameras[camera].scale.x = camera.scaleX;
        cameras[camera].scale.y = camera.scaleY;

        cameras[camera].viewOffset.x = x;
        cameras[camera].viewOffset.y = y;

        cameras[camera].skew.setTo(0,0);


        //Modify properties
        if(cameras[camera].fxShakeDuration > cool)
        {
            var sX = cameras[camera].fxShakeIntensity * cameras[camera].width;
            var sY = cameras[camera].fxShakeIntensity * cameras[camera].height;

            var rX, rY = 0.0;
            var rAngle = 0.0; var rSkewX = 0.0; var rSkewY = 0.0;

            if(betterShake)
            {
                var w = (cameras[camera].fxShakeDuration / -cool) + 1;
                var ww = clamp(w, 0, 1) * (-betterShakeHardness + 1);
                var www = clamp(w, 0, 1) * betterShakeHardness;

                cameras[camera].fxShakeI = cameras[camera].fxShakeI + (clamp((cameras[camera].fxShakeIntensity * 7) + .75, 0, 10) * elapsed * clamp(w, 0, 1.5));
                rX = Math.cos(cameras[camera].fxShakeI * 97) * sX * ww;
                rY = Math.sin(cameras[camera].fxShakeI * 86) * sY * ww;
                rAngle = Math.sin(cameras[camera].fxShakeI * 62) * clamp(cameras[camera].fxShakeIntensity * 66, -60, 60) * ww;
                rSkewX = Math.cos(cameras[camera].fxShakeI * 54) * clamp(cameras[camera].fxShakeIntensity * 12, -4, 4) * ww;
                rSkewY = Math.sin(cameras[camera].fxShakeI * 51) * clamp(cameras[camera].fxShakeIntensity * 12, -1.5, 1.5) * ww;

                if (betterShakeHardness > 0)
                {
                    rX = rX + (Math.cos(cameras[camera].fxShakeI * 165) * sX * www);
                    rY = rY + (Math.cos(cameras[camera].fxShakeI * 132) * sY * www);
                    rAngle = rAngle + (Math.sin(cameras[camera].fxShakeI * 111) * clamp(cameras[camera].fxShakeIntensity * 66, -60, 60) * www);
                    rSkewX = rSkewX + (Math.sin(cameras[camera].fxShakeI * 123) * clamp(cameras[camera].fxShakeIntensity * 12, -4, 4) * www);
                    rSkewY = rSkewY + (Math.cos(cameras[camera].fxShakeI * 101) * clamp(cameras[camera].fxShakeIntensity * 12, -1.5, 1.5) * www);
                }
            }
            else
            {
                rX = FlxG.random.float(-sX, sX);
                rY = FlxG.random.float(-sY, sY);
            }

            if (useScrollForShake)
                if(selectedCam != null)
                {
                    if(selectedCam == camera)
                        cameras[camera].scrollOffset.setTo(rX,rY);
                }
                else
                {
                    cameras[camera].scrollOffset.setTo(rX,rY);
                }
            else
                cameras[camera].viewOffset.add(new Point(rX * cameras[camera].zoom, rY * cameras[camera].zoom));

            cameras[camera].angle += rAngle;
            cameras[camera].skew.add(new Point(rSkewX, rSkewY));
        }
        else
        {
            cameras[camera].scrollOffset.setTo(0,0);
        }

        var scaleX = cameras[camera].scale.x;
        var scaleY = cameras[camera].scale.y;

        var isNumber = Type.typeof(camera.canvas.x) == TInt || Type.typeof(camera.canvas.x) == TFloat;
        if(isNumber)
        {
            var width = (cameras[camera].width * cameras[camera].spriteScale.x);
            var height = (cameras[camera].height * cameras[camera].spriteScale.y);
            
            var ratio = cameras[camera].width / width;
            
            var aW = width * cameras[camera].anchorPoint.x;
            var aH = height * cameras[camera].anchorPoint.y;

            var mat:Matrix = cameras[camera]._matrix;
            mat.identity();
            translate(mat, -aW, -aH);
            scale(mat, scaleX, scaleY);
            rotate(mat, cameras[camera].angle); //Rotate //The original rotate method for the matrix wasn't working correctly for some weird reason, so I modified it
            skew(mat, cameras[camera].skew.x, cameras[camera].skew.y); //Skew //Matrix doesn't have a skew method
            translate(mat, aW, aH); //Anchor Points
            translate(mat, cameras[camera].viewOffset.x, cameras[camera].viewOffset.y); //Offsets
            scale(mat, scaleModeX * cameras[camera].spriteScale.x, scaleModeY * cameras[camera].spriteScale.y); //ScaleMode

            @:privateAccess camera.canvas.__transform.a = mat.a;
            @:privateAccess camera.canvas.__transform.b = mat.b;
            @:privateAccess camera.canvas.__transform.c = mat.c;
            @:privateAccess camera.canvas.__transform.d = mat.d;
            @:privateAccess camera.canvas.__transform.tx = mat.tx;
            @:privateAccess camera.canvas.__transform.ty = mat.ty;
        }

        camera.flashSprite.rotation = 0;
        camera.flashSprite.x = 0;
        camera.flashSprite.y = 0;
        @:privateAccess camera._flashOffset.x = (cameras[camera].width * .5) * scaleModeX * initialZoom - (x * scaleModeX);
        @:privateAccess camera._flashOffset.y = (cameras[camera].height * .5) * scaleModeY * initialZoom - (y * scaleModeY);

        if(camera == selectedCam && isNumber)
        {
            if(selectedObject != null)
            {
                selectedObject.x += cameras[camera].scrollOffset.x;
                selectedObject.y += cameras[camera].scrollOffset.y;
            }
        }
        else
        {
            camera.scroll.x += cameras[camera].scrollOffset.x;
            camera.scroll.y += cameras[camera].scrollOffset.y;
        }

        cameras[camera]._lastScrollOffset.setTo(cameras[camera].scrollOffset.x, cameras[camera].scrollOffset.y);
    }

    //Update every camera in list
    public static function updateCameras(elapsed:Float)
    {
        if(!isReady) return;
        //iterate over every single camera in this list

        for(camera in cameras.keys())
        {
            updateCamera(camera, elapsed);
        }
    }

    public static function earlyUpdate(camera:FlxCamera)
    {
        if(camera == selectedCam)
        {
            if(selectedObject != null)
            {
                selectedObject.x -= cameras[camera]._lastScrollOffset.x;
                selectedObject.y -= cameras[camera]._lastScrollOffset.y;
            }
        }
        else
        {
            camera.scroll.x -= cameras[camera]._lastScrollOffset.x;
            camera.scroll.y -= cameras[camera]._lastScrollOffset.y;
        }
    }

    public static function updateCamerasEarly(elapsed:Float)
    {
        for(camera in cameras.keys())
        {
            earlyUpdate(camera);
        }
    }


    //Clear all cameras from list
    public static function destroy()
    {
        selectedCam = null;
        selectedObject = null;
        isReady = false;
        cameras.clear();
    }

    //Additional functions
    static function clamp(x:Float, min:Float, max:Float):Float
    {
        return Math.max(min, Math.min(x, max));
    }

    static function skew(mat:Matrix, x:Float = 0, y:Float = 0)
    {
		var skb = Math.tan(FlxAngle.asRadians(y));
        var skc = Math.tan(FlxAngle.asRadians(x));
		
		mat.b = mat.a * skb + mat.b;
		mat.c = mat.c + mat.d * skc;
		
		mat.ty = mat.tx * skb + mat.ty;
		mat.tx = mat.tx + mat.ty * skc;

        return mat;
    }

    static function rotate(mat:Matrix, theta:Float = 0)
    {
		var rad = FlxAngle.asRadians(theta);
		var rotCos = Math.cos(rad);
        var rotSin = Math.sin(rad);
		
		var a1 = mat.a * rotCos - mat.b * rotSin;
		mat.b = mat.a * rotSin + mat.b * rotCos;
		mat.a = a1;
		
		var c1 = mat.c * rotCos - mat.d * rotSin;
		mat.d = mat.c * rotSin + mat.d * rotCos;
		mat.c = c1;
		
		var tx1 = mat.tx * rotCos - mat.ty * rotSin;
		mat.ty = mat.tx * rotSin + mat.ty * rotCos;
		mat.tx = tx1;
		
		return mat;
    }

    static function translate(mat:Matrix, x:Float = 0, y:Float = 0)
    {
        mat.tx = mat.tx + x;
        mat.ty = mat.ty + y;
        return mat;
    }

    static function scale(mat:Matrix, sx:Float = 0, sy:Float = 0)
    {
		mat.a = mat.a * sx;
		mat.b = mat.b * sy;
		mat.c = mat.c * sx;
		mat.d = mat.d * sy;
		mat.tx = mat.tx * sx;
		mat.ty = mat.ty * sy;
		
		return mat;
    }	

    
}

class CamMatrix
{
    public var zoom:Float = 1;
    public var visible:Bool = true;
    public var width:Int = 1280;
    public var height:Int = 720;
    public var scale:Point = new Point(1,1);
    public var spriteScale:Point = new Point(1,1);
    public var x:Float = 0;
    public var y:Float = 0;
    public var anchorPoint:Point = new Point(0.5,0.5);
    public var offset:Point = new Point();
    public var skew:Point = new Point();
    public var clipSkew:Point = new Point();
    public var transform:Matrix = new Matrix();
    public var _matrix:Matrix = new Matrix();
    public var viewOffset:Point = new Point();
    public var angle:Float = 0;
    public var scrollOffset:Point = new Point();
    public var _lastScrollOffset:Point = new Point();
    public var ignoreScaleMode:Bool = false;
    public var fxShakeIntensity:Float = 0;
    public var fxShakeDuration:Float = -1000;
    public var fxShakeI:Float = -999999;

    public function new()
    {
        
    }
}