package backend;

class Highscore
{
	public static var weekScores:Map<String, Int> = new Map();
	public static var songScores:Map<String, Int> = new Map<String, Int>();
	public static var songRating:Map<String, Float> = new Map<String, Float>();
	public static var songGrades:Map<String, String> = new Map<String, String>();

	public static function resetSong(song:String, diff:Int = 0):Void
	{
		var daSong:String = formatSong(song, diff);
		setScore(daSong, 0);
		setRating(daSong, 0);
	}

	public static function resetWeek(week:String, diff:Int = 0):Void
	{
		var daWeek:String = formatSong(week, diff);
		setWeekScore(daWeek, 0);
	}

	public static function saveScore(song:String, score:Int = 0, ?diff:Int = 0, ?rating:Float = -1):Void
	{
		var daSong:String = formatSong(song, diff);

		if (songScores.exists(daSong)) {
			if (songScores.get(daSong) < score) {
				setScore(daSong, score);
				if(rating >= 0) setRating(daSong, rating);
			}
		}
		else {
			setScore(daSong, score);
			if(rating >= 0) setRating(daSong, rating);
		}
	}

	public static var scoreChart(get, null):Array<String>;
	
	private static function get_scoreChart()
	{
		return ["NaN", "F", "D", "C", "B", "A", "S", "FC", "P"];
	}
		
	public static function saveRanking(song:String, ?diff:Int = 0, ?rating:Float = -1, ?misses:Int = -1)
	{
		var daSong:String = formatSong(song, diff);

		var curIndex:Int = 0;
		var rank = getRanking(rating, misses);
		// trace(rank);

		if(songGrades.exists(daSong))
		{
			var prevRank = getGrade(song, diff);
			curIndex = scoreChart.indexOf(prevRank);
			if(scoreChart.indexOf(rank) > curIndex)
				setGrade(daSong, rank);
		}
		else
		{
			setGrade(daSong, rank);
		}
	}

	public static function getRanking(?rating:Float = -1, ?misses:Int = -1, ?ignoreNAN:Bool = false):String
	{
		if(rating >= 1) return "P"; //For Perfect!
		else if(misses == 0) return "FC"; //For Full Combo!
		else if(rating < 1)
		{
			if(rating <= 0 && !ignoreNAN)
				return "NaN"; //For Not entirely full
			// else if(FlxMath.inBounds(rating, 0.95, 0.9999999999999999999999))
			// 	return "S";
			// else if(FlxMath.inBounds(rating, 0.9, 0.94999999999999999999999))
			// 	return "A";
			// else if(FlxMath.inBounds(rating, 0.8, 0.89999999999999999999999))
			// 	return "B";
			// else if(FlxMath.inBounds(rating, 0.7, 0.79999999999999999999999))
			// 	return "C";
			// else if(FlxMath.inBounds(rating, 0.5, 0.69999999999999999999999))
			// 	return "D";
			// else if(FlxMath.inBounds(rating, 0.0, 0.49999999999999999999999))
			// 	return "F";
			else if(FlxMath.inBounds(rating, 23/24, 0.9999999999999999999999))
				return "S";
			else if(FlxMath.inBounds(rating, 5/6, 23/24 - 0.00000000000000000000001))
				return "A";
			else if(FlxMath.inBounds(rating, 2/3, 5/6 - 0.00000000000000000000001))
				return "B";
			else if(FlxMath.inBounds(rating, 1/2, 2/3 - 0.00000000000000000000001))
				return "C";
			else if(FlxMath.inBounds(rating, 1/3, 1/2 - 0.00000000000000000000001))
				return "D";
			else if(FlxMath.inBounds(rating, 0.0, 1/3 - 0.00000000000000000000001))
				return "F";
		}
		return "NaN";
	}

	public static function compareRankings(newGrade:String, oldGrade:String):Bool
	{
		return scoreChart.indexOf(newGrade) > scoreChart.indexOf(oldGrade);
	}

	public static function saveWeekScore(week:String, score:Int = 0, ?diff:Int = 0):Void
	{
		var daWeek:String = formatSong(week, diff);

		if (weekScores.exists(daWeek))
		{
			if (weekScores.get(daWeek) < score)
				setWeekScore(daWeek, score);
		}
		else
			setWeekScore(daWeek, score);
	}

	/**
	 * YOU SHOULD FORMAT SONG WITH formatSong() BEFORE TOSSING IN SONG VARIABLE
	 */
	static function setScore(song:String, score:Int):Void
	{
		// Reminder that I don't need to format this song, it should come formatted!
		songScores.set(song, score);
		FlxG.save.data.songScores = songScores;
		FlxG.save.flush();
	}
	static function setWeekScore(week:String, score:Int):Void
	{
		// Reminder that I don't need to format this song, it should come formatted!
		weekScores.set(week, score);
		FlxG.save.data.weekScores = weekScores;
		FlxG.save.flush();
	}

	static function setRating(song:String, rating:Float):Void
	{
		// Reminder that I don't need to format this song, it should come formatted!
		songRating.set(song, rating);
		FlxG.save.data.songRating = songRating;
		FlxG.save.flush();
	}

	static function setGrade(song:String, grade:String):Void
	{
		// Reminder that I don't need to format this song, it should come formatted!
		songGrades.set(song, grade);
		// trace(grade + "!");
		FlxG.save.data.songGrades = songGrades;
		FlxG.save.flush();
	}

	public static function formatSong(song:String, diff:Int):String
	{
		return Paths.formatToSongPath(song) + Difficulty.getFilePath(diff);
	}

	public static function getScore(song:String, diff:Int):Int
	{
		var daSong:String = formatSong(song, diff);
		if (!songScores.exists(daSong))
			setScore(daSong, 0);

		return songScores.get(daSong);
	}

	public static function getRating(song:String, diff:Int):Float
	{
		var daSong:String = formatSong(song, diff);
		if (!songRating.exists(daSong))
			setRating(daSong, 0);

		return songRating.get(daSong);
	}

	public static function getWeekScore(week:String, diff:Int):Int
	{
		var daWeek:String = formatSong(week, diff);
		if (!weekScores.exists(daWeek))
			setWeekScore(daWeek, 0);

		return weekScores.get(daWeek);
	}

	public static function getGrade(song:String, diff:Int):String
	{
		var daSong:String = formatSong(song, diff);
		if (!songGrades.exists(daSong))
			setGrade(daSong, "NaN");

		return songGrades.get(daSong);
	}
	

	public static function load():Void
	{
		if (FlxG.save.data.weekScores != null)
		{
			weekScores = FlxG.save.data.weekScores;
		}
		if (FlxG.save.data.songScores != null)
		{
			songScores = FlxG.save.data.songScores;
		}
		if (FlxG.save.data.songRating != null)
		{
			songRating = FlxG.save.data.songRating;
		}
		if(FlxG.save.data.songGrades != null)
		{
			songGrades = FlxG.save.data.songGrades;
		}
	}
}