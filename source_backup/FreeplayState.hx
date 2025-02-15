package;

import openfl.geom.ColorTransform;
import LoadSettings.Settings;
import flixel.system.FlxAssets.FlxSoundAsset;
import flixel.system.FlxSound;
#if desktop
import Discord.DiscordClient;
#end
import flash.text.TextField;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.display.FlxGridOverlay;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import lime.utils.Assets;

using StringTools;

/**
* Freeplay menu
*/
class FreeplayState extends MusicBeatState
{
	var songs:Array<SongMetadata> = [];

	var selector:FlxText;
	var curSelected:Int = 0;
	var curDifficulty:Int = 1;

	var scoreText:FlxText;
	var diffText:FlxText;
	var modSourceText:FlxText;
	var lerpScore:Int = 0;
	var intendedScore:Int = 0;
	var songPlaying:FlxSound = null;

	private var grpSongs:FlxTypedGroup<Alphabet>;
	private var curPlaying:Bool = false;

	private var iconArray:Array<HealthIcon> = [];
	
	var instPlaying:Bool = false;
	var instCooldown:Float = 0;

	override function create()
	{
		Assets.loadLibrary("songs");
		
		var initSonglist = ModSupport.getFreeplaySongs();

		for (i in 0...initSonglist.length)
		{
			var splittedThingy:Array<String> = initSonglist[i].trim().split(":");
			songs.push(new SongMetadata(splittedThingy[1], splittedThingy[0], splittedThingy[2]));
		}

		/* 
			if (FlxG.sound.music != null)
			{
				if (!FlxG.sound.music.playing)
					FlxG.sound.playMusic(Paths.music('freakyMenu'));
			}
		 */

		#if desktop
		// Updating Discord Rich Presence
		DiscordClient.changePresence("In the Menus", null);
		#end

		var isDebug:Bool = false;

		#if debug
		isDebug = true;
		#end

		// if (StoryMenuState.weekUnlocked[2] || isDebug)
		// 	addWeek(['Bopeebo', 'Fresh', 'Dadbattle'], 1, ['dad']);

		// if (StoryMenuState.weekUnlocked[2] || isDebug)
		// 	addWeek(['Spookeez', 'South', 'Monster'], 2, ['spooky']);

		// if (StoryMenuState.weekUnlocked[3] || isDebug)
		// 	addWeek(['Pico', 'Philly', 'Blammed'], 3, ['pico']);

		// if (StoryMenuState.weekUnlocked[4] || isDebug)
		// 	addWeek(['Satin-Panties', 'High', 'Milf'], 4, ['mom']);

		// if (StoryMenuState.weekUnlocked[5] || isDebug)
		// 	addWeek(['Cocoa', 'Eggnog', 'Winter-Horrorland'], 5, ['parents-christmas', 'parents-christmas', 'monster-christmas']);

		// if (StoryMenuState.weekUnlocked[6] || isDebug)
		// 	addWeek(['Senpai', 'Roses', 'Thorns'], 6, ['senpai', 'senpai', 'spirit']);

		// LOAD MUSIC

		// LOAD CHARACTERS

		var bg:FlxSprite = new FlxSprite().loadGraphic(Paths.image('menuBGBlue'));
		add(bg);

		grpSongs = new FlxTypedGroup<Alphabet>();
		add(grpSongs);

		for (i in 0...songs.length)
		{
			var songText:Alphabet = new Alphabet(0, (70 * i) + 30, songs[i].songName, true, false);
			songText.isMenuItem = true;
			songText.targetY = i;
			grpSongs.add(songText);

			var icon:HealthIcon = new HealthIcon(songs[i].songCharacter, false, songs[i].mod);
			icon.sprTracker = songText;

			// using a FlxGroup is too much fuss!
			iconArray.push(icon);
			add(icon);

			// songText.x += 40;
			// DONT PUT X IN THE FIRST PARAMETER OF new ALPHABET() !!
			// songText.screenCenter(X);
		}

		scoreText = new FlxText(FlxG.width * 0.7, 5, 0, "", 32);
		// scoreText.autoSize = false;
		scoreText.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, RIGHT);
		scoreText.antialiasing = true;
		// scoreText.alignment = RIGHT;

		var scoreBG:FlxSprite = new FlxSprite(scoreText.x - 6, 0).makeGraphic(Std.int(FlxG.width * 0.35), 99, 0xFF000000);
		scoreBG.alpha = 0.6;
		add(scoreBG);

		diffText = new FlxText(scoreText.x, scoreText.y + 36, 0, "", 24);
		diffText.font = scoreText.font;
		diffText.antialiasing = true;
		add(diffText);

		modSourceText = new FlxText(scoreText.x, diffText.y + 27, 0, "", 24);
		modSourceText.font = scoreText.font;
		modSourceText.antialiasing = true;
		add(modSourceText);

		add(scoreText);

		changeSelection();
		changeDiff();

		// FlxG.sound.playMusic(Paths.music('title'), 0);
		// FlxG.sound.music.fadeIn(2, 0, 0.8);
		selector = new FlxText();

		selector.size = 40;
		selector.text = ">";
		// add(selector);

		var swag:Alphabet = new Alphabet(1, 0, "swag");

		// JUST DOIN THIS SHIT FOR TESTING!!!
		/* 
			var md:String = Markdown.markdownToHtml(Assets.getText('CHANGELOG.md'));

			var texFel:TextField = new TextField();
			texFel.width = FlxG.width;
			texFel.height = FlxG.height;
			// texFel.
			texFel.htmlText = md;

			FlxG.stage.addChild(texFel);

			// scoreText.textField.htmlText = md;

			trace(md);
		 */

		super.create();
	}

	public function addSong(songName:String, modName:String, songCharacter:String)
	{
		songs.push(new SongMetadata(songName, modName, songCharacter));
	}

	// public function addWeek(songs:Array<String>, weekNum:Int, ?songCharacters:Array<String>)
	// {
	// 	if (songCharacters == null)
	// 		songCharacters = ['bf'];

	// 	var num:Int = 0;
	// 	for (song in songs)
	// 	{
	// 		addSong(song, weekNum, songCharacters[num]);

	// 		if (songCharacters.length != 1)
	// 			num++;
	// 	}
	// }

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (!instPlaying) {
			instCooldown += elapsed;
			if (instCooldown > Settings.engineSettings.data.freeplayCooldown) {
				instPlaying = true;
				FlxG.sound.playMusic(Paths.modInst(songs[curSelected].songName, songs[curSelected].mod), 0);
				FlxG.sound.music.persist = false;
			}
		}
		if (instPlaying) {

			if (FlxG.sound.music.volume < 0.7)
			{
				FlxG.sound.music.volume += 0.5 * FlxG.elapsed;
			}
		}

		lerpScore = Math.floor(FlxMath.lerp(lerpScore, intendedScore, 0.4));

		if (Math.abs(lerpScore - intendedScore) <= 10)
			lerpScore = intendedScore;

		scoreText.text = "PERSONAL BEST:" + lerpScore;

		var upP = controls.UP_P;
		var downP = controls.DOWN_P;
		var accepted = controls.ACCEPT || FlxG.mouse.justReleased;

		if (FlxG.mouse.wheel != 0) changeSelection(-FlxG.mouse.wheel);
		if (upP || (controls.UP && FlxG.keys.pressed.SHIFT))
		{
			changeSelection(-1);
		}
		if (downP || (controls.DOWN && FlxG.keys.pressed.SHIFT))
		{
			changeSelection(1);
		}

		if (controls.LEFT_P)
			changeDiff(-1);
		if (controls.RIGHT_P || FlxG.mouse.justReleasedRight)
			changeDiff(1);

		if (controls.BACK)
		{
			if (Settings.engineSettings.data.memoryOptimization) {
				// for (k=>v in ) {
				// 	trace(k);
				// 	v.dispose();
				// 	Assets.cache.audio.remove(k);
				// }
				openfl.utils.Assets.cache.clear("assets");

			}
			FlxG.switchState(new MainMenuState());
			
		}

		if (accepted)
		{
			var poop:String = Highscore.formatSong(songs[curSelected].songName.toLowerCase(), curDifficulty);

			trace(poop);

			// PlayState.SONG = Song.loadFromJson(poop, songs[curSelected].songName.toLowerCase());
			PlayState.SONG = Song.loadModFromJson(poop, songs[curSelected].mod, songs[curSelected].songName.toLowerCase());
			PlayState.isStoryMode = false;
			PlayState.songMod = songs[curSelected].mod;
			PlayState.storyDifficulty = curDifficulty;

			// PlayState.storyWeek = songs[curSelected].week;
			trace('CUR WEEK' + PlayState.storyWeek);
			LoadingState.loadAndSwitchState(new PlayState());
		}
	}

	function changeDiff(change:Int = 0)
	{
		curDifficulty += change;

		if (curDifficulty < 0)
			curDifficulty = 2;
		if (curDifficulty > 2)
			curDifficulty = 0;

		#if !switch
		intendedScore = Highscore.getScore(songs[curSelected].songName, curDifficulty);
		#end

		switch (curDifficulty)
		{
			case 0:
				diffText.text = "EASY";
			case 1:
				diffText.text = 'NORMAL';
			case 2:
				diffText.text = "HARD";
		}
	}

	function changeSelection(change:Int = 0)
	{

		// // NGio .logEvent('Fresh');
		FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);

		curSelected += change;

		if (curSelected < 0)
			curSelected = songs.length - 1;
		if (curSelected >= songs.length)
			curSelected = 0;

		// selector.y = (70 * curSelected) + 30;

		#if !switch
		intendedScore = Highscore.getScore(songs[curSelected].songName, curDifficulty);
		// lerpScore = 0;
		#end

		
		
		// FlxG.sound.playMusic(Paths.inst(songs[curSelected].songName), 0);
		FlxG.sound.music.stop();
		instPlaying = false;
		instCooldown = 0;

		modSourceText.text = songs[curSelected].mod;
		var bullShit:Int = 0;

		for (i in 0...iconArray.length)
		{
			iconArray[i].alpha = 0.6;
		}

		iconArray[curSelected].alpha = 1;

		for (item in grpSongs.members)
		{
			item.targetY = bullShit - curSelected;
			bullShit++;

			item.alpha = 0.6;
			// item.setGraphicSize(Std.int(item.width * 0.8));

			if (item.targetY == 0)
			{
				item.alpha = 1;
				// item.setGraphicSize(Std.int(item.width));
			}
		}
	}

	public override function destroy() {
		super.destroy();

		
	}
}

class SongMetadata
{
	public var songName:String = "";
	public var mod:String = "";
	public var songCharacter:String = "";

	public function new(song:String, mod:String, songCharacter:String)
	{
		this.songName = song;
		this.mod = mod;
		this.songCharacter = songCharacter;
	}
}
