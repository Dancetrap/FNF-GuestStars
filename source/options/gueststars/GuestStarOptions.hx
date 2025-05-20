package options.gueststars;

import flixel.util.FlxGradient;
import flixel.group.FlxSpriteGroup;

class GuestStarOptions extends MusicBeatSubstate
{
    // var options:Array<String> = ['Note Colors', 'Controls', 'Delay/Combo', 'Graphics', 'Visuals/UI', 'Gameplay'];
    // var options:Array<String> = ['Note Colors', 'Controls', 'Graphics', 'Visuals/UI', 'Gameplay'];
    final options:Array<String> = ['Controls', 'Graphics', 'Visuals/UI', 'Gameplay'];
    var optionTxt:FlxSpriteGroup;
    public static var curOption:Int = 0;
    public static var inPlayState:Bool = false;
    static var prevState:Bool = false;
    var hasSelectedOption:Bool = false;
    var isClosing:Bool = false;

    //Transition Stuff
    var mockTransitionIn:FlxSprite;
    var mockTransitionOut:FlxSprite;
    var blackTransIn:FlxSprite;
    var blackTransOut:FlxSprite;
    var duration = 0.6;

    var finishCallback:Void->Void = null;
    var pauseSong:Null<String>;
    var volume:Float;
    var playSFX:Bool;
    public static var pauseMusicTime:Null<Float>;
    public static var curTime:Float = 0;
    public static var curVol:Float = 0;
    public var pauseMusic:FlxSound;

    var optionBox:FlxSprite;

    // public static var instance:GuestStarOptions;
    

    public function new(callback:Void->Void = null, ?songName:Null<String> = null, ?curVolume:Float = 1, ?playSFX:Bool = false)
    {
        this.finishCallback = callback;
        this.pauseSong = songName;
        this.volume = curVolume;
        this.playSFX = playSFX;

        curVol = curVolume;

        // instance = this;

        super();
    }

    override function create() {
		#if DISCORD_ALLOWED
		DiscordClient.changePresence("Options Menu", null);
		#end
        
        cameras = [FlxG.cameras.list[FlxG.cameras.list.length-1]];

        if(inPlayState)
        {
            var bg:FlxSprite = new FlxSprite().makeGraphic(1, 1, FlxColor.BLACK);
            bg.scale.set(FlxG.width, FlxG.height);
            bg.updateHitbox();
            bg.alpha = 0.6;
            bg.scrollFactor.set();
            add(bg);
        }

        //Add options here
        optionTxt = new FlxSpriteGroup(50);
        optionTxt.scrollFactor.set();
        optionTxt.updateHitbox();
        add(optionTxt);
        
        if(pauseSong != null)
        {
            pauseMusic = new FlxSound();
            pauseMusic.loadEmbedded(Paths.music(pauseSong), true, true);
            pauseMusic.volume = volume;
            pauseMusic.play(false, pauseMusicTime);
            FlxG.sound.list.add(pauseMusic);
        }

        for(i in 0...options.length)
        {
            var option:FlxText = new FlxText(0, i * 100, 0, options[i], 36);
            option.setFormat(Paths.font("nikkyou.ttf"), 72, FlxColor.WHITE, "left");
            option.ID = i;
            option.scrollFactor.set();
            option.updateHitbox();
            optionTxt.add(option);
        }

        optionTxt.screenCenter(Y);

        //Mock transition
        if(!inPlayState)
        {
            var width:Int = Std.int(FlxG.width / Math.max(camera.zoom, 0.001));
            var height:Int = Std.int(FlxG.height / Math.max(camera.zoom, 0.001));

            mockTransitionIn = FlxGradient.createGradientFlxSprite(1, height, [0x0, FlxColor.BLACK]);
            mockTransitionIn.scale.x = width;
            mockTransitionIn.updateHitbox();
            mockTransitionIn.scrollFactor.set();
            mockTransitionIn.screenCenter(X);
            add(mockTransitionIn);
    
            blackTransIn = new FlxSprite().makeGraphic(1, 1, FlxColor.BLACK);
            blackTransIn.scale.set(width, height + 400);
            blackTransIn.updateHitbox();
            blackTransIn.scrollFactor.set();
            blackTransIn.screenCenter(X);
            add(blackTransIn);

            mockTransitionOut = FlxGradient.createGradientFlxSprite(1, height, [FlxColor.BLACK, 0x0]);
            mockTransitionOut.scale.x = width;
            mockTransitionOut.updateHitbox();
            mockTransitionOut.scrollFactor.set();
            mockTransitionOut.screenCenter(X);
            add(mockTransitionOut);

            blackTransOut = new FlxSprite().makeGraphic(1, 1, FlxColor.BLACK);
            blackTransOut.scale.set(width, height + 400);
            blackTransOut.updateHitbox();
            blackTransOut.scrollFactor.set();
            blackTransOut.screenCenter(X);
            add(blackTransOut);
    
            mockTransitionIn.y = blackTransIn.y - blackTransIn.height;
            mockTransitionOut.y = -mockTransitionOut.height;
            blackTransOut.y = mockTransitionOut.y - blackTransOut.height;
        }

        changeMenu();

        // optionBox = new FlxSprite(FlxG.width).makeGraphic(600, 600, FlxColor.GRAY);
        // optionBox.scrollFactor.set();
        // optionBox.updateHitbox();
        // optionBox.screenCenter(Y);
        // add(optionBox);

        optionBox = new FlxSprite(FlxG.width).loadGraphic(Paths.image("menuStuff/box"));
        optionBox.scrollFactor.set();
        optionBox.setGraphicSize(720, 600);
        optionBox.updateHitbox();
        optionBox.antialiasing = ClientPrefs.data.antialiasing;
        optionBox.screenCenter(Y);
        add(optionBox);

        super.create();
    }

    var isLeaving:Bool = false;
    override function update(elapsed:Float)
    {
        super.update(elapsed);

        if (pauseMusic != null)
        {
            if (pauseMusic.volume < 0.5)
			    pauseMusic.volume += 0.01 * elapsed;

            curTime = pauseMusic.time;
            curVol = pauseMusic.volume;
        }

        final height:Float = FlxG.height * Math.max(camera.zoom, 0.001);

        //Transition Stuff
        if(!inPlayState)
        {
            final targetPosIn:Float = mockTransitionIn.height + 50 * Math.max(camera.zoom, 0.001);
            final targetPosOut:Float = mockTransitionOut.height + 50 * Math.max(camera.zoom, 0.001);

            if(duration > 0)
                mockTransitionIn.y += (height + targetPosOut) * elapsed / duration;
            else
                mockTransitionIn.y = (targetPosOut) * elapsed;
                
            blackTransIn.y = mockTransitionIn.y + mockTransitionIn.height;

            if(isClosing)
            {
                if(duration > 0)
                    mockTransitionOut.y += (height + targetPosOut) * elapsed / duration;
                else
                    mockTransitionOut.y = (targetPosOut) * elapsed;

                blackTransOut.y = mockTransitionOut.y - blackTransOut.height;

                if(mockTransitionOut.y >= targetPosOut)
                {
                    if(finishCallback != null) finishCallback();
                    finishCallback = null;
                    close();
                }
            }
        }

        if(FlxG.keys.getIsDown().length > 0)
            mouseMode = false;
        else if(FlxG.mouse.justMoved)
            mouseMode = true;

        for(text in optionTxt.members)
        {
            text.x = FlxMath.lerp(text.x, (text == optionTxt.members[curOption] ? optionTxt.x + 50 : optionTxt.x), FlxMath.bound(elapsed * 7, 0, 1));
        }

        if(hasSelectedOption)
        {
            if(controls.BACK)
            {
                hasSelectedOption = false;
                FlxTween.cancelTweensOf(optionBox);
                FlxTween.tween(optionBox, {x: FlxG.width}, 1, {ease: FlxEase.circInOut});
            }
        }
        else
        {
            if(!isLeaving)
            {
                if(controls.UI_UP_P)
                    changeMenu(-1, true);
        
                if(controls.UI_DOWN_P)
                    changeMenu(1, true);
    
                if(controls.ACCEPT)
                    selectMenu();
    
                optionTxt.forEach(function(txt:FlxSprite){
                    if(FlxG.mouse.overlaps(txt))
                    {
                        if(txt.ID != curOption && mouseMode)
                        {
                            curOption = txt.ID;
                            changeMenu(0, true);
                        }
    
                        if(txt.ID == curOption)
                        {
                            if(FlxG.mouse.justPressed)
                            {
                                selectMenu();
                            }
                        }
                    }
                });
    
                if(controls.BACK)
                {
                    isLeaving = true;
                    if(playSFX) FlxG.sound.play(Paths.sound('cancelMenu'));
                    if(!inPlayState)
                    {
                        isClosing = true;
                    }
                    else
                    {
                        if(finishCallback != null) finishCallback();
                        finishCallback = null;
                        close();
                    }
                }
            }

        }
        
    }

    var mouseMode:Bool;

    override function destroy()
	{
		if(pauseMusic != null) 
        {
            pauseMusic.destroy();
        }

		super.destroy();
	}

    function changeMenu(change:Int = 0, playSound:Bool = false)
    {
        if(playSound) FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
        curOption += change;
        if(curOption >= options.length) curOption = 0;
        else if(curOption < 0) curOption = options.length - 1;
    }

    function selectMenu()
    {
        hasSelectedOption = true;
        FlxTween.cancelTweensOf(optionBox);
        FlxTween.tween(optionBox, {x: FlxG.width - optionBox.width - 25}, 1, {ease: FlxEase.circInOut});
    }
}

/**
    Options List
        Controls -
            * Left Note
            * Down Note
            * Up Note
            * Right Note
            * Left UI
            * Down UI
            * Up UI
            * Right UI
            * Reset
            * Accept
            * Back
            * Pause
            * Mute
            * Volume Up
            * Volume Down
        Graphics - 
            * Low Quality
            * Anti-Aliasing
            * Shaders
            * GPU Caching
            * Framerate
        Visuals -
            * Flashing Lights
            * Camera Zooms
            * FPS Counter
            * Combo Stacking
            * Time Bar
        Gameplay -
            * Downscroll
            * Middlescroll
            * Auto Pause
            * Mechanics
**/