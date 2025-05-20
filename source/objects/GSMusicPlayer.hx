package objects;

import flixel.FlxBasic;
import flixel.group.FlxGroup;
import flixel.util.FlxStringUtil;
import backend.Song;
import openfl.utils.AssetType;
import openfl.utils.Assets;
// import object.Character;
import haxe.Json;
/**
 * Music player used for Freeplay
*/
class GSMusicPlayer extends FlxBasic
{
    public var playingMusic:Bool = false;

    var startTime:Float = 0;
    var endTime:Float = 0;
    var fadeTime:Float = 1;
    var vocals:FlxSound;
    var opponentVocals:FlxSound;
    var inst:FlxSound;

    // public var playing(get, never):Bool;
	// public var paused(get, never):Bool;

    public function new()
    {
		super();

        inst = new FlxSound();
        vocals = new FlxSound();
        opponentVocals = new FlxSound();

        FlxG.sound.list.add(vocals);
        FlxG.sound.list.add(inst);
        FlxG.sound.list.add(opponentVocals);
    }

    override function update(elapsed:Float) {
        super.update(elapsed);

        if(inst.playing)
        {
            if(inst.time >= endTime - fadeTime)
            {
                inst.fadeOut(fadeTime, 0);
            }
            else if(inst.time <= startTime)
            {
                inst.fadeIn(fadeTime, 0, 1);
            }
        }

        if(vocals.playing)
        {
            if(vocals.time >= endTime - fadeTime)
            {
                vocals.fadeOut(fadeTime, 0);
            }
            else if(vocals.time <= startTime)
            {
                vocals.fadeIn(fadeTime, 0, 1);
            }
        }

        if(opponentVocals.playing)
        {
            if(opponentVocals.time >= endTime - fadeTime)
            {
                opponentVocals.fadeOut(fadeTime, 0);
            }
            else if(opponentVocals.time <= startTime)
            {
                opponentVocals.fadeIn(fadeTime, 0, 1);
            }
        }
    }

    override function destroy()
    {
        super.destroy();
        inst.stop();
        vocals.stop();
        opponentVocals.stop();
    }

    public function play(song:SwagSong, ?start:Float = 0, ?end:Null<Float>, ?fadeTime:Float = 1)
    {
        FlxG.sound.music.pause();
        this.fadeTime = fadeTime;
        startTime = start;
        
        if(song != null)
        {
            var playerVocalFile:String;
            var opponentVocalFile:String;

            var characterPath:String = 'characters/${song.player1}.json';
            var path:String = Paths.getPath(characterPath, TEXT, null, true);
            #if MODS_ALLOWED
            if (FileSystem.exists(path))
            {
                var json = Json.parse(File.getContent(path));
                playerVocalFile = json.vocalsFile;
            }
            #else
            if (Assets.exists(path))
            #end
            {
                var json = Json.parse(Assets.getText(path));
                playerVocalFile = json.vocalsFile;
            }

            characterPath = 'characters/${song.player2}.json';
            path = Paths.getPath(characterPath, TEXT, null, true);
            #if MODS_ALLOWED
            if (FileSystem.exists(path))
            {
                var json = Json.parse(File.getContent(path));
                opponentVocalFile = json.vocalsFile;
            }
            #else
            if (Assets.exists(path))
            #end
            {
                var json = Json.parse(Assets.getText(path));
                opponentVocalFile = json.vocalsFile;
            }


            if (song.needsVoices)
            {
                var playerVocals = Paths.voices(song.song, (playerVocalFile == null || playerVocalFile.length < 1) ? 'Player' : playerVocalFile);
				vocals.loadEmbedded(playerVocals != null ? playerVocals : Paths.voices(song.song));
				
				var oppVocals = Paths.voices(song.song, (opponentVocalFile == null || opponentVocalFile.length < 1) ? 'Opponent' : opponentVocalFile);
				if(oppVocals != null) opponentVocals.loadEmbedded(oppVocals);
            }

            inst.loadEmbedded(Paths.inst(song.song));

            if(end == null)
            {
                this.endTime = inst.length;
            }

            inst.play(true, start, end);
            vocals.play(true, start, end);
            opponentVocals.play(true, start, end);

            inst.fadeIn(fadeTime, 0, 1);
            vocals.fadeIn(fadeTime, 0, 1);
            opponentVocals.fadeIn(fadeTime, 0, 1);
        }

    }

    public function stop()
    {
        FlxG.sound.music.resume();

        inst.stop();
        vocals.stop();
        opponentVocals.stop();
    }

    // function get_playing():Bool 
    // {
    //     return FlxG.sound.music.playing;
    // }
    
    // function get_paused():Bool 
    // {
    //     @:privateAccess return FlxG.sound.music._paused;
    // }
}