package states;

import options.gueststars.GuestStarOptions;
import flixel.addons.transition.FlxTransitionableState;
import objects.GradientBG;
import flixel.addons.display.FlxBackdrop;
import flixel.effects.particles.FlxEmitter;
import flixel.effects.particles.FlxParticle;

class GuestStarOptionsState extends MusicBeatState
{
    var bg:GradientBG;

    var colors:Array<Array<FlxColor>> = [];
    var today:Date = Date.now();
    var holiday:Bool;
    var holidayColors:Array<FlxColor> = [];

    override function create()
    {
        FlxTransitionableState.skipNextTransIn = true;
        FlxTransitionableState.skipNextTransOut = true;
        persistentUpdate = true;

        // var bg:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLUE);
        // bg.scrollFactor.set();
        // bg.updateHitbox();
        // add(bg);

        if(today.getMonth() == 9) //It's da spooky month!
        {
            holidayColors.push(0xFFe87800);
            holidayColors.push(0xFF1d0029);
            holiday = true;
        }
        else if(today.getMonth() == 11 && today.getDate() <= 25)
        {
            holidayColors.push(0xFFff7878);
            holidayColors.push(0xFF74d680);
            holiday = true;
        }

        bg = new GradientBG(0,0,FlxG.width, FlxG.height, holiday ? holidayColors[0] : 0xFF7700ff, holiday ? holidayColors[1] : 0xFFc4ab5e);
		bg.scrollFactor.set(0,0);
		bg.updateHitbox();
		bg.screenCenter();
		bg.time = 0.5;
		add(bg);

        if(today.getMonth() == 11 && today.getDate() <= 25)
        {
            var snow:FlxEmitter = new FlxEmitter(0,0,300);

            for(i in 0...150)
            {
                var p1 = new FlxParticle();
                var p2 = new FlxParticle();

                p1.makeGraphic(2,2);
                p2.makeGraphic(5,5);

                snow.add(p1);
                snow.add(p2);
            }

            snow.width = FlxG.width;
            snow.launchMode = SQUARE;
            snow.velocity.set(-20, 80, 0, 120);
            snow.lifespan.set(0);

            add(snow);
            snow.start(false, 0.05);
        }

        var grid:FlxBackdrop = new FlxBackdrop(Paths.image("noteColorMenu/titledCheckeredPattern"));
		grid.velocity.set(40, 40);
		grid.alpha = 0;
		FlxTween.tween(grid, {alpha: 1}, 0.5, {ease: FlxEase.quadOut});
        grid.angle = 15;
		add(grid);

        var topBar = new FlxSprite().makeGraphic(FlxG.width, 75,FlxColor.BLACK);
        topBar.scrollFactor.set();
        topBar.updateHitbox();
        add(topBar);

        var bottomBar = new FlxSprite(0, FlxG.height - 75).makeGraphic(FlxG.width, 75,FlxColor.BLACK);
        bottomBar.scrollFactor.set();
        bottomBar.updateHitbox();
        add(bottomBar);

        super.create();

        GuestStarOptions.inPlayState = false;
        openSubState(new GuestStarOptions(returnToMainMenu, true));
    }

    override function update(elapsed:Float)
    {
        super.update(elapsed);
        mouseLook();
    }

    function returnToMainMenu()
    {
        MusicBeatState.switchState(new GuestStarsMainMenuState());
    }

    var xx:Float = 0;
    var yy:Float = 0;
    var zoom:Float = 1;
    var zz:Float = 1;
    var outOfRange = false;

    var mx:Float = 0;
    var my:Float = 0;

    var lerpVal = 0.04;

    function mouseLook() {
    
        mx = (FlxG.mouse.screenX - 640) / 10;
        my = (FlxG.mouse.screenY - 320) / 10;
    
        xx = FlxMath.lerp(xx, mx,lerpVal);
        yy = FlxMath.lerp(yy, my, lerpVal);
    
        FlxG.camera.scroll.x = xx;
        FlxG.camera.scroll.y = yy;
    
    }
}