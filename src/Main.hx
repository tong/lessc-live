
import sys.FileSystem;
import sys.io.Inotify;

using StringTools;
using haxe.io.Path;

class Main {

	static inline var COLOR_ERROR = 31;
	static inline var COLOR_SUCCESS = 32;

	static var lessFile : String;
	static var cssFile : String;
	static var lessOptions : Array<String>;

	static function main() {

		if( Sys.systemName() != 'Linux' ) exit( 1, 'Linux only' );

		lessOptions = [];
		var sourcePaths = new Array<String>();
		var usage : String = null;
		var argHandler = hxargs.Args.generate([
			@doc("less index file")["-main","-m"] => (file:String) -> lessFile = file, //FileSystem.fullPath(file),
			@doc("css file to write")["-css","-c"] => (path:String) -> cssFile = path,
			@doc("paths to watch for changes (seperated by :)")["--src"] => (path:String) -> {
				sourcePaths = path.split(":").map( p -> FileSystem.fullPath(p) );
			},
			@doc("lessc options (seperated by :)")["--options"] => (?options:String) -> {
				if( options != null ) lessOptions = options.split(':');
			},
			["--help","-help","-h"] => () -> exit( 0, usage ),
			_ => (arg:String) -> exit( 1, 'Unknown argument [$arg]' )
		]);
		usage = argHandler.getDoc();
		var args = Sys.args();
		if( args.length == 0 ) exit( 1, usage );
		argHandler.parse( args );

		if( lessFile == null ) {
			if( FileSystem.exists( 'index.less' ) ) lessFile = 'index.less';
			else if( FileSystem.exists( 'main.less' ) ) lessFile = 'main.less';
			else exit( 1, 'missing -main param' );
			lessFile = FileSystem.fullPath(lessFile);
		} else {
			lessFile = FileSystem.fullPath(lessFile);
			if( !FileSystem.exists( lessFile ) )
				exit( 1, 'Main less file not found: $lessFile' );
		}

		if( sourcePaths.length > 0 ) lessOptions.push( '--include-path='+sourcePaths.join(':') );

		if( cssFile == null ) {
			cssFile = lessFile.withoutExtension() + '.css';
		}

		build();

		// ---

		if( sourcePaths.length == 0 ) {
			sourcePaths.push( lessFile.directory() );
		}

		// TODO Get list of dependencies
		//lessc style/index.less assets/style.css -M

		var inotify = new Inotify();
		var watches = new Array<Int>();
		var mask = MODIFY | CLOSE_WRITE;

		/*
		var mask =
			ACCESS
			| MODIFY
			//| ATTRIB
			| CLOSE_WRITE
			//| CLOSE_NOWRITE
			| OPEN;
			//| MOVED_FROM
			//| MOVED_TO
			//| CREATE
			//| DELETE
			//| DELETE_SELF
			//| MOVE_SELF
			//| CLOSE
			//| MOVE;
			*/

		function watchDirectory( dir : String ) {
			watches.push( inotify.addWatch( dir, mask ) );
			for( e in FileSystem.readDirectory( dir ) ) {
				var p = '$dir/$e';
				if( FileSystem.isDirectory( p ) ) {
					watchDirectory( p );
				}
			}
		}
		for( path in sourcePaths ) {
			println( 'Watching $path' );
			watchDirectory(path);
		}

		var fileModified : String = null;
		while( true ) {
			var events = inotify.read();
			for( e in events ) {
                if( e.name != null && e.name.extension() == 'less' ) {
					if( e.mask & MODIFY > 0 ) {
						fileModified = e.name;
                    } else if( e.mask & CLOSE_WRITE > 0 ) {
                        if( fileModified != null ) {
							Sys.print( DateTools.format( Date.now(), '%H:%M:%S $fileModified / ' ) );
							build();
                            fileModified = null;
                        }
                    }
                }
			}
        }
        for( wd in watches ) inotify.removeWatch( wd );
		inotify.close();
	}

	static function build() : Bool {
		var ts = Sys.time();
		Sys.print( lessFile.withoutDirectory()+' → $cssFile ' );
		var result = lessc( lessFile, cssFile, lessOptions );
		if( result.code == 0 ) {
			var time = Std.int( (Sys.time() - ts) * 1000) / 1000;
			printSuccess( '✔ ${time}s' );
			return true;
		} else {
			printError( '✖\n'+result.data );
			return false;
		}
	}

	static function resolveDependencies() : Array<String> {
		var list = new Array<String>();
		var result = lessc( lessFile, cssFile, lessOptions.concat(['-M']) );
		if( result.code == 0 ) {
			for( f in result.data.split(' ') ) {
				f = f.trim();
				if( f.length > 0 ) {
					list.push( f );
				}
			}
			return list;
		} else {
			throw result.data;
			return null;
		}
	}

	static function lessc( lessMain : String, cssOut : String, ?lessOptions : Array<String> ) : { code : Int, data : String } {
		var args = [lessMain,cssOut];
		if( lessOptions != null ) args = args.concat( lessOptions );
		var proc = new sys.io.Process( 'lessc', args );
		var code = proc.exitCode( true );
		var result = switch code {
			case 0: proc.stdout.readAll().toString();
			default: proc.stderr.readAll().toString();
		}
		proc.close();
		return { code: code, data : result };
	}

	static inline function printSuccess( str : String ) {
		println( str, COLOR_SUCCESS );
	}

	static inline function printError( str : String ) {
		println( str, COLOR_ERROR );
	}

	static function println( str : String, ?color : Int ) {
		if( color != null ) str = '\x1B['+'\033[$color'+'m'+str+'\033[0m';
		Sys.println( str );
	}

	static function exit( code = 0, ?info : String ) {
		if( info != null ) println( info );
		Sys.exit( code );
	}
}
