package objects;

import flixel.util.FlxAxes;
import flixel.graphics.FlxGraphic;
import flixel.FlxObject;
import flixel.addons.display.FlxBackdrop;

class FlxEndlessGallery extends FlxSpriteGroup
{
    private var totalWidth:Float;
    private var _maxHeight:Float = Math.NEGATIVE_INFINITY; //For graphics
    private var maxHeight:Float = Math.NEGATIVE_INFINITY; //For backdrops
    private var graphics:Array<FlxGraphic>;
    private var _spacing:Float;
    public var spacing(get, never):Float;
    private var defaultSpacing:Float;

    private var defaultScales:Array<Float> = [];

    private var tallestBD:FlxBackdrop;

    public function new(?x:Int = 0, ?y:Int = 0, ?graphics:Null<Array<FlxGraphic>>, spacing:Float = 0.0, size:Float = 1.0)
    {
        super(x,y);
        this._spacing = spacing;
        this.defaultSpacing = spacing;

        if(graphics != null)
        {
            this.graphics = graphics;
            //Get the total width for each graphic. This will help with spacing
            for(graphic in graphics)
            {
                totalWidth += graphic.width;

                if(size > 10)
                    defaultScales.push(size/graphic.height);
                else if(size > 0)
                    defaultScales.push(size);

            }
            var scale:Float = 1;

            var currentWidth:Float = spacing/defaultScales[0];

            //Add all backdrops into group
            for(graphic in graphics)
            {
                var backdrop:FlxBackdrop = new FlxBackdrop(graphic, X, totalWidth - graphic.width + (spacing/defaultScales[graphics.indexOf(graphic)]) * graphics.length);
                if(backdrop.height > maxHeight)
                {
                    maxHeight = backdrop.height;
                    tallestBD = backdrop;
                }
                    
                //The spacing has to be multiplied with the graphics length, so that the beginning and end can have a spacing, too
                backdrop.x = currentWidth;
                backdrop.ID = graphics.indexOf(graphic);
                backdrop.antialiasing = ClientPrefs.data.antialiasing;
                currentWidth += graphic.width + spacing/defaultScales[graphics.indexOf(graphic)];
                add(backdrop);
            }

            repositionSprites();
            
            if(size > 10) 
                _setMaxHeight(size) 
            else
                setScale(size);

            antialiasing = ClientPrefs.data.antialiasing;
        }
    }

    inline function get_spacing()
    {
        return _spacing;
    }
    
    public function setScale(scale:Float = 1, ?update:Bool = true)
    {
        if(scale <= 0) return;

        if(graphics != null)
        {
            _spacing = defaultSpacing/scale;
            // this.scale.set(scale, scale);
            var currentWidth:Float = _spacing;
            // var newSpacing = spacing * 4;

            //Add all backdrops into group
            for(backdrop in members)
            {
                backdrop.scale.set(scale, scale);
                if(update) backdrop.updateHitbox();
                backdrop.x = currentWidth;
                currentWidth += update ? backdrop.width + _spacing * scale : (backdrop.width + _spacing) * scale;
                backdrop.antialiasing = ClientPrefs.data.antialiasing;
            }

            // _spacing *= scale;

            // trace(_spacing);

            // repositionSprites();
        }
    }

    private function _setMaxHeight(height:Float = 0, ?update:Bool = true, ?stretch:Bool = false)
    {
        _spacing = defaultSpacing/defaultScales[0]; //This is here as a status
        var currentWidth:Float = _spacing;

        trace(defaultScales);

        for(backdrop in members)
        {
            var i:Int = members.indexOf(backdrop);
            _spacing = defaultSpacing/defaultScales[i];
            backdrop.scale.set(defaultScales[i], defaultScales[i]);
            if(update) backdrop.updateHitbox();
            backdrop.x = currentWidth;
            currentWidth += update ? backdrop.width + _spacing * defaultScales[i] : (backdrop.width + _spacing) * defaultScales[i];
        }

        //They'll have to be a lot of fixing here;

        if(stretch)
        {
            for(backdrop in members)
            {
                var stretchScale:Float = height / backdrop.height;
                backdrop.scale.y = stretchScale;
            }
        }
    }

    public function setMaxHeight(height:Float = 0, ?update:Bool = true, ?stretch:Bool = false)
    {
        if(height <= 0) return;

        if(graphics != null)
        {
            defaultScales = [];

            for(backdrop in members)
            {
                defaultScales.push(height/backdrop.frameHeight);
            }

            _setMaxHeight(height, update, stretch);
        }
    }

    public function center()
    {
        for(backdrop in members)
        {
            backdrop.screenCenter(Y);
        }
    }

    public function repositionSprites(position:FlxHeightPositions = TOP)
    {
        for(backdrop in members)
        {
            switch(position)
            {
                case TOP:
                    backdrop.y = tallestBD.y;
                case CENTER:
                    backdrop.y = tallestBD.y + (maxHeight/2) - (backdrop.height/2);
                case BOTTOM:
                    backdrop.y = tallestBD.y + maxHeight - backdrop.height;
            }
        }
    }


}

enum abstract FlxHeightPositions(Int) {
    var TOP = 0;
    var CENTER = 1;
    var BOTTOM = 2;
}