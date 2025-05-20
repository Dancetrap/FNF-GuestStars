package backend;

import flixel.graphics.FlxGraphic;
import openfl.display.BitmapData;
import openfl.utils.Assets as OpenFlAssets;
import flixel.system.FlxAssets;

class LoadingTransition extends MusicBeatSubstate {
	public static var finishCallback:Void->Void;
	var isTransIn:Bool = false;
	var image:FlxSprite;
    public static var imageFile:Null<String>;
    public static var folder:Null<String>;
    public var graphic:FlxGraphicAsset;

    var width:Int;
    var height:Int;

    var newWidth:Float;
    var newHeight:Float;

	var duration:Float;
    var multiple:Float = 1.2;

	public function new(duration:Float, isTransIn:Bool, file:String = 'funkay', library:String = 'assets/shared/')
	{
		this.duration = duration;
		this.isTransIn = isTransIn;
        if(imageFile == null)
            imageFile = file;
        if(folder == null)
            folder = library;
		super();
	}

    override function create()
    {
        cameras = [FlxG.cameras.list[FlxG.cameras.list.length-1]];
        width = Std.int(FlxG.width / Math.max(camera.zoom, 0.001));
        height = Std.int(FlxG.height / Math.max(camera.zoom, 0.001));

        //This is so that it won't automatically go to assets/shared it doesn't exist
        var path = folder + 'images/$imageFile.png';

        var bitmap:BitmapData = null;
        graphic = 'assets/shared/images/funkay.png';
        #if MODS_ALLOWED
		if (Paths.currentTrackedAssets.exists(path))
		{
			Paths.localTrackedAssets.push(path);
			graphic = Paths.currentTrackedAssets.get(path);
		}
		else if (FileSystem.exists(path))
			bitmap = BitmapData.fromFile(path);
		else
		#end
		{
			if (Paths.currentTrackedAssets.exists(path))
			{
				Paths.localTrackedAssets.push(path);
				graphic = Paths.currentTrackedAssets.get(path);
			}
			else if (OpenFlAssets.exists(path, IMAGE))
				bitmap = OpenFlAssets.getBitmapData(path);
		}

		if (bitmap != null)
		{
			graphic = Paths.cacheBitmap(path, bitmap);
		}

        // image = new FlxSprite().loadGraphic(Paths.image(imageFile));
        image = new FlxSprite().loadGraphic(graphic);
        image.scrollFactor.set();
        var factor = isTransIn ? 1 : multiple;
        image.setGraphicSize(Std.int(width * factor), Std.int(height * factor));
        // image.setGraphicSize(width, height);
        image.updateHitbox();
        add(image);


        image.antialiasing = ClientPrefs.data.antialiasing;


        image.alpha = !isTransIn ? 0 : 1;
        image.screenCenter();

        // The width will automatically update the height
        newWidth = image.width;
        // newHeight = image.height;

        super.create();
    }

    override function update(elapsed:Float) {
		super.update(elapsed);

        var targetAlpha = -1;
        var targetWidth = 0;
        var targetHeight = 0;


        if(isTransIn)
        {
            targetAlpha = 0;
            image.alpha -= FlxMath.bound(elapsed / duration * 2, 0, 1);
            newWidth += 100*(elapsed / duration);
            newWidth = FlxMath.bound(newWidth,  width, width * multiple); 

        }
        else
        {
            targetAlpha = 1;
            image.alpha += FlxMath.bound(elapsed / duration * 2, 0, 1);
            newWidth -= 750*(elapsed / duration);
            newWidth = FlxMath.bound(newWidth,  width, width * multiple); 

        }

        image.setGraphicSize(Std.int(newWidth));
        image.updateHitbox();
        if(image.alpha == targetAlpha)
        {
            if(isTransIn) { imageFile = null; folder = null; }
            close();
			if(finishCallback != null) finishCallback();
			finishCallback = null;
        }

        image.screenCenter();

		// final height:Float = FlxG.height * Math.max(camera.zoom, 0.001);
		// final targetPos:Float = transGradient.height + 50 * Math.max(camera.zoom, 0.001);
		// if(duration > 0)
		// 	transGradient.y += (height + targetPos) * elapsed / duration;
		// else
		// 	transGradient.y = (targetPos) * elapsed;

		// if(isTransIn)
		// 	transBlack.y = transGradient.y + transGradient.height;
		// else
		// 	transBlack.y = transGradient.y - transBlack.height;

		// if(transGradient.y >= targetPos)
		// {
		// 	close();
		// 	if(finishCallback != null) finishCallback();
		// 	finishCallback = null;
		// }
	}
}