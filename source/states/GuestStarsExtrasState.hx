package states;

import backend.Highscore;
import backend.TrackData;
import flixel.addons.display.FlxBackdrop;
import flixel.addons.display.FlxGridOverlay;
import flixel.addons.plugin.FlxScrollingText;
import flixel.text.FlxBitmapText;
import flixel.text.FlxBitmapFont;
import openfl.geom.Rectangle;
import flixel.FlxObject;
import flixel.addons.display.shapes.FlxShapeCircle;

import flixel.graphics.FlxGraphic;

import flixel.effects.particles.FlxEmitter;
import flixel.effects.particles.FlxParticle;

import states.GuestStarsLogsState;

import objects.GradientBG;

class GuestStarsExtrasState extends MusicBeatState
{
    // Overall Stuff
    var extrasList:Array<String> = ["cast", "logs", "gallery"];
    static var curExtra:Int = 0;
    public var selectedExtra:String;

    // Logs Section
    public var logsState:FlxSpriteGroup;
    var inLog:Bool;
    public var logIcons:FlxTypedSpriteGroup<LogIcon>;
    var yPoses:Array<Float> = [];
    var camFollow:FlxObject;
    public static var curLog:Int = 0;
    public static var curY:Int = 0;

    var logDescriptionTxt:FlxText;

    // Gallery Section
    public var gallerySection:FlxSpriteGroup;
    var galleryDescriptionTxt:FlxText;
    
    //Special effects
    var today:Date = Date.now();
    var holiday:Bool = false;
    var holidayColors:Array<FlxColor> = [];

    override function create()
    {
        super.create();
        persistentUpdate = true;

        TrackData.reloadTracksFiles(false);
        GuestStarsLogsState.loadLogs();
        
        Difficulty.list = ["Normal"];
        PlayState.storyDifficulty = 1;

        camFollow = new FlxObject(0, 0, 1, 1);
		add(camFollow);

        if(today.getMonth() == 9) //It is a spooky month!
        {
            holidayColors.push(0xFFe87800);
            holidayColors.push(0xFF1d0029);
            holiday = true;
        }
        else if(today.getMonth() == 11 && today.getDate() <= 25) //IT IS KRIMA!!!!
        {
            holidayColors.push(0xFFff7878);
            holidayColors.push(0xFF74d680);
            holiday = true;
        }

        var bg = new GradientBG(0,0,FlxG.width, FlxG.height, holiday ? holidayColors[0] :0xFF7700ff, holiday ?  holidayColors[1] : 0xff0300aa);
		bg.scrollFactor.set(0,0);
		bg.updateHitbox();
		bg.screenCenter();
		bg.time = 0.5;
        bg.scrollFactor.set();
        bg.updateHitbox();
		add(bg);

        var grid:FlxBackdrop = new FlxBackdrop(FlxGridOverlay.createGrid(80, 80, 160, 160, true, 0x33FFFFFF, 0x0));
		grid.velocity.set(50, 50);
		grid.alpha = 0;
		FlxTween.tween(grid, {alpha: 1}, 0.5, {ease: FlxEase.quadOut});
        grid.angle = 15;
        grid.scrollFactor.set();
        grid.updateHitbox();
		add(grid);

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

        FlxTween.angle(grid, 15, 375, 30, {type: LOOPING});
        FlxTween.tween(grid, {"scale.x": 1.25, "scale.y": 1.25}, 5, {type: PINGPONG, ease: FlxEase.sineInOut});

        logsState = new FlxSpriteGroup();
        add(logsState);

        logIcons = new FlxTypedSpriteGroup<LogIcon>();
        logsState.add(logIcons);

        var x = FlxG.width/5;
        var y = FlxG.height/4;

        yPoses.push(y);
        for(i in 0...GuestStarsLogsState.logFiles.length)
        {
            var log:LogIcon = new LogIcon(x, y, GuestStarsLogsState.logFiles[i]);
            log.ID = i;
            logIcons.add(log);

            x += 200;
            if(x > FlxG.width/5 + 600)
            {
                y += 200;
                x = FlxG.width/5;
                yPoses.push(y);
            }
        }

        var topBar = new FlxSprite().makeGraphic(FlxG.width, 75,FlxColor.BLACK);
        topBar.scrollFactor.set();
        topBar.updateHitbox();
        logsState.add(topBar);

        bottomBar = new FlxSprite(0, FlxG.height - 75).makeGraphic(FlxG.width, 75,FlxColor.BLACK);
        bottomBar.scrollFactor.set();
        bottomBar.updateHitbox();
        logsState.add(bottomBar);

        logDescriptionTxt = new FlxText(0, bottomBar.y + bottomBar.height/2, 0, "", 48);
        logDescriptionTxt.setFormat(Paths.font("nikkyou.ttf"), 48, FlxColor.WHITE);
        logDescriptionTxt.scrollFactor.set();
        logDescriptionTxt.updateHitbox();
        logDescriptionTxt.y -= logDescriptionTxt.height/2;
        logDescriptionTxt.screenCenter(X);
        logsState.add(logDescriptionTxt);

        changeLogs();

        // FlxG.camera.follow(camFollow, null, 9);
    }
    
    private var bottomBar:FlxSprite;
    override function update(elapsed:Float)
    {
        super.update(elapsed);

        if(FlxG.mouse.justMoved || FlxG.mouse.justPressed)
        {
            mouseMode = true;
        }

        if(!inLog)
        {
            if (controls.UI_LEFT_P)
            {
                changeLogs(-1);
                holdTime = 0;
            }
            if (controls.UI_RIGHT_P)
            {
                changeLogs(1);
                holdTime = 0;
            }
        
            if(controls.UI_LEFT || controls.UI_RIGHT)
            {
                var checkLastHold:Int = Math.floor((holdTime - 0.5) * 10);
                holdTime += elapsed;
                var checkNewHold:Int = Math.floor((holdTime - 0.5) * 10);
        
                if(holdTime > 0.5 && checkNewHold - checkLastHold > 0)
                    changeLogs((checkNewHold - checkLastHold) * (controls.UI_LEFT ? -1 : 1));
            }

            if (controls.UI_UP_P)
            {
                changeLogs(-4);
                holdTime = 0;
            }
            if (controls.UI_DOWN_P)
            {
                changeLogs(4);
                holdTime = 0;
            }
            
            if(controls.UI_UP || controls.UI_DOWN)
            {
                var checkLastHold:Int = Math.floor((holdTime - 0.5) * 10);
                holdTime += elapsed;
                var checkNewHold:Int = Math.floor((holdTime - 0.5) * 10);
            
                if(holdTime > 0.5 && checkNewHold - checkLastHold > 0)
                    changeLogs((checkNewHold - checkLastHold) * (controls.UI_UP ? -4 : 4));
            }

            if(controls.BACK)
                {
                    FlxG.sound.play(Paths.sound('cancelMenu'));
                    // MusicBeatState.switchState(new MainMenuState());
                    MusicBeatState.switchState(new GuestStarsMainMenuState());
                }

                logIcons.forEach(function(icon:LogIcon){
                    if(FlxG.mouse.overlaps(icon) && mouseMode)
                    {
                        for(logs in logIcons)
                            logs.isSelected = false;
        
                        icon.isSelected = true;
                        curLog = icon.ID;
                        if(prevLog != curLog) setCurLog();
                    }
        
        
                    if(controls.ACCEPT || (FlxG.mouse.overlaps(icon) && FlxG.mouse.justPressed))
                    {
                        // if(!icon.isLocked)
                        // {
                        //     inLog = true;
                        // }
                        // inLog = true;
                        // persistentUpdate = false;
                        icon.open(FlxG.mouse.justPressed);
                        if(!icon.isLocked && icon.isSelected)
                        {
                            inLog = true;
                        }
                    }
                        
                });
        }
        // if(controls.ACCEPT)
        // {
        //     inLog = true;
        //     persistentUpdate = false;
        //     // openSubState(new GuestStarsLogEntry(GuestStarsLogsState.logFiles[0].text));
        // }

        logDescriptionTxt.screenCenter(X);

    }

    var holdTime:Float;
    var mouseMode:Bool;

    override function closeSubState() {
		persistentUpdate = true;
		inLog = false;
		super.closeSubState();
	}

    var prevLog:Int;
    private var prevY:Float;
    
    function changeLogs(change:Int = 0)
    {
        curLog += change;
        mouseMode = false;
        if(change == 0)
        {
            if(curLog >= GuestStarsLogsState.logFiles.length) curLog = GuestStarsLogsState.logFiles.length - 1;
            else if(curLog < 0) curLog = 0;
        }
        else if(change <= 1 && change >= -1)
        {
            if(curLog >= GuestStarsLogsState.logFiles.length) curLog = 0;
            else if(curLog < 0) curLog = GuestStarsLogsState.logFiles.length - 1;
        }
        else
        {
            if(curLog >= GuestStarsLogsState.logFiles.length) //This is always positive
            {
                var length = GuestStarsLogsState.logFiles.length;
                while(length % change != 0)
                {
                    length++;
                }

                if(length > curLog) length -= change;

                curLog = curLog % length;
            }
            else if(curLog < 0) //This is negative btw
            {
                var length = GuestStarsLogsState.logFiles.length;
                while(length % change != 0)
                {
                    length++;
                }

                var ideal = length + curLog;

                if(ideal >= GuestStarsLogsState.logFiles.length) ideal += change;

                curLog = ideal;
            }
        }

        setCurLog();
    }

    function setCurLog()
    {
        logIcons.forEach(function(icon:LogIcon){
            icon.isSelected = false;

            if(icon.ID == curLog)
            {
                icon.isSelected = true;
                logDescriptionTxt.text = icon.description;
                logDescriptionTxt.size = 48;
                // if(logDescriptionTxt.width > FlxG.width)
                //     logDescriptionTxt.size = 36;
                var s = logDescriptionTxt.size;
                while(logDescriptionTxt.width > FlxG.width)
                {
                    s -= 4;
                    logDescriptionTxt.size = s;
                }

                // trace(prevY);
                if(prevY != icon.yValue)
                {
                    curY = yPoses.indexOf(icon.yValue);
                    // trace(curY);
                    FlxTween.cancelTweensOf(logIcons);
                    FlxTween.tween(logIcons, {y: -(FlxG.height/4 + 20)*curY}, mouseMode ? 0.5 : 0.2, {ease: FlxEase.quadInOut});
                }
                prevY = icon.yValue;
                
                logDescriptionTxt.y = bottomBar.y + bottomBar.height/2 - logDescriptionTxt.height/2;
                prevY = icon.y;
            }
                
        });

        prevLog = curLog;
    }
}

class GalleryImage extends FlxSprite {

    public function new(image:String, ?animationName:String = null, ?looped:Bool = true)
    {
        super();
        if(animationName != null)
        {
			frames = Paths.getSparrowAtlas("gallery/" + image);
            animation.addByPrefix(animationName, animationName, 24, looped);
            animation.play(animationName);
        }
        else
        {
			if(image != null) {
				loadGraphic(Paths.image("gallery/" + image));
			}
        }

        antialiasing = ClientPrefs.data.antialiasing;
    }
}