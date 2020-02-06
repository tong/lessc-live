
import om.less.Lessc;
import om.Term;
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

	static function watch( files : Array<String> ) {
		var args = ['-e','close_write','--format','%w'].concat( files );
		var p = new Process( 'inotifywait', args );
		var e = p.stderr.readAll().toString();
		if( p.exitCode() != 0 )
			throw e;
		var r = p.stdout.readAll().toString().trim();
		p.close();
		return r;
	}

	static function findFiles( path : String ) : Array<String> {
		var found = new Array<String>();
		function search( dir : String ) {
			for( f in FileSystem.readDirectory( dir ) ) {
				var p = '$dir/$f';
				if( FileSystem.isDirectory( p ) ) search( p );
				else if( f.extension() == 'less' ) found.push( FileSystem.absolutePath( p ) );
			}
		}
		search( path );
		return found;
	}

	static function lessc( lessMain, cssOut, lessParams, lessOptions ) {
		//Term.clear();
		var args = [lessMain,cssOut].concat( Lessc.getArgs( lessParams, lessOptions ) );
		//print( getTimeString()+' [lessc '+args.join(' ')+']' );
		print( 'lessc '+args.join(' ') );
		var r = Lessc.execute( args );
		/*
		if( r.code != 0 )
			return throw r.err;
		trace(r);
		return r.out;
		*/

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
		var lessDirs : Array<String>;
		var lessOptions = new Array<String>();

		var usage : String = null;
		var argHandler = null;

		argHandler = hxargs.Args.generate([
			@doc("less index file")
			["-main"] => function(file:String) {
				lessMain = file;
			},
			@doc("CSS file to write")
			["-css"] => function(path:String) {
				cssOut = path;
			},
			@doc("Source directory to watch for changes")
			["-src"] => function(path:String) {
				lessDirs = path.split(":");
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


		if( !cssOut.hasExtension() ) {
			cssOut = cssOut.removeTrailingSlashes()+'/'+lessMain.withoutDirectory().withoutExtension()+'.css';
		}

		var files = [lessMain];

		var lessParams : om.less.Lessc.Params = {
			include_paths: []
		};

		if( lessDirs != null ) {
			for( dir in lessDirs ) {
				if( !FileSystem.exists( dir ) ) {
					exit( 1, dir+' not found' );
				}
				var found = findFiles( dir );
				files = files.concat( found );
				lessParams.include_paths.push( dir );
			}
			/*
			var found = findFiles( lessDir );
			files = files.concat( found );
			lessParams.inlclude_paths.push( lessDir );
			*/
		}

		println( 'Watching '+files.length+' files' );

		//print( getTimeString()+' ' );
		lessc( lessMain, cssOut, lessParams, lessOptions );

		while( true ) {

			var mod : String = null;
			try { mod = watch( files ); } catch(e:Dynamic) {
				exit( 1, e );
			}

			println( mod );
			lessc( lessMain, cssOut, lessParams, lessOptions );

			/*
			print( getTimeString() + ' [$mod] ' );

			var result : String = null;
			try {
				result = compile( lessMain, cssOut, lessParams, lessOptions );
			} catch(e:Dynamic) {
				println(e);
			}

			if( result != null ) {
				println( result );
			}
			*/

			Sys.sleep( 0.2 );
		}
	}

}
