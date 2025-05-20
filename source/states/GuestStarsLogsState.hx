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

import flixel.graphics.FlxGraphic;

import flixel.effects.particles.FlxEmitter;
import flixel.effects.particles.FlxParticle;

import objects.GradientBG;

typedef LogFile = 
{
    var file:String; //the song file to unlock
    var displaySong:String; //the song name you want displayed
    var title:String; //the name of the file
    var text:String; //the text in the file
    var folder:String; //text folder;
    var unlocked:Null<Bool>; //if the song has been unlocked
}

class LogData
{
    public var fileName:String;
    public var folder:String;

    public function new(logFile:LogFile, fileName:String) {
		// here ya go - MiguelItsOut
		for (field in Reflect.fields(logFile))
			if(Reflect.fields(this).contains(field)) // Reflect.hasField() won't fucking work :/
				Reflect.setProperty(this, field, Reflect.getProperty(logFile, field));

		this.fileName = fileName;
	}
}

class GuestStarsLogsState
{
    public static var songLogs:Map<String, LogFile> = new Map<String, LogFile>();
    public static var logFiles:Array<LogFile> = [];
    public var logIcons:FlxTypedSpriteGroup<LogIcon>;

    public static function loadLogs()
    {
        //I believe this will crash if I don't put this in
        Difficulty.list = ["Normal"];
        PlayState.storyDifficulty = 1;

        songLogs.clear();
        logFiles = [];
        #if MODS_ALLOWED
		var directories:Array<String> = [Paths.getSharedPath(), Paths.mods()];
		var originalLength:Int = directories.length;

		for (mod in Mods.parseList().enabled)
			directories.push(Paths.mods(mod + '/'));
		#else
		    var directories:Array<String> = [Paths.getSharedPath()];
		    var originalLength:Int = directories.length;
		#end

        var loadedLogs = [];

        for(i in 0...directories.length)
        {
            var fileToCheck:String = directories[i] + 'logs';
            if(FileSystem.readDirectory(fileToCheck) == null)
                continue;

            for(log in FileSystem.readDirectory(fileToCheck))
            {
                var fileToRead:String = directories[i] + 'logs/' + log;
                var file:LogFile = getLogFile(fileToRead);
                if(file != null)
                {
                    if(file.file != null)
                    {
                        
                    }
                    #if MODS_ALLOWED
                        file.folder = directories[i].substring(Paths.mods().length, directories[i].length-1);
                    #else
                        file.folder = "";
                    #end
                    songLogs.set(file.folder + "/" + file.file, file);
                    loadedLogs.push(file);
                }
                    
            }
        }

        for (i in 0...TrackData.tracksList.length) {
            var track:TrackData = TrackData.tracksLoaded.get(TrackData.tracksList[i]);

            TrackData.setDirectoryFromTrack(track);
            for (song in track.songs)
            {
                for(log in loadedLogs)
                {
                    if(log.file != null && log.folder == Mods.currentModDirectory)
                    {
                        if(log.file == song.song)
                        {
                            logFiles.push(log);
                            var curRank = Highscore.getGrade(log.file, 0);
                            log.unlocked = Highscore.compareRankings(curRank, "S");
                            // break;
                        }
                        else if(log.file.contains("-"))
                        {
                            var spt = log.file.split("-");
                            spt.remove(spt[spt.length - 1]);
                            var string = spt.join("-");
                            if(string == song.song)
                            {
                                if(song.tags != null)
                                {
                                    for(tag in song.tags)
                                    {
                                        if(tag.toLowerCase() != "normal")
                                            if(log.file == string + "-" + tag.toLowerCase())
                                            {
                                                logFiles.push(log);
                                                var curRank = Highscore.getGrade(log.file, 0);
                                                log.unlocked = Highscore.compareRankings(curRank, "S");
                                                // trace(log.unlocked);
                                                // break;
                                            }
                                    }
                                }
                            }
                        }
                        
                        
                    }
                }
            }
        }
    }

    private static function getLogFile(path:String):LogFile {
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

    public static function getLogBySong(songName:String):LogFile
    {
        for(file in logFiles)
        {
            if(file.file == songName && file.folder == Mods.currentModDirectory) return file;
        }
        return null;
    }

    public static function containsLog(songName:String):Bool
    {
        for(file in logFiles)
        {
            if(file.file == songName && file.folder == Mods.currentModDirectory) return true;
        }
        return false;
    }
}

class LogIcon extends FlxSpriteGroup
{
    var unlocked:Bool;
    public var isLocked(get, null):Bool;
    var selected:Bool;
    public var isSelected(default, set):Bool;

    var songFileName:String = "";
    var songName:String = "";
    var title:String = "";
    var text:String = "";

    var yProperty:Float; //A property in order to get their grid placement
    public var yValue(get, null):Float;

    public var description(get, null):String;

    public function new(?x:Float = 0, ?y:Float = 0, file:LogFile = null)
    {
        super(x,y);
        yProperty = y;

        if(file != null)
        {
            songFileName = file.file != null ? file.file : "";
            songName = file.displaySong != null ? file.displaySong : "";
            title = file.title != null ? file.title : "";
            text = file.text != null ? file.text : "";
            unlocked = file.unlocked != null ? file.unlocked : false;
        }

        // var curRank = Highscore.getGrade(songFileName, 0);
        // unlocked = Highscore.compareRankings(curRank, "S"); //Check if the player has recieved a full combo or higher on a song
        
        border = new FlxSprite().makeGraphic(150, 150, FlxColor.WHITE);
        add(border);

        var box:FlxSprite = new FlxSprite(12.5,12.5).makeGraphic(125, 125, FlxColor.WHITE);
        add(box);

        if(!unlocked)
        {
            var lock:FlxSprite = new FlxSprite(25,25).loadGraphic(Paths.image("lock"));
            lock.setGraphicSize(100, 100);
            lock.updateHitbox();
            add(lock);
        }
        // trace(unlocked);
    }
    
    var border:FlxSprite;

    private function get_isLocked()
    {
        return !unlocked;
    }

    private function set_isSelected(value: Bool)
    {
        isSelected = value;
        if(border != null)
            border.color = value ? FlxColor.YELLOW : FlxColor.WHITE;
        return isSelected;
    }

    private function get_description()
    {
        if(!unlocked)
            return 'Get a full combo in "$songName" to unlock';
        
        return title;
    }

    private function get_yValue()
    {
        return yProperty;
    }

    public function open(mouseClick:Bool = false)
    {
        if(isSelected)
        {
            if(unlocked)
            {
                FlxG.state.openSubState(new GuestStarsLogEntry(text, mouseClick));
                return;
            }
            else
                FlxG.camera.shake(0.005, 0.25);
        }

    }
}

class GuestStarsLogEntry extends MusicBeatSubstate
{
    var text:String;
    var paper:FlxSprite;
    var infoText:FlxSpriteGroup;
    // var infoText:FlxText;
    var paperCam:FlxCamera;

    public function new(text:String = "Hello!", mouseClicked:Bool = false)
    {
        super();
        this.text = text;

        canClose = !mouseClicked;
        // trace("Hello!");
    }
    
    override function create()
    {
        super.create();
        var paperHeight = FlxG.height * 0.9;
        var paperWidth = paperHeight * Math.sqrt(0.5);

        var bg:FlxSprite = new FlxSprite().makeGraphic(1, 1, FlxColor.BLACK);
		bg.scale.set(FlxG.width, FlxG.height);
		bg.updateHitbox();
		bg.alpha = 0.6;
		bg.scrollFactor.set();
		add(bg);

        paper = new FlxSprite().makeGraphic(1, 1, FlxColor.WHITE);
        paper.scale.set(paperWidth, paperHeight);
        paper.updateHitbox();
        paper.screenCenter();
        add(paper);

        var rectHeight = FlxG.height * 0.875;
        var rectWidth = FlxG.height * 0.75 * Math.sqrt(0.5);

        var margin:FlxSprite = new FlxSprite().makeGraphic(1, 1, FlxColor.WHITE);
        margin.scale.set(rectWidth, rectHeight);
        margin.updateHitbox();
        margin.screenCenter();

        paperCam = new FlxCamera(margin.x, margin.y, Std.int(margin.width), Std.int(margin.height));
        paperCam.bgColor.alpha = 0;
        // paperCam.minScrollY = -10;
        // paperCam.scroll.y = -10;
        paperCam.minScrollY = 0;
        FlxG.cameras.add(paperCam, false);

        infoText = new FlxSpriteGroup(0,10);
        infoText.cameras = [paperCam];
        add(infoText);

        // <c> for center
        // <r> for right
        // <j> for justify
        var stringArray:Array<Array<String>> = [];

        var containsAlignment = text.contains("<c>") || text.contains("<r>") || text.contains("<j>");
        // trace(containsAlignment);
        var stringSegment:String = "";
        var prevAlign:String = "<l>";
        // trace(text.contains("\n"));

        if(containsAlignment)
            for(str in text.split(""))
            {
                stringSegment += str;
                if(stringSegment.contains("<c>") || stringSegment.contains("<r>") || stringSegment.contains("<j>"))
                {
                    var savedString = stringSegment;
                    var legend = "";
                    for(i in stringSegment.length - 3...stringSegment.length)
                    {
                        legend += stringSegment.split("")[i];
                    }

                    savedString = savedString.replace(legend, "");
                    if(savedString.length != 0)
                    {
                        stringArray.push([savedString, prevAlign]);
                        if(prevAlign == legend)
                            legend = "<l>";
                    }
                    prevAlign = legend;
                    stringSegment = "";
                }
            }
        
        if(stringArray.length == 0)
        {
            var text:FlxText = new FlxText(0,0,paperCam.width, text, 24);
            text.setFormat(Paths.font("natumemozi.ttf"), 16, FlxColor.BLACK);
            text.applyMarkup(text.text, [new FlxTextFormatMarkerPair(new FlxTextFormat(FlxColor.BLACK, true), "<b>")]);
            // text.cameras = [paperCam];
            infoText.add(text);
        }
        else
        {
            for(string in stringArray)
            {
                var text:FlxText = null;

                if(infoText.members.length == 0)
                {
                    text = new FlxText(0,0,paperCam.width, string[0], 24);
                }
                else
                {
                    var newY:Float = infoText.members[infoText.members.length - 1].y + infoText.members[infoText.members.length - 1].height;
                    text = new FlxText(0, newY, paperCam.width, string[0], 24);
                }

                text.setFormat(Paths.font("natumemozi.ttf"), 16, FlxColor.BLACK);
                switch(string[1])
                {
                    case "<c>":
                        text.alignment = CENTER;
                    case "<r>":
                        text.alignment = RIGHT;
                    case "<j>":
                        text.alignment = JUSTIFY;
                    default:
                        text.alignment = LEFT;
                }
                text.applyMarkup(text.text, [new FlxTextFormatMarkerPair(new FlxTextFormat(FlxColor.BLACK, true), "<b>")]);
                    // text.cameras = [paperCam];
                infoText.add(text);
            }

        }

        
        barLine = new FlxSprite(margin.x + margin.width + 10, margin.y).makeGraphic(2, Std.int(margin.height), FlxColor.BLACK);
        add(barLine);

        scrollBar = new FlxSpriteGroup(margin.x + margin.width, margin.y);
        add(scrollBar);

        if(infoText.height > paperCam.height) //Find the ratio between the camera height and text height;
            multiple = paperCam.height/infoText.height;

        var border:FlxSprite = new FlxSprite().makeGraphic(20, Std.int(margin.height * multiple), FlxColor.BLACK);
        scrollBar.add(border);

        var bar:FlxSprite = new FlxSprite(2.5,2.5).makeGraphic(15, Std.int(margin.height * multiple) - 5, FlxColor.WHITE);
        scrollBar.add(bar);

        if(infoText.height > paperCam.height)
            paperCam.maxScrollY = infoText.height + 10;
        else
        {
            paperCam.maxScrollY = paperCam.height - 10;
            barLine.visible = false;
            scrollBar.visible = false;
        }

        // I'll have to figure out how to get this working at some point
        maxEnd = Math.floor(paperCam.maxScrollY * (1-multiple/1.0125));

        //Multiples - [0.404884318766067, 0.503194888178914, 0.675965665236052]
        //Differences - [936, 632, 312]
        //Max Scroll - [1566, 1262, 942]
        //Max End - [931, 626, 305]

        //Bar Ends - [420, 358, ]
        //End scrolls - [831.25, 547.312849162011, 250.1]
    }

    var barLine:FlxSprite;
    var scrollBar:FlxSpriteGroup;
    var invisibleBar:FlxSprite;
    var clickedOnBar:Bool;
    var barOffset:Float;

    private var multiple:Float = 1.0;
    private var maxEnd:Float;
    private var canClose:Bool = false;

    override function update(elapsed:Float) {
        super.update(elapsed);

        if(FlxG.mouse.justPressed)
        {
            clickedOnBar = FlxG.mouse.overlaps(scrollBar);
            barOffset = FlxG.mouse.y - scrollBar.y;

            // trace(FlxG.mouse.overlaps(barLine));
        }
            
        if(FlxG.mouse.justReleased)
            clickedOnBar = false;

        if(clickedOnBar && scrollBar.visible)
        {
            scrollBar.y = FlxG.mouse.y - barOffset;
            var slope = maxEnd/(barLine.height - scrollBar.height);
            paperCam.scroll.y = slope*(scrollBar.y - barLine.y); //Starts at top but not at bottom
            // paperCam.scroll.y = slope*(scrollBar.y); //Starts at bottom but not at top
        }
        else
        {
            if(FlxG.mouse.wheel != 0)
            {
                scroll(-FlxG.mouse.wheel * 10);
            }
                    
            if(controls.UI_DOWN)
            {
                scroll(5);
            }
            else if(controls.UI_UP)
            {
                scroll(-5);
            }
        }

        scrollBar.y = FlxMath.bound(scrollBar.y, barLine.y, barLine.y + barLine.height - scrollBar.height);
        paperCam.scroll.y = FlxMath.bound(paperCam.scroll.y, paperCam.minScrollY, paperCam.maxScrollY);

        if(controls.BACK)
        {
            FlxG.cameras.remove(paperCam);
            close();
        }

        closeProperties();
    }

    function scroll(value:Float)
    {
        paperCam.scroll.y += value;
        scrollBar.y += value * multiple;
    }

    function closeProperties()
    {
        if(FlxG.mouse.justPressed)
        {
            if(!FlxG.mouse.overlaps(paper) && canClose)
            {
                FlxG.cameras.remove(paperCam);
                close();
            }
            canClose = true;
        }
    
        // if(FlxG.mouse.justReleased)
        //     canClose = true;
    }
}