package backend;

import lime.utils.Assets;
import openfl.utils.Assets as OpenFlAssets;
import haxe.Json;

typedef TrackInfo = 
{
    var song:String;
    var character:String;
    var title:String;
    var description:String;
}

typedef TrackFile = 
{
    var songs:Array<TrackInfo>;
}

class TrackData {
    public static var tracksLoaded:Map<String, TrackData> = new Map<String, TrackData>();
	public static var tracksList:Array<String> = [];
    public var folder:String = '';

    public var songs:Array<TrackInfo> = [];

    public var fileName:String;

    public function new(trackFile:TrackFile, fileName:String) {
		// here ya go - MiguelItsOut
		for (field in Reflect.fields(trackFile))
			if(Reflect.fields(this).contains(field)) // Reflect.hasField() won't fucking work :/
				Reflect.setProperty(this, field, Reflect.getProperty(trackFile, field));

		this.fileName = fileName;
	}

    private static function getTracksFile(path:String):TrackFile {
		var rawJson:String = null;
		#if MODS_ALLOWED
		if(FileSystem.exists(path)) {
			rawJson = File.getContent(path);
		}
		#else
		if(OpenFlAssets.exists(path)) {
			rawJson = Assets.getText(path);
		}
		#end

		if(rawJson != null && rawJson.length > 0) {
			return cast tjson.TJSON.parse(rawJson);
		}
		return null;
	}

    private static function addTracks(tracksToCheck:String, path:String, directory:String, i:Int, originalLength:Int)
	{
		if(!tracksLoaded.exists(tracksToCheck))
		{
			var tracks:TrackFile = getTracksFile(path);
			if(tracks != null)
			{
				var trackFile:TrackData = new TrackData(tracks, tracksToCheck);
				if(i >= originalLength)
				{
					#if MODS_ALLOWED
					trackFile.folder = directory.substring(Paths.mods().length, directory.length-1);
					#end
				}
				tracksLoaded.set(tracksToCheck, trackFile);
				tracksList.push(tracksToCheck);
			}
		}
	}

    public static function reloadTracksFiles(isStoryMode:Null<Bool> = false)
	{
		tracksList = [];
		tracksLoaded.clear();
		#if MODS_ALLOWED
		var directories:Array<String> = [Paths.mods(), Paths.getSharedPath()];
		var originalLength:Int = directories.length;

		for (mod in Mods.parseList().enabled)
			directories.push(Paths.mods(mod + '/'));
		#else
		    var directories:Array<String> = [Paths.getSharedPath()];
		    var originalLength:Int = directories.length;
		#end

        for(i in 0...directories.length)
        {
            var fileToCheck:String = directories[i] + 'data/tracks.json';
            if(!tracksLoaded.exists(directories[i])) {
                var collection:TrackFile = getTracksFile(fileToCheck);
                if(collection != null)
                {
                    var trackFile:TrackData = new TrackData(collection, directories[i]);

                    #if MODS_ALLOWED
                    if(i >= originalLength) {
                        trackFile.folder = directories[i].substring(Paths.mods().length, directories[i].length-1);
                    }
                    #end

                    tracksLoaded.set(directories[i], trackFile);
                    tracksList.push(directories[i]);
                }
            }
        }

        #if MODS_ALLOWED
		for (i in 0...directories.length) {
            if(!tracksLoaded.exists(directories[i])) {
			    var directory:String = directories[i] + 'data/';
			    if(FileSystem.exists(directory)) {
				    var path:String = directory + 'tracks.json';
				    if(FileSystem.exists(path))
				    {
					    addTracks(directories[i], path, directories[i], i, originalLength);
				    }
			    }
            }
		}
        #end
	}
}