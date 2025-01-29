package states;

import flixel.graphics.FlxGraphic;
import objects.GradientBG;
import objects.FlxEndlessGallery;
import flixel.addons.display.FlxBackdrop;
import flixel.addons.display.FlxGridOverlay;
import backend.TrackData;

class SongSelectionState extends MusicBeatState
{
    //Variables
    public static var curSelection:Int = 0;
    private var startPos:Float; //Start position of the gallery

    private var albumPos:Float; //The middle position of the selected track album

    //Assets
    var bg:GradientBG;
    var songSelection:FlxEndlessGallery;
    var selectedAlbum:FlxSprite;

    //Data
    private var tracks:Array<TrackMetadata> = [];
    var graphics:Array<FlxGraphic> = [];

    override function create() {
        super.create();
		
        persistentUpdate = true;
		PlayState.isStoryMode = false;

        TrackData.reloadTracksFiles(false);

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
                else
                {
                    for(color in song.color)
                    {
                        var ast = !color.startsWith("#") ? "#" : "";
                        colors.push(ast + color);
                    }
                }

                addSong(song.song, i, song.title, song.character, song.description, FlxColor.fromString(colors[0]), FlxColor.fromString(colors[1]));
            }
		}
        
        //0xFF00ffcd, 0xFFff1e73
		bg = new GradientBG(0,0,FlxG.width, FlxG.height);
		bg.scrollFactor.set(0,0);
		bg.updateHitbox();
		bg.screenCenter();
        bg.time = 8;
		add(bg);
        
        var grid:FlxBackdrop = new FlxBackdrop(FlxGridOverlay.createGrid(80, 80, 160, 160, true, 0x33FFFFFF, 0x0));
		grid.velocity.set(40, 40);
		grid.alpha = 0;
		FlxTween.tween(grid, {alpha: 1}, 0.5, {ease: FlxEase.quadOut});
		add(grid);

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

        //It starts on the last one always, so I have to make it so that it'll start on the first one;
        p = curSelection;
        songSelection.x -= (FlxG.width/3 * curSelection); 

        add(songSelection);

        selectedAlbum = new FlxSprite().loadGraphic(Paths.image('tracks/404'));
        selectedAlbum.setGraphicSize(0,550);
        selectedAlbum.updateHitbox();
        selectedAlbum.screenCenter();
        selectedAlbum.x++;
        albumPos = selectedAlbum.x;
        selectedAlbum.alpha = 0;
        add(selectedAlbum);

        changeSelection(false);
        bg.setGradientImmediate(tracks[curSelection].topColor, tracks[curSelection].bottomColor);
    }

    var holdTime:Float = 0;
    var p:Int;
    var selectedSong:Bool = false;
    var canInteract:Bool = false;

    override function update(elapsed) {

        if(!selectedSong)
        {
            if(controls.BACK)
            {
                FlxG.sound.play(Paths.sound('cancelMenu'));
                MusicBeatState.switchState(new MainMenuState());
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
                }
            }
        }

        var lerpVal:Float = Math.exp(-elapsed * 9.6);
        songSelection.x = FlxMath.lerp(startPos - (FlxG.width/3 * p), songSelection.x, lerpVal);

        super.update(elapsed);
    }

    function changeSelection(?change:Int = 0, ?playSound:Bool = true)
    {
        curSelection += change;
        if(playSound) FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
        if(curSelection >= tracks.length) curSelection = 0;
        else if(curSelection < 0) curSelection = tracks.length - 1;

        p += change;

        bg.setGradient(tracks[curSelection].topColor, tracks[curSelection].bottomColor);
    }

    function addSong(song:String, week:Int, title:String, char:String, description:String, top:Null<FlxColor>, bottom:Null<FlxColor>)
    {
        var trackData = new TrackMetadata(song, week, title, char, description, top, bottom);
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

        //Set all of the song info to the selected track
    }

    //In selected song
    function returnToSongSelection()
    {
        // FlxTween.cancelChain();
        canInteract = false;
        FlxTween.tween(selectedAlbum, {x: albumPos}, 0.5, {ease: FlxEase.cubeInOut, onComplete: function(twn:FlxTween){
            songSelection.members[curSelection].visible = true;
            songSelection.members[curSelection].alpha = 1;
            selectedAlbum.alpha = 0;
            selectedSong = false;
        }});

        songSelection.forEach(function(spr:FlxSprite){
            if(spr.ID != curSelection)
            {
                FlxTween.tween(songSelection, {alpha: 1}, 0.5);
            }
        });
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
	public var folder:String = "";
	public var lastDifficulty:String = null;

    public function new(song:String, week:Int, display:String, songCharacter:String, description:String, ?topColor:Null<Int>, ?bottomColor:Null<Int>)
    {
        this.songName = song;
		this.week = week;
        this.displayName = display;
		this.songCharacter = songCharacter;
		this.topColor = topColor != null ? topColor : 0xFFFF0000;
        this.bottomColor = bottomColor != null ? bottomColor : 0xFF00FF00;
		this.folder = Mods.currentModDirectory;
		if(this.folder == null) this.folder = '';
    }
}