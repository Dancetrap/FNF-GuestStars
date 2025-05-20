package substates;

import backend.WeekData;
import backend.TrackData;
import backend.Highscore;

import flixel.FlxSubState;
import flixel.ui.FlxBar;
import objects.HealthIcon;
import objects.RankingIcon;
import objects.AlbumCover;

import objects.Character;

import states.GuestStarsLogsState;

class RankingSubState extends MusicBeatSubstate
{
    var song:String;
    var artist:String;
    var songPath:String;
    var diff:Int;

    var score:Int;
    var misses:Int;
    var accuracy:Float;
    var grade:String;
    var exitCallback:Void->Void = null;

    var previousScore:Int;
    var previousGrade:String;
    var displayAccuracy:Float = 0;
    var displayMisses:Int = 1;

    public var bar:FlxBar;
    public var rank:RankingIcon;
    public var perfectRank:RankingIcon;
    public var logCongrats:Alphabet;
    public var albumCover:AlbumCover;
    public var songTxt:FlxText;
    public var boyfriend:Character = null;
    var resultsBox:FlxSprite;
    var results:FlxText;

    var ultraComboGroup:FlxSpriteGroup;
    var rankingGroup:FlxSpriteGroup;

    public function new(song:String = "shit", ?artist:String = "", diff:Int = 0, score:Int = 0, misses:Int = 0, accuracy:Float = 0.99, previousScore:Int = 0, previousGrade:String = "NaN", returnCallback:Void->Void = null)
    {
        super();
        this.song = song;
        songPath = Paths.formatToSongPath(song);
        this.artist = artist;
        this.diff = diff;
        this.score = score;
        this.misses = misses;
        this.accuracy = accuracy;
        this.previousScore = previousScore;
        this.previousGrade = previousGrade;
        exitCallback = returnCallback;

        newHighscore = score > previousScore;
        if(GuestStarsLogsState.containsLog(songPath))
            log = GuestStarsLogsState.getLogBySong(songPath); //So that it can display the song's name


        grade = Highscore.getRanking(accuracy, misses);

        //Things to check
        /**
            1. The log entry is not null
            2. The grade is bigger than the previous. For instance, if your previous grade was 'A' and you got an 'S', that would be considered true
            3. The grade is bigger than the 'S' ranking, so either 'FC' or 'P'
            4. The log entry has not already been unlocked
        **/
        unlockedNewLog = log != null && Highscore.compareRankings(grade, previousGrade) && Highscore.compareRankings(grade, "S") && !log.unlocked;

        if(unlockedNewLog)
            log.unlocked = true;
    }

    var canExit:Bool = false;
    var log:LogFile = null;
    var newHighscore:Bool = false;
    var unlockedNewLog:Bool = false;
    var ultraCombo:Bool = false;

    var rankingSFX:FlxSound;
    var barScroll:FlxSound;
    var pitch:Float = 1;
    var barPitch:Float = 1;

    var ultra_combo_sound:FlxSound;

    override function create() {

        var bg:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
        bg.alpha = 0;
        bg.scrollFactor.set();
        bg.updateHitbox();
        bg.screenCenter();
        add(bg);
        FlxTween.tween(bg, {alpha: 0.6}, 0.2);

        rankingGroup = new FlxSpriteGroup();
        add(rankingGroup);

        ultraComboGroup = new FlxSpriteGroup();
        add(ultraComboGroup);

        bar = new FlxBar(0, 0, LEFT_TO_RIGHT, 707, 75, this,
        'displayAccuracy', 0, 1).createImageBar(Paths.image("ranking/ranking_bar_empty"),Paths.image("ranking/ranking_bar_full"));
        bar.screenCenter();
        bar.antialiasing = ClientPrefs.data.antialiasing;
        rankingGroup.add(bar);

        // #if FLX_PITCH FlxG.sound.music.pitch = playbackRate; #end

        rankingSFX = new FlxSound();
        rankingSFX.loadEmbedded(Paths.sound("increment"));
        FlxG.sound.list.add(rankingSFX);

        barScroll = new FlxSound();
        barScroll.loadEmbedded(Paths.sound("barscroll"));
        FlxG.sound.list.add(barScroll);

        ultra_combo_sound = new FlxSound();
        ultra_combo_sound.loadEmbedded(Paths.sound("ULTRAAAAAAAAAAAAAAAAAAAAAAAAA"));
        FlxG.sound.list.add(ultra_combo_sound);
        // ultra_combo_sound.onComplete = function() canExit = true;
        
        rank = new RankingIcon(0, 0, "F", function() return displayAccuracy, true, function(){
            if(rank.animation.curAnim.name != "F")
            {
                #if FLX_PITCH rankingSFX.pitch = pitch; #end
                rankingSFX.play(true);
                pitch += 0.1;
            }
        });
    
        rank.scrollFactor.set();
        rank.updateHitbox();
        rankingGroup.add(rank);
        rank.x = FlxG.width - rank.width - 100;
        rank.y = FlxG.height - rank.height - 25;

        perfectRank = new RankingIcon(0, 0, "P");
        perfectRank.scrollFactor.set();
        perfectRank.updateHitbox();
        perfectRank.screenCenter();
        perfectRank.scaleX = perfectRank.scaleY = 0;
        perfectRank.scale.set(0, 0);
        ultraComboGroup.add(perfectRank);

        var string = log != null ? 'Congratulations! You unlocked "${log.title}"!' : "";
        logCongrats = new Alphabet(0, bar.y + bar.height + 5, string, true);
        logCongrats.visible = false;
        rankingGroup.add(logCongrats);
        var scl = 0.3;
        logCongrats.setScale(scl);
        logCongrats.screenCenter(X);
        while(logCongrats.width >= bar.width)
        {
            scl -= 0.01;
            logCongrats.setScale(scl);
            logCongrats.screenCenter(X);
        }

        resultsBox = new FlxSprite(0, -100).loadGraphic(Paths.image("ranking/resultsBar"));
        resultsBox.setGraphicSize(FlxG.width, resultsBox.height);
        resultsBox.updateHitbox();
        resultsBox.y -= resultsBox.height;
        rankingGroup.add(resultsBox);
        
        results = new FlxText(0, resultsBox.y + resultsBox.height, 0, "RESULTS!", 36);
        results.setFormat(Paths.font("Ethnocentric Rg It.otf"), 48, FlxColor.WHITE, CENTER);
        results.screenCenter(X);
        results.y -= results.height + 5;
        rankingGroup.add(results);
        

        songTxt = new FlxText(0, 40, 600, '${song} - Marc Cea', 30);
        songTxt.setFormat(Paths.font("nikkyou.ttf"), 36, FlxColor.WHITE, RIGHT);
        songTxt.antialiasing = ClientPrefs.data.antialiasing;
        // rankingGroup.add(songTxt);

        var albumShadow = new AlbumCover(songPath);
        albumShadow.setGraphicSize(250, 250);
        albumShadow.updateHitbox();
        albumShadow.angle = -5;
        albumShadow.color = FlxColor.BLACK;
        albumShadow.alpha = 0.5;
        rankingGroup.add(albumShadow);

        albumCover = new AlbumCover(FlxG.width + albumShadow.width, 25, songPath);
        albumCover.setGraphicSize(albumShadow.width, albumShadow.height);
        albumCover.updateHitbox();
        // albumCover.x = FlxG.width - albumCover.width - 25;
        albumCover.angle = albumShadow.angle;
        rankingGroup.add(albumCover);

        albumShadow.setTracker(albumCover, 10, 10, 4);
        songTxt.x = albumCover.x - songTxt.width - 10;

        boyfriend = new Character(0, 0, 'bf', false);
		boyfriend.setGraphicSize(Std.int(boyfriend.width * 0.75));
		boyfriend.updateHitbox();
		boyfriend.dance();
		boyfriend.animation.finishCallback = function (name:String) boyfriend.dance();
        boyfriend.y = FlxG.height - boyfriend.height - 60;
		// boyfriend.visible = false;
        // rankingGroup.add(boyfriend);


        cameras = [FlxG.cameras.list[FlxG.cameras.list.length - 1]];
        super.create();
        
        if(FlxG.sound.music != null) FlxG.sound.music.volume = 0;

        if(accuracy >= 1)
        {
            //ULTRA COMBO
            ultra_combo_sound.play();
            rankingGroup.visible = false;
            ultraCombo = true;
            isPlaying = true;
            perfectTimer = new FlxTimer().start((ultra_combo_sound.length * 0.5)/1000, function(tmr:FlxTimer){
                numTween = FlxTween.num(0, 1, (ultra_combo_sound.length * 0.5)/1000, {onComplete: function(twn:FlxTween){
                    displayFullPerfect();
                }}, function(num:Float){
                    perfectRank.scaleX = perfectRank.scaleY = num;
                });

                angleTween = FlxTween.angle(perfectRank, -1080, 0, (ultra_combo_sound.length * 0.5)/1000);
            });


        }
        else
        {
            // Regular Group
            ultraComboGroup.visible = false;
            barTimer = new FlxTimer().start(0.5, function(tmr:FlxTimer){ startBar = true; });
            FlxTween.tween(albumCover, {x: FlxG.width - albumCover.width - 25}, 2, {ease: FlxEase.elasticOut /**FlxEase.quadOut**/});
            FlxTween.tween(resultsBox, {y: -7 * resultsBox.height/16}, 2, {ease: FlxEase.elasticOut /**FlxEase.quadOut**/, onUpdate: function(twn:FlxTween){
                results.y = resultsBox.y + resultsBox.height - results.height - 5;
            }});
        }

        // trace(score);
        // trace(grade);

        // If grade is bigger than previous grade and grade is bigger than 'S' and the song has a log file, display "You've unlocked ___"
    }

    var numTween:FlxTween;
    var angleTween:FlxTween;
    var barTimer:FlxTimer;
    var perfectTimer:FlxTimer;

    function waveEffect(id:Int = 0)
    {
        if(logCongrats.members.length == 0) return;

        var play:Bool = false;
        FlxTween.tween(logCongrats.members[id], {y: logCongrats.members[id].y - 10}, 0.25, {type: PINGPONG, ease: FlxEase.quadInOut, onUpdate: function(twn:FlxTween) {
            if(twn.percent >= 0.4 && !play)
            {
                id++;
                if(logCongrats != null && id >= logCongrats.members.length)
                {
                    id = 0;
                    new FlxTimer().start(0.125, function(tmr:FlxTimer) waveEffect(id));
                }
                else
                    waveEffect(id);
                play = true;
            }
        }, onComplete: function(twn:FlxTween){
            if(twn.executions == 2) twn.cancel();
        }});
    }

    var startBar:Bool;
    var isPlaying:Bool;
    var prevAcc:Float = 0;
    var holdTimer:Float = 0;
    var soundHasBeenPlayed:Bool = false;

    override function update(elapsed:Float){
        
        if(!ultraCombo)
        {
            if(startBar && !canExit)
            {
            displayAccuracy += elapsed * 0.25;
            displayAccuracy = FlxMath.bound(displayAccuracy, 0, accuracy);
            isPlaying = true;
            if(prevAcc == displayAccuracy)
            {
                holdTimer += elapsed;
                if(holdTimer > 0.5)
                {
                    soundHasBeenPlayed = true;
                    // isPlaying = false;
                    // canExit = true;
                    startBar = false;
                    new FlxTimer().start(0.5, function(tmr:FlxTimer){ displayMissesWithFinalScore(); });
                }
            }
            else
            {
                #if FLX_PITCH barScroll.pitch = barPitch; #end
                barScroll.play(true);
                barPitch += 0.05;
            }
            prevAcc = displayAccuracy;
            }
        }

        if(controls.ACCEPT || controls.BACK)
        {
            if(canExit)
            {
                if(exitCallback != null) exitCallback();
                exitCallback = null;
                isClosing = true;
                for(i in 0...logCongrats.members.length) FlxTween.cancelTweensOf(logCongrats.members[i]);
                ultra_combo_sound.stop();
                if(FlxG.sound.music != null) FlxG.sound.music.volume = 1;
                close();
            }

            if(isPlaying)
            {
                if(ultraCombo) displayFullPerfect();
                else displayMissesWithFinalScore(true);
            }
        }
        // rank.playByAccuracy(displayAccuracy, true);

        // results.y = resultsBox.y - resultsBox.height;

        super.update(elapsed);
    }

    var isClosing:Bool = false;
    function displayMissesWithFinalScore(skipped:Bool = false)
    {
        displayAccuracy = accuracy;
        displayMisses = misses;
        rank.valueFunction = null;
        isPlaying = false;
        var finalGrade = rank.playByAccuracy(displayAccuracy, displayMisses, true, true);
        canExit = true;
        if(barTimer != null) barTimer.cancel();
        // trace(finalGrade);
        // rank.updateHitbox();
        if(finalGrade == "FC")
        {
            pitch = 1 + 0.6;
            #if FLX_PITCH rankingSFX.pitch = pitch; #end
            rankingSFX.play(true);
            logCongrats.visible = true;
            waveEffect();
        }
        else
        {
            if(skipped)
            {
                var mult = Highscore.scoreChart.indexOf(finalGrade);
                #if FLX_PITCH rankingSFX.pitch = 1 + 0.1 * mult; #end
                if(finalGrade != "F" && !soundHasBeenPlayed) rankingSFX.play(true);
            }
        }

    }

    function displayFullPerfect()
    {
        if(numTween != null) numTween.cancel();
        if(angleTween != null) angleTween.cancel();
        if(barTimer != null) barTimer.cancel();
        if(perfectTimer != null) perfectTimer.cancel();

        perfectRank.scaleX = perfectRank.scaleY = 1;
        perfectRank.scale.set(2 * perfectRank.scaleX, 2 * perfectRank.scaleX);
        perfectRank.angle = 0;

        isPlaying = false;
        canExit = true;
    }
}