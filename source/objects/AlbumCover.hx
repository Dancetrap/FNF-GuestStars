package objects;

class AlbumCover extends FlxSprite
{
    private var sprTracker:FlxSprite;
    private var trackerOffset:FlxPoint;
    private var lerpDelay:Float;
    private var song:String = '';

    public function new(?x:Float = 0, ?y:Float = 0, song:String = 'bugz', ?allowGPU:Bool = true)
    {
        super(x,y);
        changeCover(song, allowGPU);
        scrollFactor.set();
    }

    override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (sprTracker != null)
        {
            if(lerpDelay == 0)
            {
                setPosition(sprTracker.x + trackerOffset.x, sprTracker.y + trackerOffset.y);
            }
            else
            {
                x = FlxMath.lerp(x, sprTracker.x + trackerOffset.x, FlxMath.bound(elapsed * lerpDelay,0,1));
                y = FlxMath.lerp(y, sprTracker.y + trackerOffset.y, FlxMath.bound(elapsed * lerpDelay,0,1));
            }
        }
			
	}

    public function changeCover(song:String, ?allowGPU:Bool = true)
    {
		if(this.song != song) {
			var name:String = 'albums/' + song;
            if(!Paths.fileExists('images/' + name + '.png', IMAGE)) name = 'albums/cover';
            var graphic = Paths.image(name, allowGPU);
			loadGraphic(graphic, true);
            this.song = song;
			antialiasing = ClientPrefs.data.antialiasing;
        }
    }

    public function getSong():String {
		return song;
	}

    public function setTracker(sprite:FlxSprite, x:Float = 0, y:Float = 0, lerp:Float = 0)
    {
        sprTracker = sprite;
        trackerOffset = new FlxPoint(x,y);
        lerpDelay = lerp;
        setPosition(sprTracker.x + trackerOffset.x, sprTracker.y + trackerOffset.y);
    }
}