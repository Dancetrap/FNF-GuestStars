package states;

import backend.FlxCameraFix;
import backend.Highscore;
import backend.Song;
import backend.TrackData;

import flixel.addons.display.FlxBackdrop;
import flixel.addons.display.FlxGridOverlay;

import flixel.effects.particles.FlxEmitter;
import flixel.effects.particles.FlxParticle;

import flixel.graphics.FlxGraphic;

import objects.FlxEndlessGallery;
import objects.GradientBG;
import objects.GSMusicPlayer;
import objects.RankingIcon;

import substates.GameplayChangersSubstate;


class SongSelectionState extends MusicBeatState
{
    //Variables
    public static var curSelection:Int = 0;
    private var startPos:Float; //Start position of the gallery
    private var albumPos:Float; //The middle position of the selected track album
    private var curData:TrackMetadata; //The current data track
    private var curTag:Int = 0;

    //Assets
    var bg:GradientBG;
    var songSelection:FlxEndlessGallery;
    var selectedAlbum:FlxSprite;

    var border:FlxSprite;

    var barCam:FlxCamera;
    var topSongBar:FlxBackdrop;
    var bottomSongBar:FlxBackdrop;

    private var topBar:FlxSprite;
    var songNameBox:FlxSpriteGroup;
    var songTitle:FlxText;

    var missingCam:FlxCamera;

    var information:FlxSpriteGroup;
    var infoBox:FlxSprite;
    var description:FlxText;
    var songName:FlxText;
    var highscore:FlxText;
    var ranking:RankingIcon;

    var player:GSMusicPlayer;

    var missingTextBG:FlxSprite;
	var missingText:FlxText;

    //Special effects
    var today:Date = Date.now();

    //Data
    private var tracks:Array<TrackMetadata> = [];
    var graphics:Array<FlxGraphic> = [];

    var intendScore:Float;
    var lerpScore:Float;

    override function create() {
        
        Paths.clearStoredMemory();
		Paths.clearUnusedMemory();
        super.create();

        persistentUpdate = true;
		PlayState.isStoryMode = false;

        TrackData.reloadTracksFiles(false);
        // trace(today.getMonth());

        Difficulty.list = ["Normal"];
        PlayState.storyDifficulty = 1;

        for (i in 0...TrackData.tracksList.length) {
            var track:TrackData = TrackData.tracksLoaded.get(TrackData.tracksList[i]);

            TrackData.setDirectoryFromTrack(track);
            for (song in track.songs)
            {
                var colors:Array<String> = [];

                if(song.color == null)
                {
                    colors = ["",""];
                }
                else if(today.getMonth() == 9) //It's da spooky month!
                {
                    colors.push("#e87800");
                    colors.push("#1d0029");
                }
                else if(today.getMonth() == 11 && today.getDate() <= 25)
                {
                    colors.push("#ff7878");
                    colors.push("#74d680");
                }
                else
                {
                    for(color in song.color)
                    {
                        var ast = !color.startsWith("#") ? "#" : "";
                        colors.push(ast + color);
                    }
                }

                addSong(song.song, i, song.title, song.character, song.description, FlxColor.fromString(colors[0]), FlxColor.fromString(colors[1]), song.tags != null ? song.tags : [""]);
            }
		}

        player = new GSMusicPlayer();
        add(player);
        
        //0xFF00ffcd, 0xFFff1e73
		bg = new GradientBG(0,0,FlxG.width, FlxG.height);
		bg.scrollFactor.set(0,0);
		bg.updateHitbox();
		bg.screenCenter();
        bg.time = 8;
		add(bg);
        
        //FlxGridOverlay.createGrid(80, 80, 160, 160, true, 0x33FFFFFF, 0x0)
        var grid:FlxBackdrop = new FlxBackdrop(FlxGridOverlay.createGrid(80, 80, 160, 160, true, 0x33FFFFFF, 0x0));
		grid.velocity.set(40, 40);
		grid.alpha = 0;
		FlxTween.tween(grid, {alpha: today.getDate() == 13 ? 0.6 : 1}, 0.5, {ease: FlxEase.quadOut});
        grid.angle = 15;
		add(grid);

        // HUGE thanks to this guy for the snowfall tutorial https://www.ohsat.com/tutorial/flixel/quick-snow-effect/index.php
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

        for (i in 0...tracks.length)
        {
            Mods.currentModDirectory = tracks[i].folder;
            var file:String = Paths.fileExists('images/tracks/' + tracks[i].songCharacter + '.png', IMAGE) ? 'tracks/' + tracks[i].songCharacter : 'tracks/404';
            graphics.push(Paths.image(file));
        }

        songSelection = new FlxEndlessGallery(graphics, 90, 0.15); //550 is the default height
        // songSelection.setScale(0.15); //600*0.15 = 90
        songSelection.center();
        songSelection.x += 300 - FlxG.width/3;
        startPos = songSelection.x;
        songSelection.antialiasing = ClientPrefs.data.antialiasing;

        //It starts on the last one always, so I have to make it so that it'll start on the first one;
        p = curSelection;
        songSelection.x -= (FlxG.width/3 * curSelection); 

        add(songSelection);

        information = new FlxSpriteGroup(423,165);
        information.alpha = 0;
        add(information);

        infoBox = new FlxSprite().loadGraphic(Paths.image("menuStuff/box"));
        information.add(infoBox);

        description = new FlxText(50,50,550,"",20);
        description.setFormat(Paths.font("JI-Flabby.ttf"), 28, FlxColor.WHITE);
        description.antialiasing = ClientPrefs.data.antialiasing;
        information.add(description);

        songName = new FlxText(12.5, -75,0,"",20);
        songName.setFormat(Paths.font("JI-Flabby.ttf"), 48, FlxColor.WHITE);
        songName.antialiasing = ClientPrefs.data.antialiasing;
        information.add(songName);

        highscore = new FlxText(50, 0, 0, "000000", 40);
        highscore.setFormat(Paths.font("JI-Flabby.ttf"), 48, FlxColor.WHITE, FlxTextBorderStyle.SHADOW, FlxColor.BLACK);
        highscore.shadowOffset.set(-5,5);
        highscore.y += infoBox.height - highscore.height - 36;
        highscore.antialiasing = ClientPrefs.data.antialiasing;
        information.add(highscore);

        ranking = new RankingIcon(0, 25);
        ranking.setGraphicSize(0,150);
        ranking.updateHitbox();
        ranking.x += infoBox.width - ranking.width - 25;
        // ranking.x = infoBox.x + infoBox.width - ranking.width/2;
        // ranking.y = infoBox.y + infoBox.height - ranking.height/2;
        information.add(ranking);

        selectedAlbum = new FlxSprite().loadGraphic(Paths.image('tracks/404'));
        selectedAlbum.setGraphicSize(0,550);
        selectedAlbum.updateHitbox();
        selectedAlbum.screenCenter();
        selectedAlbum.x++;
        albumPos = selectedAlbum.x;
        selectedAlbum.alpha = 0;
        add(selectedAlbum);

        var black:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, 75, FlxColor.BLACK);
        songTitle = new FlxText(0,10,0,"", 30);
        songTitle.setFormat(Paths.font("Ethnocentric Rg It.otf"), 48, FlxColor.WHITE);
        songTitle.screenCenter(X);
        songTitle.antialiasing = ClientPrefs.data.antialiasing;

        changeSelection(false);
        bg.setGradientImmediate(tracks[curSelection].topColor, tracks[curSelection].bottomColor);

        border = new FlxSprite().loadGraphic(Paths.image("coolBorder"));
        border.setGraphicSize(FlxG.width);
        border.updateHitbox();
        // add(border);

        barCam = new FlxCamera();
        barCam.bgColor.alpha = 0;
        barCam.angle = 15;
        barCam.alpha = 0;
        // barCam.zoom = 1.5;
        FlxG.cameras.add(barCam, false);
        FlxCameraFix.initialize([barCam]);
        // FlxTween.tween(barCam, {angle: 30}, 2);
        // @:privateAccess barCam.updateScrollRect();

        missingCam = new FlxCamera();
        missingCam.bgColor.alpha = 0;
        FlxG.cameras.add(missingCam, false);

        missingTextBG = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		missingTextBG.alpha = 0.6;
		missingTextBG.visible = false;
        missingTextBG.cameras = [missingCam];
		add(missingTextBG);
		
		missingText = new FlxText(50, 0, FlxG.width - 100, '', 24);
		missingText.setFormat(Paths.font("vcr.ttf"), 24, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		missingText.scrollFactor.set();
		missingText.visible = false;
        missingText.cameras = [missingCam];
		add(missingText);

        topSongBar = new FlxBackdrop(Paths.image("pattern"), X);
        topSongBar.y -= topSongBar.height - 10;
        topSongBar.flipY = true;
        topSongBar.velocity.set(30);
        topSongBar.cameras = [barCam];
        topSongBar.color = FlxColor.BLACK;
        topSongBar.antialiasing = ClientPrefs.data.antialiasing;
        add(topSongBar);

        bottomSongBar = new FlxBackdrop(Paths.image("pattern"), X);
        bottomSongBar.y = FlxG.height - 10;
        bottomSongBar.velocity.set(-30);
        bottomSongBar.cameras = [barCam];
        bottomSongBar.color = FlxColor.BLACK;
        bottomSongBar.antialiasing = ClientPrefs.data.antialiasing;
        add(bottomSongBar);

        if(today.getMonth() == 11 && today.getDate() <= 25)
        {
            topSongBar.color = FlxColor.fromString("#B70D00");
            bottomSongBar.color = FlxColor.fromString("#005C01");
        }

        var extraCam:FlxCamera = new FlxCamera();
        extraCam.bgColor.alpha = 0;
        FlxG.cameras.add(extraCam, false);

        topBar = new FlxSprite().makeGraphic(FlxG.width, 75,FlxColor.BLACK);
        topBar.cameras = [extraCam];
        add(topBar);

        songNameBox = new FlxSpriteGroup();
        songNameBox.cameras = [extraCam];
        add(songNameBox);

        songNameBox.add(black);
        songNameBox.add(songTitle);

        songNameBox.y = FlxG.height - 75;
    }

    var holdTime:Float = 0;
    var p:Int;
    var selectedSong:Bool = false;
    var canInteract:Bool = false;

    override function update(elapsed) {

        FlxCameraFix.updateCamerasEarly(elapsed);

        super.update(elapsed);

        if(!selectedSong)
        {
            if(controls.BACK)
            {
                FlxG.sound.play(Paths.sound('cancelMenu'));
                // MusicBeatState.switchState(new MainMenuState());
                MusicBeatState.switchState(new GuestStarsMainMenuState());
            }
        
            if (controls.UI_LEFT_P)
            {
                changeSelection(-1);
                holdTime = 0;
            }
            if (controls.UI_RIGHT_P)
            {
                changeSelection(1);
                holdTime = 0;
            }
        
            if(controls.UI_RIGHT || controls.UI_LEFT)
            {
                var checkLastHold:Int = Math.floor((holdTime - 0.5) * 10);
                holdTime += elapsed;
                var checkNewHold:Int = Math.floor((holdTime - 0.5) * 10);
        
                if(holdTime > 0.5 && checkNewHold - checkLastHold > 0)
                    changeSelection((checkNewHold - checkLastHold) * (controls.UI_LEFT ? -1 : 1));
            }

            if((controls.ACCEPT) && !controls.UI_RIGHT && !controls.UI_LEFT)
            {
                songSelection.x = startPos - (FlxG.width/3 * p);
                selectedSong = true;
                selectSong(tracks[curSelection], curSelection);
                FlxG.sound.play(Paths.sound('confirmMenu'));
                // trace(tracks[curSelection].songName);
            }
        }
        else
        {
            if(canInteract)
            {
                if(controls.BACK)
                {
                    FlxG.sound.play(Paths.sound('cancelMenu'));
                    returnToSongSelection();
                    missingText.visible = false;
                    missingTextBG.visible = false;
                }

                if (controls.UI_LEFT_P)
                {
                    changeTag(-1);
                }
                if (controls.UI_RIGHT_P)
                {
                    changeTag(1);
                }

                if(controls.ACCEPT)
                {
                    persistentUpdate = false;
                    var songLowercase:String = Paths.formatToSongPath(curData.songName + curData.tags[curTag]);
                    var poop:String = Highscore.formatSong(songLowercase, 0);
        
                    try
                    {
                        PlayState.SONG = Song.loadFromJson(poop, songLowercase);
                        PlayState.isStoryMode = false;
                        PlayState.storyDifficulty = 0;
                    }
                    catch(e:Dynamic)
                    {
                        trace('ERROR! $e');
        
                        var errorStr:String = e.toString();
                        if(errorStr.startsWith('[file_contents,assets/data/')) errorStr = 'Missing file: ' + errorStr.substring(34, errorStr.length-1); //Missing chart
                        missingText.text = 'ERROR WHILE LOADING CHART:\n$errorStr';
                        missingText.screenCenter(Y);
                        missingText.visible = true;
                        missingTextBG.visible = true;
                        FlxG.sound.play(Paths.sound('cancelMenu'));
        
                        super.update(elapsed);
                        return;
                    }
                    LoadingState.loadAndSwitchState(new PlayState(), false, true, getRandomLoadingScreen()[0], getRandomLoadingScreen()[1]);
        
                    FlxG.sound.music.volume = 0;
                            
                    // destroyFreeplayVocals();
                    #if (MODS_ALLOWED && DISCORD_ALLOWED)
                    DiscordClient.loadModRPC();
                    #end
                }

                // highscore.text = CoolUtil.zeroFormat(Highscore.getScore(curData.songName + data.tags[curTag], 0), 6);
                lerpScore = Math.floor(FlxMath.lerp(intendScore, lerpScore, Math.exp(-elapsed * 24)));
                highscore.text = CoolUtil.zeroFormat(Std.int(lerpScore), 6);
            }
        }


        if(FlxG.keys.justPressed.TAB)
        {
            holdTab = true;
            tabHold = 0;
        }

        if(FlxG.keys.pressed.TAB)
        {
            if(holdTab)
            {
                var checkLastHold:Int = Math.floor((tabHold - 0.5) * 10);
                tabHold += elapsed;
                var checkNewHold:Int = Math.floor((tabHold - 0.5) * 10);

                if(tabHold > 0.5 && checkNewHold - checkLastHold > 0)
                {
                    persistentUpdate = false;
                    openSubState(new GameplayChangersSubstate());
                    holdTab = false;
                }
            }
        }

        if(FlxG.keys.released.TAB)
        {
            holdTab = false;
        }

        var lerpVal:Float = Math.exp(-elapsed * 9.6);
        songSelection.x = FlxMath.lerp(startPos - (FlxG.width/3 * p), songSelection.x, lerpVal);

        songTitle.screenCenter(X);

        FlxCameraFix.updateCameras(elapsed);
    }

    var holdTab:Bool;
    var tabHold:Float;

    function changeSelection(?change:Int = 0, ?playSound:Bool = true)
    {
        curSelection += change;
        if(playSound) FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
        if(curSelection >= tracks.length) curSelection = 0;
        else if(curSelection < 0) curSelection = tracks.length - 1;

        p += change;

        bg.setGradient(tracks[curSelection].topColor, tracks[curSelection].bottomColor);

        songTitle.text = tracks[curSelection].displayName;
    }

    function changeTag(?change:Int = 0, ?playAnim:Bool = true)
    {
        curTag += change;
        if(curTag >= curData.tags.length) curTag = 0;
        else if(curTag < 0) curTag = curData.tags.length - 1;

        ranking.playBySongScore(curData.songName + curData.tags[curTag], 0, playAnim);
        // ranking.playByAccuracy(0.99, 0, false, playAnim);
        ranking.setGraphicSize();
        ranking.updateHitbox();
        
        if(ranking.width >= ranking.height)
            ranking.setGraphicSize(0,150);
        else
            ranking.setGraphicSize(150);

        ranking.updateHitbox();
        ranking.playBySongScore(curData.songName + curData.tags[curTag], 0, playAnim);
        // ranking.playByAccuracy(0.99, 0, false, playAnim);

        intendScore = Highscore.getScore(curData.songName + curData.tags[curTag], 0);
        
        // highscore.text = CoolUtil.zeroFormat(Highscore.getScore(curData.songName + curData.tags[curTag], 0), 6);
    }

    function addSong(song:String, week:Int, title:String, char:String, description:String, top:Null<FlxColor>, bottom:Null<FlxColor>, tags:Array<String>)
    {
        var trackData = new TrackMetadata(song, week, title, char, description, top, bottom, tags);
        tracks.push(trackData);
    }

    function selectSong(data:TrackMetadata, int:Int)
    {
        selectedAlbum.loadGraphic(graphics[int]);
        selectedAlbum.setGraphicSize(0,550);
        selectedAlbum.updateHitbox();
        selectedAlbum.screenCenter();
        selectedAlbum.alpha = 1;
        songSelection.members[int].visible = false;
        FlxTween.tween(selectedAlbum, {x: 48}, 0.5, {ease: FlxEase.cubeInOut});
        FlxTween.tween(songSelection, {alpha: 0}, 0.5, {onComplete: function(twn:FlxTween){
            canInteract = true;
        }});

        // FlxTween.tween(barCam, {zoom: 1, angle: 15}, 1, {ease: FlxEase.cubeInOut});
        FlxTween.tween(barCam, {alpha:1}, 0.5, {ease: FlxEase.cubeInOut});

        Mods.currentModDirectory = tracks[int].folder;
        PlayState.storyWeek = tracks[int].week;
        curData = data;
        curTag = 0;
        setInfoBox(curData);
        changeTag();

        // var poop:String = Highscore.formatSong(tracks[int].songName.toLowerCase(), 1);
        // if(Song.loadFromJson(poop, tracks[int].songName.toLowerCase()) != null)
        //     PlayState.SONG = Song.loadFromJson(poop, tracks[int].songName.toLowerCase());
        // else
        //     PlayState.SONG = null;

        // player.play(PlayState.SONG);
        // trace(curData.description);

        //Set all of the song info to the selected track
        FlxTween.tween(information, {alpha: 1, y: 175}, 0.5, {ease: FlxEase.sineOut, startDelay: 0.25});
        FlxTween.tween(topBar, {y:-topBar.height}, 0.5, {ease: FlxEase.sineOut});
        FlxTween.tween(songNameBox, {y: FlxG.height}, 0.5, {ease: FlxEase.sineOut});
    }

    //In selected song 
    function returnToSongSelection()
    {
        FlxTween.cancelTweensOf(barCam);
        FlxTween.cancelTweensOf(information);
        FlxTween.cancelTweensOf(songNameBox);
        canInteract = false;
        // player.stop();
        
        FlxTween.tween(selectedAlbum, {x: albumPos}, 0.5, {ease: FlxEase.cubeInOut, onComplete: function(twn:FlxTween){
            songSelection.members[curSelection].visible = true;
            songSelection.members[curSelection].alpha = 1;
            selectedAlbum.alpha = 0;
            selectedSong = false;
        }});

        FlxTween.tween(information, {alpha: 0, y: 165}, 0.25, {ease: FlxEase.sineOut});
        FlxTween.tween(topBar, {y:0}, 0.5, {ease: FlxEase.sineInOut});
        FlxTween.tween(songNameBox, {y: FlxG.height - 75}, 0.5, {ease: FlxEase.sineInOut});
        FlxTween.tween(barCam, {alpha:0}, 0.5, {ease: FlxEase.cubeInOut});

        // FlxTween.tween(barCam, {zoom: 1.5, angle: 0}, 0.5, {ease: FlxEase.cubeInOut});

        songSelection.forEach(function(spr:FlxSprite){
            if(spr.ID != curSelection)
            {
                FlxTween.tween(songSelection, {alpha: 1}, 0.5);
            }
        });
    }

    function setInfoBox(data:TrackMetadata)
    {
        // infoBox.color = CoolUtil.colorMean([data.topColor, data.bottomColor]);
        infoBox.color = FlxColor.interpolate(data.topColor, data.bottomColor);
        description.text = data.description.toUpperCase();

        if(Paths.fileExists('images/titles/' + data.songName + '.png', IMAGE))
        {
            songName.text = "";
            songName.loadGraphic(Paths.image("titles/" + data.songName));
            songName.antialiasing = ClientPrefs.data.antialiasing;
            songName.setGraphicSize(0,100);
            songName.updateHitbox();
            songName.y = information.y - 100;
            if(songName.x + songName.width > FlxG.width)
            {
                songName.setGraphicSize(Std.int(infoBox.width - 37.5));
                songName.updateHitbox();
                songName.y = information.y - 87.5;
            }
            
        }
        else
        {
            songName.scale.set(1,1);
            songName.updateHitbox();
            songName.text = data.displayName;
            songName.y = information.y -75;
        }
        
        intendScore = lerpScore = Highscore.getScore(data.songName + data.tags[curTag], 0);
        highscore.text = CoolUtil.zeroFormat(Highscore.getScore(data.songName + data.tags[curTag], 0), 6);
    }

    public static function getRandomLoadingScreen()
    {
        var loadingScreens:Array<String> = [];
        var folder:String = 'assets/shared/';
		if(FileSystem.exists(Paths.modFolders('images/loadingScreens'))) //Images from Mod Folder
		{
            folder = 'mods/' + Mods.currentModDirectory + '/';
			var modLoadingScreens:Array<String> = FileSystem.readDirectory(Paths.modFolders('images/loadingScreens'));
			for(screen in modLoadingScreens)
			{
				if(Paths.fileExists("images/loadingScreens/" + screen, IMAGE))
				{
					loadingScreens.push(screen);
				}
			}
		}
        else if(FileSystem.exists('assets/shared/images/loadingScreens')) //Images from Shared/Compiled
		{
			var sharedLoadingScreens:Array<String> = FileSystem.readDirectory('assets/shared/images/loadingScreens');
			for(screen in sharedLoadingScreens)
			{
				if(Paths.fileExists("images/loadingScreens/" + screen, IMAGE))
				{
					loadingScreens.push(screen);
				}
			}
		}

        var screen = 'funkay';
		if(loadingScreens.length != 0)
		{
			var randomInt = FlxG.random.int(0, loadingScreens.length - 1);
			screen = 'loadingScreens/' + StringTools.replace(loadingScreens[randomInt], ".png", "");
		}

        return [screen, folder];
    }
}

class TrackMetadata
{
    public var songName:String = "";
	public var week:Int = 0;
    public var displayName:String = "";
	public var songCharacter:String = "";
    public var description:String = "";
	public var topColor:Int = -7179779;
    public var bottomColor:Int = -7179779;
    public var tags:Array<String> = [""];
	public var folder:String = "";
	public var lastDifficulty:String = null;

    public function new(song:String, week:Int, display:String, songCharacter:String, description:String, ?topColor:Null<Int>, ?bottomColor:Null<Int>, ?tags:Null<Array<String>>)
    {
        this.songName = song;
		this.week = week;
        this.displayName = display;
		this.songCharacter = songCharacter;
        this.description = description;
		this.topColor = topColor != null ? topColor : 0xFFFF0000;
        this.bottomColor = bottomColor != null ? bottomColor : 0xFF00FF00;
        this.tags = tags;
        for(i in 0...tags.length)
        {
            if(tags[i].toLowerCase() == "normal")
            {
                tags[i] = "";
            }
            tags[i] = tagPath(tags[i]);
        }
		this.folder = Mods.currentModDirectory;
		if(this.folder == null) this.folder = '';
    }

    public function tagPath(tag:String):String
    {
        return tag != "" ? "-" + tag.toLowerCase() : "";
    }
}