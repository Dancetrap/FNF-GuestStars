package options.gueststars;


class OptionMenu extends FlxSpriteGroup
{
    public var isSelected:Bool = false;
    public var curOpt:Int = 0;

    public function new()
    {
        setUp();
        super();
    }

    public function setUp(){}

    public function open()
    {
        isSelected = true;
    }

    public function close()
    {
        isSelected = false;
    }
}