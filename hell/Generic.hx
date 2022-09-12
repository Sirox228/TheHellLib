package;

import sys.FileSystem;
#if android
import android.Hardware;
import android.Permissions;
import android.os.Environment;
#end
import flash.system.System;
import flixel.FlxG;
import haxe.CallStack.StackItem;
import haxe.CallStack;
import lime.app.Application;
import openfl.Lib;
import openfl.events.UncaughtErrorEvent;
import flixel.FlxState;
import flixel.addons.ui.FlxUIButton;
import flixel.text.FlxText;
import openfl.utils.Assets;
import sys.io.File;
using StringTools;

/**
* @author: Sirox (all code here is stolen /j)
* @version: 1.1
* extension-androidtools by @M.A. Jigsaw
*/
class Generic {
	
	public static var mode:Modes = ROOTDATA;
	private static var path:String = null;
	public static var initState:FlxState = null;
	
	/**
	* returns some paths depending on current 'mode' variable or you can force it to any mode by typing it into ()
	*/
	public static function returnPath(m:Modes = ROOTDATA):String {
		#if android
		if (m == ROOTDATA && mode != ROOTDATA) { // the most stupid checking i made
			m = mode;
		}
		switch (m) {
			case ROOTDATA:
				path = lime.system.System.applicationStorageDirectory;
			case INTERNAL:
			    path = Environment.getExternalStorageDirectory() + '/' + '.' + Application.current.meta.get('file') + '/';
			case ANDROIDDATA:
			    path = Environment.getDataDirectory() + '/';
		}
		if (path != null && path.length > 0) {
			mkDirs(path);
			return path;
		}
		trace('DEATH');
		return null;
		#else
		path = '';
		return path;
		#end
	}
	
	/**
	* this thing cheaks each folder of path 'l' if it exists and if no, it creates them, final element of 'l' path must be a folder, otherwise expect something weird to happen
	*/
	public static function mkDirs(l:String) {
		var p:String = l;
		var o:String = "";
		var q:String = "/";
		if (l.endsWith("/")) {
			p = p.substr(p.length - p.length, p.length - 1); //really idk about that string length starts from 0 or 1
		}
		if (l.startsWith("/")) {
			p = p.substr((p.length + 1) - p.length, p.length - 1); //this is a horrible way to remove "/" a the start of path if it is there...
		}
		if (l.contains("storage/emulated/0/")) {
			q = "/storage/emulated/0/";
			p = p.replace("storage/emulated/0/", "");
		}
		var j:Array<String> = p.split("/");
		for (i in j) {
			trace(q + o + i);
			if (!FileSystem.exists(q + o + i)) {
				FileSystem.createDirectory(q + o + i);
			}
			o += i + "/";
		}
	}
	
	/**
	 * crash handler (it works only with exceptions thrown by haxe, for example glsl death or fatal signals wouldn't be saved using this)
     * @author: sqirra-rng
     * @edit: Saw (M.A. Jigsaw)
	 */
	public static function initCrashHandler()
	{
		Lib.current.loaderInfo.uncaughtErrorEvents.addEventListener(UncaughtErrorEvent.UNCAUGHT_ERROR, function(u:UncaughtErrorEvent)
		{
			var callStack:Array<StackItem> = CallStack.exceptionStack(true);
			var errMsg:String = '';

			for (stackItem in callStack)
			{
				switch (stackItem)
				{
					case CFunction:
						errMsg += 'a C function\n';
					case Module(m):
						errMsg += 'module ' + m + '\n';
					case FilePos(s, file, line, column):
						errMsg += file + ' (line ' + line + ')\n';
					case Method(cname, meth):
						errMsg += cname == null ? "<unknown>" : cname + '.' + meth + '\n';
					case LocalFunction(n):
						errMsg += 'local function ' + n + '\n';
				}
			}

			errMsg += u.error;

			try
			{
				mkDirs(returnPath() + 'logs');
				
				var lmao:String = returnPath();
				if (!lmao.contains(lime.system.System.applicationStorageDirectory)) {
				    File.saveContent(lmao
					+ 'logs/'
					+ Application.current.meta.get('file')
					+ '-'
					+ Date.now().toString().replace(' ', '-').replace(':', "'")
					+ '.log',
					errMsg
					+ '\n');
				}
			}
			#if android
			catch (e:Dynamic)
			Hardware.toast("Error!\nClouldn't save the crash dump because:\n" + e, ToastType.LENGTH_LONG);
			#end

			Sys.println(errMsg);
			Application.current.window.alert(errMsg, 'Error!');

			System.exit(1);
		});
	}
	
	public static function trace(thing:Dynamic, var_name:String, alert:Bool = false) {
		var dateNow:String = Date.now().toString();
		dateNow = dateNow.replace(" ", "_");
		dateNow = dateNow.replace(":", "'");
		var fp:String = returnPath() + "logs/" + var_name + dateNow + ".txt";
		
		mkDirs(returnPath() + "logs/");
		
		var thingToSave:String = forceToString(thing);
		
		if (alert) {
			Application.current.window.alert(thingToSave, 'FileTrace');
		}
		
		/*if (FileSystem.exists(fp)) {
			for (i in 0.0...Math.POSITIVE_INFINITY) {
				fp = fp + i;
				if (FileSystem.exists(fp)) {
					fp = fp.replace(i, '');
				} else {
					break;
				}
			}
		}*/
		mkDirs(returnPath() + 'logs');
		File.saveContent(fp, var_name + " = " + thingToSave + "\n");
	}
	
	public static function forceToString(shit:Dynamic):String {
		var result:String = '';
		if (!Std.isOfType(shit, String)) {
			result = Std.string(shit);
		} else {
			result = shit;
		}
		return result;
	}
	
	public static function match(val1:Dynamic, val2:Dynamic) {
		return Std.isOfType(val1, val2);
	}
	
	public static function copyContent(copyPath:String, savePath:String)
	{
		try
		{
			if (!FileSystem.exists(returnPath() + savePath) && Assets.exists(copyPath))
				File.saveBytes(returnPath() + savePath, Assets.getBytes(copyPath));
		}
		#if android
		catch (e:Dynamic)
		Hardware.toast("Error!\nClouldn't copy the file because:\n" + e, ToastType.LENGTH_LONG);
		#end
	}
}

class PermsState extends FlxState {
	var permsbutton:FlxUIButton;
	var continuebutton:FlxUIButton;
	var text:FlxText;
	override public function create():Void
	{
		text = new FlxText(0,0, FlxG.width, "PERMISSIONS" + "\n" + "this game needs storage permissions to work" + "\n" + "press 'Ask Permissions' to ask them" + "/n" + "press 'continue' to run the game", 32);
		text.setFormat("VCR OSD Mono", 32);
		text.screenCenter(XY);
		text.y += FlxG.height / 4;
		text.alignment = CENTER;
		add(text);
		permsbutton = new FlxUIButton(0,0,"Ask Permissions", () -> {
            Permissions.requestPermissions([Permissions.WRITE_EXTERNAL_STORAGE, Permissions.READ_EXTERNAL_STORAGE]);
        });
        permsbutton.screenCenter(XY);
        permsbutton.x -= FlxG.width / 4;
        permsbutton.y -= FlxG.height / 4;
        permsbutton.resize(250,50);
        continuebutton = new FlxUIButton(0,0,"continue", () -> {
        	FlxG.switchState(new TitleState());
        });
        continuebutton.screenCenter(XY);
        continuebutton.x += FlxG.width / 4;
        continuebutton.y -= FlxG.height / 4;
		continuebutton.resize(250,50);
		
		super.create();
	}
	
	override function update(elapsed:Float)
	{
		super.update(elapsed);
	}
}

enum Modes {
	ROOTDATA;
	ANDROIDDATA;
	INTERNAL;
}