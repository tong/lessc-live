
import Sys.print;
import Sys.println;
import sys.FileSystem;
import sys.io.Inotify;

using StringTools;
using haxe.io.Path;

class Main {

	static function main() {

		if( Sys.systemName() != 'Linux' ) exit( 1, 'Linux only' );

		var mainLessFile : String = null;
		var cssFile : String = null;
		var sourcePaths = new Array<String>();
		var lessOptions = new Array<String>();
		var usage : String = null;
		var argHandler = hxargs.Args.generate([
			@doc("less index file")["-main","-m"] => (file:String) -> mainLessFile = file, //FileSystem.fullPath(file),
			@doc("css file to write")["-css","-out"] => (path:String) -> cssFile = path,
			@doc("paths to watch for changes")["-src"] => (path:String) -> {
				sourcePaths = path.split(":").map( p -> FileSystem.fullPath(p) );
			},
			@doc("lessc options")["--options"] => (?options:String) -> {
				if( options != null ) lessOptions = options.split(':');
			},
			["--help","-h"] => () -> exit( 0, usage ),
			_ => (arg:String) -> exit( 1, 'Unknown argument [$arg]' )
		]);
		usage = argHandler.getDoc();
		var args = Sys.args();
		if( args.length == 0 ) exit( 1, usage );
		argHandler.parse( args );

		if( mainLessFile == null ) {
			if( FileSystem.exists( 'index.less' ) ) mainLessFile = 'index.less';
			else if( FileSystem.exists( 'main.less' ) ) mainLessFile = 'main.less';
			else exit( 1, 'missing -main param' );
			mainLessFile = FileSystem.fullPath(mainLessFile);
		} else {
			if( !FileSystem.exists( mainLessFile ) )
				exit( 1, 'Main less file not found: $mainLessFile' );
			mainLessFile = FileSystem.fullPath(mainLessFile);
		}

		if( cssFile == null ) {
			cssFile = mainLessFile.withoutExtension() + '.css';
		}

		lessc( mainLessFile, cssFile, lessOptions );

		var inotify = new Inotify();
		var watches = new Array<Int>();
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
		for( path in sourcePaths ) {
			println( 'Watching: '+path );
			watches.push( inotify.addWatch( path, mask ) );
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
                            lessc( mainLessFile, cssFile, lessOptions );
                            fileModified = null;
                        }
                    }
                }
			}
        }
        for( wd in watches ) inotify.removeWatch( wd );
		inotify.close();
	}

	static function lessc( lessMain : String, cssOut : String, ?lessOptions : Array<String> ) : Bool {
		var args = [lessMain,cssOut];
		if( lessOptions != null ) args = args.concat( lessOptions );
		print( DateTools.format( Date.now(), '%H:%M:%S ' ) );
		var timestamp = Sys.time();
		var proc = new sys.io.Process( 'lessc', args );
		var code = proc.exitCode( true );
		switch code {
		case 0:
			var time = Std.int( (Sys.time() - timestamp) * 1000) / 1000;
			println( '✔ ${time}sec $cssOut' );
		default:
			println( proc.stderr.readAll().toString() );
		}
		proc.close();
		return code == 0;
	}

	static function exit( code = 0, ?info : String ) {
		if( info != null ) println( info );
		Sys.exit( code );
	}
}
