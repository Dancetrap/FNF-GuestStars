package substates;

import backend.WeekData;

import objects.Character;
import flixel.FlxObject;
import flixel.FlxSubState;
import flixel.ui.FlxBar;
import objects.Bar;
import flixel.util.FlxStringUtil;

import states.StoryMenuState;
import states.FreeplayState;
import states.SongSelectionState;

class GameOverSubstate extends MusicBeatSubstate
{
	public var boyfriend:Character;
	var camFollow:FlxObject;
	var moveCamera:Bool = false;
	var playingDeathSound:Bool = false;

	var stageSuffix:String = "";

	public static var characterName:String = 'bf-dead';
	public static var deathSoundName:String = 'fnf_loss_sfx';
	public static var loopSoundName:String = 'GameOverMusic';
	public static var endSoundName:String = 'LeContinue';
	public static var loopStart:Float = 2268;

	public static var instance:GameOverSubstate;

	var gameOverMusic:FlxSound;
	var gameOverHUD:FlxCamera;

	//Game Over Hud
	var runningRabbit:FlxSprite;
	var progressBar:Bar;
	var timeTxt:FlxText;
	var lerpPoint:Float = 0;
	var progress:Float = 0;
	var curSongPercent:Float = 0;
	var songLength:Float = 0;
	var curSongTime:Float = 0;

	var secondsLength:Int = 0;
	var secondsTime:Int = 0;

	public static function resetVariables() {
		characterName = 'bf-dead';
		deathSoundName = 'fnf_loss_sfx';
		loopSoundName = 'GameOverMusic';
		endSoundName = 'LeContinue';
		loopStart = 2268;

		var _song = PlayState.SONG;
		if(_song != null)
		{
			if(_song.gameOverChar != null && _song.gameOverChar.trim().length > 0) characterName = _song.gameOverChar;
			if(_song.gameOverSound != null && _song.gameOverSound.trim().length > 0) deathSoundName = _song.gameOverSound;
			if(_song.gameOverLoop != null && _song.gameOverLoop.trim().length > 0) loopSoundName = _song.gameOverLoop;
			if(_song.gameOverEnd != null && _song.gameOverEnd.trim().length > 0) endSoundName = _song.gameOverEnd;
			if(_song.gameOverStart != null && _song.gameOverStart >= 0) loopStart = _song.gameOverStart;
		}
	}

	var charX:Float = 0;
	var charY:Float = 0;
	override function create()
	{
		instance = this;

		@:privateAccess curSongPercent = PlayState.instance.songPercent;
		if(PlayState.instance.startingSong)
		{
			@:privateAccess songLength = PlayState.instance.inst._sound.length;
		}
		else
			@:privateAccess songLength = PlayState.instance.songLength;

		var songCalc:Float = curSongPercent * songLength;

		secondsLength = Math.floor(songLength / 1000);
		secondsTime = Math.floor(songCalc / 1000);
		

		Conductor.songPosition = 0;

		boyfriend = new Character(PlayState.instance.boyfriend.getScreenPosition().x, PlayState.instance.boyfriend.getScreenPosition().y, characterName, true);
		boyfriend.x += boyfriend.positionArray[0] - PlayState.instance.boyfriend.positionArray[0];
		boyfriend.y += boyfriend.positionArray[1] - PlayState.instance.boyfriend.positionArray[1];
		add(boyfriend);

		FlxG.sound.play(Paths.sound(deathSoundName));
		FlxG.camera.scroll.set();
		FlxG.camera.target = null;

		boyfriend.playAnim('firstDeath');

		camFollow = new FlxObject(0, 0, 1, 1);
		camFollow.setPosition(boyfriend.getGraphicMidpoint().x + boyfriend.cameraPosition[0] + 350, boyfriend.getGraphicMidpoint().y + boyfriend.cameraPosition[1]);
		FlxG.camera.focusOn(new FlxPoint(FlxG.camera.scroll.x + (FlxG.camera.width / 2), FlxG.camera.scroll.y + (FlxG.camera.height / 2)));
		add(camFollow);
		
		PlayState.instance.setOnScripts('inGameOver', true);
		PlayState.instance.callOnScripts('onGameOverStart', []);


		Paths.music(loopSoundName);
		gameOverMusic = new FlxSound();
		gameOverMusic.loadEmbedded(Paths.music(loopSoundName), false, false, function(){
			gameOverMusic.play(false, loopStart);
		});
		FlxG.sound.list.add(gameOverMusic);


		gameOverHUD = new FlxCamera();
		gameOverHUD.bgColor.alpha = 0;
		FlxG.cameras.add(gameOverHUD, false);
		gameOverHUD.x = FlxG.width;

		var gamaOvar:FlxText = new FlxText(FlxG.width, 50, 0, "GAME OVER", 48);
		gamaOvar.setFormat(Paths.font("nikkyou.ttf"), 96, FlxColor.WHITE);
		gamaOvar.cameras = [gameOverHUD];
		add(gamaOvar);

		// progressBar = new FlxBar(FlxG.width, 250, LEFT_TO_RIGHT, 450, 20, this, 'progress', 0, 1, true);
		// progressBar.createFilledBar(0xFF323232/*000000*/, 0xFFFFFFFF);
		// progressBar.numDivisions = 800;
		// progressBar.cameras = [gameOverHUD];
		// progressBar.x -= progressBar.width + 100;
		progressBar = new Bar(FlxG.width, 350, 'healthBar', function() return progress, 0, 1);
		progressBar.leftToRight = true;
		progressBar.setColors(0xFFFFFFFF,0xFF323232);
		progressBar.cameras = [gameOverHUD];
		progressBar.x -= progressBar.width + 50;
		// loadingBar.value = 0;
		add(progressBar);

		gamaOvar.x = progressBar.x + progressBar.width/2 - gamaOvar.width/2;

		runningRabbit = new FlxSprite(progressBar.x, progressBar.y);
		runningRabbit.frames = Paths.getSparrowAtlas("gameOver/running_at_night");
		runningRabbit.animation.addByPrefix("run", "running", 24);
		runningRabbit.animation.play("run");
		runningRabbit.setGraphicSize(0, 100);
		runningRabbit.updateHitbox();
		runningRabbit.cameras = [gameOverHUD];
		runningRabbit.x -= runningRabbit.width/2;
		runningRabbit.y -= runningRabbit.height;
		runningRabbit.antialiasing = ClientPrefs.data.antialiasing;
		add(runningRabbit);

		timeTxt = new FlxText(progressBar.x, progressBar.y + progressBar.height, 0, FlxStringUtil.formatTime(secondsTime, false) + "/" + FlxStringUtil.formatTime(secondsLength, false), 24);
		timeTxt.setFormat(Paths.font("JI-Flabby.ttf"), 16, FlxColor.WHITE);
		timeTxt.cameras = [gameOverHUD];
		add(timeTxt);

		var scores:String = '<g>Sicks: ${PlayState.instance.ratingsData[0].hits}<g>\n<c>Goods: ${PlayState.instance.ratingsData[1].hits}<c>\n<y>Bads: ${PlayState.instance.ratingsData[2].hits}<y>\n<r>Shits: ${PlayState.instance.ratingsData[3].hits}<r>';
		var scoreTxt:FlxText = new FlxText(progressBar.x, progressBar.y + progressBar.height + 50, 0, scores, 16);
		scoreTxt.setFormat(Paths.font("Ethnocentric Rg It.otf"), 36, FlxColor.WHITE);
		scoreTxt.cameras = [gameOverHUD];
		scoreTxt.applyMarkup(scoreTxt.text, [new FlxTextFormatMarkerPair(new FlxTextFormat(FlxColor.LIME),"<g>"), new FlxTextFormatMarkerPair(new FlxTextFormat(FlxColor.CYAN),"<c>"), new FlxTextFormatMarkerPair(new FlxTextFormat(FlxColor.YELLOW),"<y>"),new FlxTextFormatMarkerPair(new FlxTextFormat(FlxColor.RED),"<r>")]);
		add(scoreTxt);

		super.create();
	}

	public var startedDeath:Bool = false;
	override function update(elapsed:Float)
	{
		super.update(elapsed);

		PlayState.instance.callOnScripts('onUpdate', [elapsed]);

		if (controls.ACCEPT)
		{
			endBullshit();
		}

		if (controls.BACK)
		{
			#if DISCORD_ALLOWED DiscordClient.resetClientID(); #end
			FlxG.sound.music.stop();
			gameOverMusic.stop();
			PlayState.deathCounter = 0;
			PlayState.seenCutscene = false;
			PlayState.chartingMode = false;
			progress = curSongPercent;
			updateRabbit();
			FlxTween.cancelTweensOf(gameOverHUD);
			gameOverHUD.x = 0;

			var screen = SongSelectionState.getRandomLoadingScreen();
			Mods.loadTopMod();
			if (PlayState.isStoryMode)
				MusicBeatState.switchState(new StoryMenuState(), true);
			else
				// MusicBeatState.switchState(new FreeplayState(), true);
			MusicBeatState.switchState(new SongSelectionState(), true, screen[0], screen[1]);

			FlxG.sound.playMusic(Paths.music('freakyMenu'));
			PlayState.instance.callOnScripts('onGameOverConfirm', [false]);
		}
		
		if (boyfriend.animation.curAnim != null)
		{
			if (boyfriend.animation.curAnim.name == 'firstDeath' && boyfriend.animation.curAnim.finished && startedDeath)
				boyfriend.playAnim('deathLoop');

			if(boyfriend.animation.curAnim.name == 'firstDeath')
			{
				if(boyfriend.animation.curAnim.curFrame >= 12 && !moveCamera)
				{
					FlxG.camera.follow(camFollow, LOCKON, 0.6);
					moveCamera = true;
				}

				if (boyfriend.animation.curAnim.finished && !playingDeathSound)
				{
					startedDeath = true;
					if (PlayState.SONG.stage == 'tank')
					{
						playingDeathSound = true;
						coolStartDeath(0.2);
						
						var exclude:Array<Int> = [];
						//if(!ClientPrefs.cursing) exclude = [1, 3, 8, 13, 17, 21];

						FlxG.sound.play(Paths.sound('jeffGameover/jeffGameover-' + FlxG.random.int(1, 25, exclude)), 1, false, null, true, function() {
							if(!isEnding)
							{
								FlxG.sound.music.fadeIn(0.2, 1, 4);
							}
						});
					}
					else coolStartDeath();
				}
			}
		}

		if(startBar)
		{
			progress = FlxMath.lerp(progress, curSongPercent + 0.1, elapsed * 0.5);
			progress = FlxMath.bound(progress, 0, curSongPercent);
			updateRabbit();
		}
		
		if (FlxG.sound.music.playing)
		{
			Conductor.songPosition = FlxG.sound.music.time;
		}
		else if (gameOverMusic.playing)
		{
			Conductor.songPosition = gameOverMusic.time;
			// runningRabbit.animation.timeScale = Conductor.getBPMFromSeconds(Conductor.songPosition).bpm/120;
		}

		var songCalc:Float = progress * songLength;
		var secondsProgress = Math.floor(songCalc / 1000);
		timeTxt.text = FlxStringUtil.formatTime(secondsProgress, false) + "/" + FlxStringUtil.formatTime(secondsLength, false);

		PlayState.instance.callOnScripts('onUpdatePost', [elapsed]);
	}

	var isEnding:Bool = false;
	var startBar:Bool = false;

	function coolStartDeath(?volume:Float = 1):Void
	{
		// FlxG.sound.playMusic(Paths.music(loopSoundName), volume);
		// trace("Play");
		gameOverMusic.play();
		gameOverMusic.volume = volume;
		startBar = true;

		FlxTween.tween(gameOverHUD, {x: 0}, 3, {ease: FlxEase.quartOut});
	}

	function updateRabbit()
	{
		if(curSongPercent == 0) runningRabbit.x = progressBar.x - runningRabbit.width/2;
		else runningRabbit.x = progressBar.barCenter - runningRabbit.width/2;
	}

	function endBullshit():Void
	{
		if (!isEnding)
		{
			isEnding = true;
			boyfriend.playAnim('deathConfirm', true);
			FlxTween.cancelTweensOf(gameOverHUD);
			gameOverHUD.x = 0;
			progress = curSongPercent;
			updateRabbit();
			gameOverMusic.stop();
			FlxG.sound.music.stop();
			camFollow.setPosition(boyfriend.getGraphicMidpoint().x + boyfriend.cameraPosition[0], boyfriend.getGraphicMidpoint().y + boyfriend.cameraPosition[1]);
			// FlxG.camera.follow(camFollow, LOCKON, 0.6);
			FlxTween.tween(gameOverHUD, {x: FlxG.width}, 1, {ease: FlxEase.quartIn});


			FlxG.sound.play(Paths.music(endSoundName));
			new FlxTimer().start(0.7, function(tmr:FlxTimer)
			{
				FlxG.camera.fade(FlxColor.BLACK, 2, false);
				gameOverHUD.fade(FlxColor.BLACK, 2, false, function()
				{
					MusicBeatState.resetState();
				});
			});
			PlayState.instance.callOnScripts('onGameOverConfirm', [true]);
		}
	}

	override function destroy()
	{
		instance = null;
		super.destroy();
	}
}
