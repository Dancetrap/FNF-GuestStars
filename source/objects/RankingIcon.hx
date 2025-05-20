package objects;

import backend.Highscore;
import haxe.Json;

typedef RankingOffsets =
{
    F:Array<Float>,
    D:Array<Float>,
    C:Array<Float>,
    B:Array<Float>,
    A:Array<Float>,
    FC:Array<Float>,
    P:Array<Float>,
    NaN:Array<Float>,
}

class RankingIcon extends FlxSprite
{
    public var valueFunction:Void->Float = null;
    public var offsets:Null<FlxPoint> = null;
    public var offsetList:Map<String, Array<Dynamic>> = new Map<String, Array<Dynamic>>();

    public var includeOffsets:Bool;
    public var autoCallback:Void->Void;

    public function new(x:Float = 0, y:Float = 0, ?startValue:String = "NaN", ?valueFunction:Void->Float = null, ?includeOffsets:Bool = false, ?autoCallback:Void->Void = null)
    {
        super(x,y);
        frames = Paths.getSparrowAtlas("ranking/guest_stars_rankings");
        animation.addByPrefix('P','P',24);
        animation.addByPrefix('FC','FC',24);
        animation.addByPrefix('S','S',24);
        animation.addByPrefix('A','A',24);
        animation.addByPrefix('B','B',24);
        animation.addByPrefix('C','C',24);
        animation.addByPrefix('D','D',24);
        animation.addByPrefix('F','F0',24);
        animation.addByPrefix('NaN','NaN',24);
        antialiasing  = ClientPrefs.data.antialiasing;
        animation.play(animation.exists(startValue) ? startValue : 'NaN');

        this.valueFunction = valueFunction;
        this.includeOffsets = includeOffsets;
        this.autoCallback = autoCallback;

        var json:RankingOffsets = tjson.TJSON.parse(Paths.getTextFromFile('images/ranking/offsets.json'));
        // trace(json != null);
        if(json != null)
        {
            // trace(json);
            var stringified = Json.stringify(json).replace("{","").replace("}","").replace(":","").replace("],","]");
            var stringifiedArray = stringified.split('"');
            var lettersArray = stringifiedArray.filter(function(s){ return !s.contains("[") && s != ""; });
            var offsetsArray = stringifiedArray.filter(function(s){ return s.contains("["); });

            for(i => letters in lettersArray)
            {
                var str = offsetsArray[i];
                var array = str.substr(1,str.length-2).split(",").map(Std.parseInt);
                offsetList.set(letters, array);
            }
        }

        for(names in animation.getNameList())
        {
            if(!offsetList.exists(names)) offsetList.set(names, [0,0]);
        }
    }

    override function update(elapsed:Float) {
        super.update(elapsed);

        if(valueFunction != null)
		{
            playByAccuracy(valueFunction(), true, autoCallback, true);
		}

        scale.x = FlxMath.lerp(scale.x, scaleX, Math.exp(-elapsed * 9));
        scale.y = FlxMath.lerp(scale.y, scaleY, Math.exp(-elapsed * 9));
    }

    public function playByAccuracy(accuracy:Float, ?misses:Int = -1, ?ignoreNaN:Bool = false, ?callback:Void->Void = null, ?anim:Bool = false)
    {
        var previous:String = animation.curAnim.name;
        var grade:String = Highscore.getRanking(accuracy, misses, ignoreNaN);
        playAnim(grade, previous, callback, anim);
        return grade;
    }

    public function playBySongScore(songName:String, songDifficulty:Int, ?callback:Void->Void = null, ?anim:Bool = false)
    {
        var previous:String = animation.curAnim.name;
        var grade:String = Highscore.getGrade(songName, songDifficulty);
        playAnim(grade, previous, callback, anim);
        return grade;
    }

    function playAnim(name:String, previous:String, ?callback:Void->Void = null, ?anim:Bool = false)
    {
        animation.play(name);
        if(includeOffsets) offset.set(offsetList[name][0], offsetList[name][1]);
        if(offsets != null)
        {
            x = offsets.x;
            y = offsets.y;
        }
        if(animation.curAnim.name != previous)
        {
            if(anim)
            {
                scale.x = 1.3 * scaleX;
                scale.y = 1.3 * scaleY;
            }
            if(callback != null)
                callback();
        }
    }

    public var scaleX:Float = 1;
    public var scaleY:Float = 1;
    override public function setGraphicSize(width = 0.0, height = 0.0)
    {
        super.setGraphicSize(width, height);
        scaleX = scale.x;
        scaleY = scale.y;
        // trace(scale.x);
        // trace(scale.y);
    }
}