package states;

import objects.HealthIcon;
import flixel.addons.display.FlxBackdrop;
import flixel.addons.display.FlxGridOverlay;
import flixel.graphics.FlxGraphic;
import objects.GradientBG;

import openfl.utils.Assets;
import openfl.utils.AssetType;
import flixel.util.FlxStringUtil;

import flixel.effects.particles.FlxEmitter;
import flixel.effects.particles.FlxParticle;

class GuestStarsCreditsState extends MusicBeatState
{
	public var creditsList:GuestStarsCredits;

	var list:Array<Array<String>> = [];
	var titleArray:Array<String> = ["GUEST STARS", "title", "center"];
	var thankYouArray:Array<String> = ["Thank you for playing Guest Stars!", "header", "center"];

	/**
		Guide to credit using
		// 1. Text/image file
		// 2. Type
			a. Title - Big Text
			b. Header - Medium Text
			c. Text/Paragraph - Small Text
			d. Image (will add image instead)
			e. Icon (will add an icon image)
		// 3. Alignment
		// 3. Scale
	**/

	//Special effects
    var today:Date = Date.now();
    var holiday:Bool = false;
    var holidayColors:Array<FlxColor> = [];

    override function create()
    {
		super.create();
		persistentUpdate = true;

		list.push(titleArray);

		var creditsFile = Paths.getSharedPath('data/credits.txt');
		if (FileSystem.exists(creditsFile))
		{
			var firstarray:Array<String> = CoolUtil.coolTextFile(creditsFile);
			for(i in firstarray)
			{
				var arr:Array<String> = i.replace('\\n', '\n').split("::");
				list.push(arr);
			}
			list.push(['']);
		}

		#if MODS_ALLOWED
		for (mod in Mods.parseList().enabled) 
		{
			pushModCreditsToList(mod);
		}
		#end

		list.push(thankYouArray);

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

        var bg:GradientBG = new GradientBG(0,0,FlxG.width, FlxG.height, holiday ? holidayColors[0] : 0xFF7700ff, holiday ? holidayColors[1] : 0xFFc4ab5e);
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

		var graphic:FlxGraphic = Paths.image("pattern");

		var sideBar:FlxBackdrop = new FlxBackdrop(graphic, Y, 0, Math.abs(graphic.width - graphic.height));
        sideBar.angle = 90;
        sideBar.velocity.set(0, 30);
		sideBar.x -= 150;
		sideBar.color = FlxColor.BLACK;
		if(today.getMonth() == 11 && today.getDate() <= 25) sideBar.color = FlxColor.fromString("#B70D00");
        add(sideBar);

		var sideBar:FlxBackdrop = new FlxBackdrop(graphic, Y, 0, Math.abs(graphic.width - graphic.height));
        sideBar.angle = 270;
        sideBar.velocity.set(0, -30);
		sideBar.x = FlxG.width - 150;
		sideBar.color = FlxColor.BLACK;
		if(today.getMonth() == 11 && today.getDate() <= 25) sideBar.color = FlxColor.fromString("#005C01");
        add(sideBar);

		creditsList = new GuestStarsCredits(Std.int(FlxG.width * 0.75));
		add(creditsList);
		creditsList.screenCenter(X);
		// creditsList.addText("GUEST STARS", "title", "center");

		for (i in 0...list.length)
		{
			// trace(list[i]);
			if(list[i].length < 2)
			{
				// creditsList.addText(list.length > 0 ? list[i][0] : "", "paragraph", "center");
				creditsList.addBreak(!Math.isNaN(Std.parseFloat(list[i][0])) ? Std.parseFloat(list[i][0]) : 50);
				continue;
			}

			switch(list[i][1].toLowerCase())
			{
				case "image":
					creditsList.addImage(list[i][0], list[i][2], false, list[i].length >= 4 && !Math.isNaN(Std.parseFloat(list[i][3])) ? Std.parseFloat(list[i][3]) : 1);
				case "icon":
					creditsList.addImage(list[i][0], list[i][2], true, list[i].length >= 4 && !Math.isNaN(Std.parseFloat(list[i][3])) ? Std.parseFloat(list[i][3]) : 1);
				default:
					creditsList.addText(list[i][0], list[i][1], list[i][2]);
			}
		}
    }

    #if MODS_ALLOWED
	function pushModCreditsToList(folder:String)
	{
		var creditsFile:String = null;
		if(folder != null && folder.trim().length > 0) creditsFile = Paths.mods(folder + '/data/credits.txt');
		else creditsFile = Paths.mods('data/credits.txt');
		if (FileSystem.exists(creditsFile))
		{
			var firstarray:Array<String> = CoolUtil.coolTextFile(creditsFile);
			for(i in firstarray)
			{
				var arr:Array<String> = i.replace('\\n', '\n').split("::");
				if(arr.length >= 4) arr.push(folder);
				list.push(arr);
			}
			list.push(['']);
		}
	}
	#end

	override function update(elapsed:Float) {
		super.update(elapsed);

		if(controls.BACK)
        {
            FlxG.sound.play(Paths.sound('cancelMenu'));
            // MusicBeatState.switchState(new MainMenuState());
            MusicBeatState.switchState(new GuestStarsMainMenuState());
        }
	}
}

class GuestStarsCredits extends FlxSpriteGroup
{
	var box:FlxSprite;
	var scrollSpeed:Float;
	public var defaultScrollSpeed:Float = -20;
	var creditAssets:Array<Dynamic> = [];

	var alignments:Map<FlxSprite, String> = new Map<FlxSprite, String>();

	var controls(get, never):Controls;
	private function get_controls()
	{
		return Controls.instance;
	}

	public function new(width:Int = 0)
	{
		super();
		if(width <= 0) width = FlxG.width;

		y = FlxG.height;

		box = new FlxSprite().makeGraphic(width, 10, FlxColor.TRANSPARENT);
		add(box);

		scrollSpeed = defaultScrollSpeed;
	}

	var creditsHeight:Float = 0;
	public function addText(text:String, type:String, alignment:String = "left")
	{
		var text:FlxText = new FlxText(0, creditsHeight, 0, text);
		switch(type.toLowerCase())
		{
			case "title":
				text.font = Paths.font("JI-Flabby.ttf");
				text.size = 72;
				text.borderStyle = FlxTextBorderStyle.SHADOW;
				text.borderColor = FlxColor.BLACK;
				text.shadowOffset.set(-5,5);
			case "header":
				text.font = Paths.font("nikkyou.ttf");
				text.size = 48;
				text.borderStyle = FlxTextBorderStyle.OUTLINE;
				text.borderColor = FlxColor.BLACK;
				text.borderSize = 3;
			default:
					text.font = Paths.font("nikkyou.ttf");
					text.size = 24;
					text.borderStyle = FlxTextBorderStyle.OUTLINE;
					text.borderColor = FlxColor.BLACK;
					text.borderSize = 3;
		}

		creditAssets.push(text);
		add(text);

		switch(alignment.toLowerCase())
		{
			case "left":
				text.alignment = LEFT;
			case "center":
				text.alignment = CENTER;
				text.x = box.x +  box.width/2 - text.width/2;
			case "right":
				text.alignment = RIGHT;
				text.x = box.x + box.width - text.width;
		}

		box.setGraphicSize(box.width, height);
		box.updateHitbox();

		creditsHeight += text.height;

	}

	public function addTextList()
	{

	}

	var prevX = 0.0;

	public function addImage(file:String, alignment:String, isIcon:Bool = false, ?scale:Float = 1, animation:String = "", wrap:Bool = false)
	{
		if(isIcon)
		{
			var icon:HealthIcon = new HealthIcon(file);
			icon.y = creditsHeight;
			creditAssets.push(icon);
			add(icon);

			switch(alignment.toLowerCase())
			{
				case "center":
					icon.x = box.x + box.width/2 - icon.width/2;
				case "right":
					icon.x = box.x + box.width - icon.width;
			}

			icon.scale.set(scale, scale);
			icon.updateHitbox();
		}
		else
		{
			var image:FlxSprite = new FlxSprite(0, creditsHeight);
			if(animation != "")
			{
				image.frames = Paths.getSparrowAtlas(file);
				image.animation.addByPrefix(animation, animation, 24);
				image.animation.play(animation);
			}
			else
			{
				image.loadGraphic(Paths.image(file));
			}

			image.antialiasing = ClientPrefs.data.antialiasing;
			creditAssets.push(image);
			add(image);
			
			image.scale.set(scale, scale);
			image.updateHitbox();

			if(image.width > box.width) 
			{
				image.setGraphicSize(box.width);
				image.updateHitbox();
			}

			switch(alignment.toLowerCase())
			{
				case "center":
					image.x = box.x + box.width/2 - image.width/2;
				case "right":
					image.x = box.x + box.width - image.width;
			}

			creditsHeight += image.height;
		}

		box.setGraphicSize(box.width, height);
		box.updateHitbox();
	}

	public function addBreak(b:Float)
	{
		creditsHeight += b;
	}

	var prevMouseY:Float;
	override function update(elapsed:Float) {
		super.update(elapsed);

		if(FlxG.mouse.pressed)
		{
			scrollSpeed = defaultScrollSpeed * (1 - (FlxG.mouse.deltaY * Math.abs(defaultScrollSpeed * 5)));
		}
		else if(FlxG.mouse.released)
		{
			scrollSpeed = defaultScrollSpeed;
		}

		if(controls.UI_DOWN)
		{
			scrollSpeed = Math.abs(20 * defaultScrollSpeed);
		}
		else if(controls.UI_UP)
		{
			scrollSpeed = -Math.abs(20 * defaultScrollSpeed);
		}
		else
		{
			if(FlxG.mouse.wheel != 0)
				scrollSpeed -= FlxG.mouse.wheel * Math.abs(50 * defaultScrollSpeed);
			else
				scrollSpeed = FlxMath.lerp(scrollSpeed, defaultScrollSpeed, Math.exp(-elapsed * 9));
		}

		if(controls.UI_UP_R || controls.UI_DOWN_R)
			scrollSpeed = defaultScrollSpeed;

		velocity.set(0,scrollSpeed);

		if(y < -height)
			y = FlxG.height;
		else if(y > FlxG.height)
			y = -height;
	}
}