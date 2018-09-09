
import om.less.Lessc;
import om.term.Symbol;
import sys.FileSystem;
import sys.io.Process;
import sys.io.File;
import Sys.print;
import Sys.println;

using StringTools;
using om.Path;

class Main {

	static var verbose = false;

	static function exit( code = 0, ?info : String ) {
		if( info != null ) println( info );
		Sys.exit( code );
	}

	static function watch( files : Array<String> ) : String {
		var args = ['-e','close_write','--format','%w'].concat( files );
		var inotifywait = new Process( 'inotifywait', args );
		return switch inotifywait.exitCode() {
		case 0: inotifywait.stdout.readAll().toString().trim();
		default: inotifywait.stderr.readAll().toString().trim();
		}
	}

	static function findFiles( path : String ) : Array<String> {
		var found = new Array<String>();
		function search( dir : String ) {
			for( f in FileSystem.readDirectory( dir ) ) {
				var p = '$dir/$f';
				if( FileSystem.isDirectory( p ) ) search( p ) else {
					if( f.extension() == 'less' ) found.push( FileSystem.absolutePath( p ) );
				}
			}
		}
		search( path );
		return found;
	}

	static function compile( lessMain, cssOut, lessParams, lessOptions ) {
		var args = [lessMain,cssOut].concat( Lessc.getArgs( lessParams, lessOptions ) );
		print( '[lessc '+args.join(' ')+']' );
		var r = Lessc.execute( args );
		switch r.code {
		case 0:
			println( ' '+Symbol.tick+' '+r.out.trim() );
		default:
			println( ' '+Symbol.cross );
			println( r.err.trim() );
		}
	}

	static function getTimeString( ?date : Date ) : String {
		return DateTools.format( (date == null) ? Date.now() : date, "%H:%M:%S" );
	}

	static function main() {

		var cwd = Sys.getCwd();
		var lessMain : String;
		var cssOut : String;
		var lessDir : String;
		var lessOptions = new Array<String>();

		var usage : String = null;
		var argHandler = null;

		argHandler = hxargs.Args.generate([
			@doc("less index file")
			["-main"] => function(file:String) {
				lessMain = file;
			},
			@doc("CSS file to write")
			["-css"] => function(file:String) {
				cssOut = file;
			},
			@doc("Source directory to watch for changes")
			["-src"] => function(path:String) {
				lessDir = path;
			},
			@doc("lessc options")
			["--options"] => function(?options:String) {
				if( options != null ) {
					lessOptions = options.split(':');
				}
			},
			["--no-color"] => function() {
				//TODO
			},
			["-v"] => function() {
				verbose = true;
			},
			["--list-source-files"] => function() {
				//TODO
			},
			["--help"] => function() {
				exit( 0, usage );
			},
			_ => function(arg:String) {
				exit( 1, 'Unknown argument [$arg]' );
			}
		]);

		usage = argHandler.getDoc();

		var args = Sys.args();
		if( args.length == 0 ) exit( 1, usage );
		argHandler.parse( args );

		var files = [lessMain];
		if( lessDir != null ) {
			var found = findFiles( lessDir );
			files = files.concat( found );
		}

		var lessParams = {
			inlclude_paths: [lessDir]
		};

		print( getTimeString()+' ' );
		compile( lessMain, cssOut, lessParams, lessOptions );

		while( true ) {

			var mod : String = null;
			try { mod = watch( files ); } catch(e:Dynamic) {
				exit( 1, e );
			}

			print( getTimeString() );
			print( ' [$mod] ' );
			compile( lessMain, cssOut, lessParams, lessOptions );

			//Sys.sleep(0.1);
		}
	}

}
