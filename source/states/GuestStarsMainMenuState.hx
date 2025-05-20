package states;

import backend.WeekData;
import backend.Highscore;
import backend.TrackData;

import flixel.input.keyboard.FlxKey;
import flixel.addons.transition.FlxTransitionableState;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.graphics.frames.FlxFrame;
import flixel.group.FlxGroup;
import flixel.input.gamepad.FlxGamepad;
import haxe.Json;

import flixel.FlxObject;
import flixel.addons.transition.FlxTransitionableState;
import flixel.effects.FlxFlicker;
import lime.app.Application;
import states.editors.MasterEditorMenu;
import options.OptionsState;
import objects.GradientBG;
import objects.FlxEndlessGallery;

import flixel.addons.display.FlxBackdrop;
import flixel.addons.display.FlxGridOverlay;
import flixel.addons.display.FlxStarField;
import flixel.effects.particles.FlxEmitter;
import flixel.effects.particles.FlxParticle;

import flixel.util.FlxGradient;
import flixel.addons.display.FlxStarField;

import openfl.Assets;
import openfl.display.Bitmap;
import openfl.display.BitmapData;

import shaders.ColorSwap;

import states.StoryMenuState;
import states.OutdatedState;
import states.MainMenuState;

import substates.RankingSubState;

class GuestStarsMainMenuState extends MusicBeatState
{
    public static var inMainMenu:Bool = true;
    public static var initialized:Bool = false;

    var optionShit:Array<Array<Dynamic>> = [
		['play', 100],
		['gallery', 350],
		['credits', 470]
	];

    var optionBar:String = 'options';

    var colors:Array<FlxColor> = [FlxColor.RED, FlxColor.ORANGE, FlxColor.YELLOW, FlxColor.GREEN, FlxColor.CYAN, FlxColor.BLUE, FlxColor.PURPLE, FlxColor.MAGENTA];
	static var color:Int = 4;
    var whiteBG:GradientBG;
    var topBar:FlxSprite;
    var bottomBar:FlxSprite;
    var dancingSprite:FlxSprite;
    public static var bpm:Float;

    var menuItems:FlxTypedGroup<FlxSprite>;
    static var curSelection:Int = 0;

    var defaultX:Float = 15;
    var mouseMode:Bool = false;

    //Special effects
    var today:Date = Date.now();
    var holiday:Bool = false;
    var holidayColors:Array<FlxColor> = [];

    override public function create():Void
    {
        Paths.clearStoredMemory();

		#if LUA_ALLOWED
		Mods.pushGlobalMods();
		#end
		Mods.loadTopMod();

		FlxG.fixedTimestep = false;
		FlxG.game.focusLostFramerate = 60;
		FlxG.keys.preventDefaultKeys = [TAB];
        persistentUpdate = true;

        super.create();

        Highscore.load();
		TrackData.reloadTracksFiles();

        var secColor = color + 1;
		if(secColor >= colors.length) secColor = 0;

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

		whiteBG = new GradientBG(0,0,FlxG.width, FlxG.height, holiday ? holidayColors[0] : colors[color], holiday ? holidayColors[1] : colors[secColor]);
		whiteBG.scrollFactor.set(0,0);
		whiteBG.updateHitbox();
		whiteBG.screenCenter();
		whiteBG.time = 0.5;
		add(whiteBG);

        // Paths.image("noteColorMenu/titledCheckeredPattern")
        var grid:FlxBackdrop = new FlxBackdrop(FlxGridOverlay.createGrid(80, 80, 160, 160, true, 0x33FFFFFF, 0x0));
		grid.velocity.set(50, 50);
		grid.alpha = 0;
		FlxTween.tween(grid, {alpha: 1}, 0.5, {ease: FlxEase.quadOut});
        grid.angle = 15;
		add(grid);

        FlxTween.angle(grid, 15, 375, 30, {type: LOOPING});
        FlxTween.tween(grid, {"scale.x": 1.25, "scale.y": 1.25}, 5, {type: PINGPONG, ease: FlxEase.sineInOut});

        var starField:FlxStarField3D = new FlxStarField3D(0, 0, Std.int(FlxG.width/4), Std.int(FlxG.height/4), 1000);
		starField.setStarSpeed(200, 500);
		starField.setStarDepthColors(5, FlxColor.WHITE, FlxColor.TRANSPARENT);
        starField.setGraphicSize(FlxG.width, FlxG.height);
		starField.scrollFactor.set(0,0);
		starField.updateHitbox();
        starField.alpha = 0.5;
        // starField.blend = "SCREEN";
		// add(starField);
        
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

        Conductor.bpm = bpm;

        topBar = new FlxSprite().makeGraphic(FlxG.width, 75,FlxColor.BLACK);
        topBar.scrollFactor.set();
        topBar.updateHitbox();
        add(topBar);

        dancingSprite = new FlxSprite(512, 40);
		dancingSprite.antialiasing = ClientPrefs.data.antialiasing;
        dancingSprite.frames = Paths.getSparrowAtlas('gfDanceTitle');
        dancingSprite.animation.addByIndices('danceLeft', 'gfDance', [30, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14], "", 24, false);
        dancingSprite.animation.addByIndices('danceRight', 'gfDance', [15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29], "", 24, false);
        add(dancingSprite);

        bottomBar = new FlxSprite(0, FlxG.height - 75).makeGraphic(FlxG.width, 75,FlxColor.BLACK);
        bottomBar.scrollFactor.set();
        bottomBar.updateHitbox();
        add(bottomBar);

        menuItems = new FlxTypedGroup<FlxSprite>();
		add(menuItems);

        for(i in 0...optionShit.length)
        {
            var menu:FlxSprite = new FlxSprite(15, optionShit[i][1]).loadGraphic(Paths.image("menuoptions/menu_" + optionShit[i][0]));
            menu.antialiasing = ClientPrefs.data.antialiasing;
            menu.scrollFactor.set();
            menu.ID = i;
            menuItems.add(menu);
        }

        var optionItem:FlxSprite = new FlxSprite(FlxG.width - 60, 490);
        optionItem.frames = Paths.getSparrowAtlas('menuoptions/menu_$optionBar');
		optionItem.animation.addByPrefix('idle', 'options idle', 24, true);
		optionItem.animation.addByPrefix('selected', 'options selected', 24, true);
        optionItem.updateHitbox();
        optionItem.antialiasing = ClientPrefs.data.antialiasing;
        optionItem.scrollFactor.set();
        optionItem.x -= optionItem.width;
        optionItem.ID = menuItems.members.length;
        menuItems.add(optionItem);

        optionShit.push([optionBar]);

        super.create();

        if(!holiday)
        {
		    setNewColors();
		    new FlxTimer().start(1, function(tmr:FlxTimer){
			    setNewColors();
		    }, 0);
        }

        changeItem();

        FlxG.mouse.visible = true;
    }

	function setNewColors()
	{
		color++;
		if(color >= colors.length) color = 0;

		var secColor = color + 1;
		if(secColor >= colors.length) secColor = 0;

		whiteBG.setGradient(colors[color], colors[secColor]);
	}

    var selectedSomethin:Bool;

    override public function update(elapsed):Void
    {
        super.update(elapsed);

        if (FlxG.sound.music != null)
			Conductor.songPosition = FlxG.sound.music.time;

        if(inMainMenu)
        {
            if (!selectedSomethin)
            {
                if (controls.UI_UP_P)
                {
                    mouseMode = false;
                    changeItem(-1);
                }
                if (controls.UI_DOWN_P)
                {
                    mouseMode = false;
                    changeItem(1);
                }


                if (controls.ACCEPT)
                    selectItem();

                if(FlxG.mouse.justMoved)
                    mouseMode = true;
            }

            menuItems.forEach(function(spr:FlxSprite){

                if(!selectedSomethin)
                {
                    if(FlxG.mouse.overlaps(spr) && mouseMode)
                    {
                        if(curSelection != spr.ID)
                        {
                            curSelection = spr.ID;
                            chooseItem(curSelection, true);
                        }

                        if(FlxG.mouse.justPressed)
                        {
                            selectItem();
                        }
                    }
                }
    
                if(spr.ID != menuItems.members.length - 1)
                {
                    if(spr.ID == curSelection) spr.x = FlxMath.lerp(spr.x, 65, elapsed * 8);
                    else spr.x = FlxMath.lerp(spr.x, defaultX, elapsed * 8);
    
                    // spr.updateHitbox();
                }
    
                
            });
        }
        #if desktop
        if (controls.justPressed('debug_1'))
        {
            selectedSomethin = true;
            MusicBeatState.switchState(new MasterEditorMenu());
        }

        if(FlxG.keys.justPressed.FIVE)
		{
            persistentUpdate = false;
            openSubState(new RankingSubState());
            // selectedSomethin = true;
			// MusicBeatState.switchState(new GuestStarsLogsState());
		}
        #end

    }

    override function closeSubState() {
		persistentUpdate = true;
		changeItem();
		super.closeSubState();
	}

    var danceLeft:Bool = false;
    override function beatHit()
    {
        super.beatHit();
    
        if(dancingSprite != null) {
            danceLeft = !danceLeft;
            if (danceLeft)
                dancingSprite.animation.play('danceRight');
            else
                dancingSprite.animation.play('danceLeft');
        }
    }

    function changeItem(huh:Int = 0)
    {
        if(huh != 0) FlxG.sound.play(Paths.sound('scrollMenu'));
    
        curSelection += huh;
    
        if (curSelection >= menuItems.length)
            curSelection = 0;
        if (curSelection < 0)
            curSelection = menuItems.length - 1;
    
        chooseItem(curSelection);
    }

    function chooseItem(select:Int = 0, audioOn:Bool = false)
    {
        if(audioOn) FlxG.sound.play(Paths.sound('scrollMenu'));

        for(item in menuItems.members)
        {
            if(item.animation != null) item.animation.play('idle');
            item.updateHitbox();
        }

        if(menuItems.members[select].animation != null)
        {
            menuItems.members[select].animation.play('selected');
            menuItems.members[select].centerOffsets();
        }
    }

    function selectItem()
    {
        FlxG.sound.play(Paths.sound('confirmMenu'));
        selectedSomethin = true;

        for (i in 0...menuItems.members.length)
		{
			if (i == curSelection)
				continue;
			FlxTween.tween(menuItems.members[i], {alpha: 0}, 0.4, {
				ease: FlxEase.quadOut,
				onComplete: function(twn:FlxTween)
				{
					menuItems.members[i].kill();
				}
			});
		}

        new FlxTimer().start(1, function(tmr:FlxTimer)
		{
			switch (optionShit[curSelection][0])
			{
				case 'play':
					MusicBeatState.switchState(new SongSelectionState());
                case 'gallery':
                    // MusicBeatState.switchState(new GuestStarsLogsState());
                    MusicBeatState.switchState(new GuestStarsExtrasState());
				case 'credits':
					// MusicBeatState.switchState(new CreditsState());
                    MusicBeatState.switchState(new GuestStarsCreditsState());
				case 'options':
					// MusicBeatState.switchState(new OptionsState());
                    MusicBeatState.switchState(new GuestStarOptionsState());
					OptionsState.onPlayState = false;
					if (PlayState.SONG != null)
					{
						PlayState.SONG.arrowSkin = null;
						PlayState.SONG.splashSkin = null;
						PlayState.stageUI = 'normal';
					}
                default:
                    selectedSomethin = false;
                    for (i in 0...menuItems.members.length)
                    {
                        menuItems.members[i].revive();
                        if (i == curSelection)
                            continue;
                        FlxTween.tween(menuItems.members[i], {alpha: 1}, 0.4, {
                            ease: FlxEase.quadOut,
                            onComplete: function(twn:FlxTween)
                            {
                                
                            }
                        });
                    }
			}
		});


    }
}