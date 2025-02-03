package objects;

class ComboTrail extends FlxSpriteGroup
{
    public var combo(default, set):Float;
    public var comboColor:FlxColor;
    public var sprite(default, set):FlxSprite;

    var alphaSet:Float = 0;
    var ySet:Float = 0;
    var scaleSet:Float = 1;

    public function new(sprite:FlxSprite, ?color:FlxColor = FlxColor.WHITE)
    {
        super();
        this.sprite = sprite;
        this.comboColor = color;
    }

    override function update(elapsed:Float) {
        for(shadow in members)
        {
            if(shadow != null)
            {
                shadow.x = FlxMath.lerp(shadow.x, shadow.x + Math.sin(shadow.y/10) * (elapsed * 1000), elapsed * 5);
                shadow.scale.x = FlxMath.lerp(shadow.scale.x, 1, elapsed * 5);
                shadow.scale.y = FlxMath.lerp(shadow.scale.y, 1, elapsed * 5);
            }
        }

        if(combo >= 10)
        {
            createTrailObject();
        }

        super.update(elapsed);
    }

    public function createTrailObject()
    {
        var shadow:FlxSprite = new FlxSprite();
        shadow.frames = sprite.frames;
        shadow.animation.addByPrefix('play', sprite.animation.frameName, 0, false);
        shadow.animation.play('play');
        shadow.alpha = alphaSet;
        shadow.color = comboColor;
        shadow.scale.set(scaleSet * sprite.scale.x, sprite.scale.y);
        shadow.updateHitbox();
        shadow.offset.set(sprite.offset.x, sprite.offset.y);
        shadow.blend = ADD;
        add(shadow);

        FlxTween.tween(shadow, {alpha: 0}, 1, {onComplete: function(twn:FlxTween){
            shadow.kill();
            remove(shadow);
        }});
        FlxTween.tween(shadow, {y: shadow.y - ySet}, 1.5);
        FlxTween.tween(shadow, {"scale.x": sprite.scale.x, "scale.y": sprite.scale.y}, 1);
    }

    public function changeSprite(newSprite:FlxSprite, newColor:FlxColor = FlxColor.WHITE)
    {
        sprite = newSprite;
        comboColor = newColor;
    }

    private function set_sprite(value:FlxSprite)
    {
        sprite = value;
        x = sprite.x;
        y = sprite.y;
        return value;
    }

    private function set_combo(value:Float)
    {
        combo = value;
        switch(combo)
        {
            case 0:
                alphaSet = 0;
                ySet = 0;
                scaleSet = 1;
            case 10:
                alphaSet = 0.0125;
                ySet = 125; 
                scaleSet = 1.05;
            case 25:
                alphaSet = 0.025;
                ySet = 250;
                scaleSet = 1.1;
            case 50:
                alphaSet = 0.0375;
                ySet = 375;
                scaleSet = 1.15;
            case 100:
                alphaSet = 0.05;
                ySet = 500;
                scaleSet = 1.2;
        }
        return value;
    }
}