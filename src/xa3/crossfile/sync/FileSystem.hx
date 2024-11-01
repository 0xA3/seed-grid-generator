package xa3.crossfile.sync;

class FileSystem {
	
	public static function createDirectory( path:String ) {
		#if sys
			sys.FileSystem.createDirectory( path );
		#elseif nodejs
			js.node.Fs.mkdirSync( path );
		#else
			throw "Error: Platform not supported.";
		#end
	}
	
	public static function isDirectory( path:String ) {
		#if sys
			return sys.FileSystem.isDirectory( path );
		#elseif nodejs
			return js.node.Fs.existsSync( path ) && js.node.Fs.lstatSync( path ).isDirectory();
		#else
			throw "Error: Platform not supported.";
		#end
	}
	
	public static function exists( path:String ) {
		#if sys
			return sys.FileSystem.exists( path );
		#elseif nodejs
			return js.node.Fs.existsSync( path );
		#else
			throw "Error: Platform not supported.";
		#end
	}
	
	public static function readDirectory( path:String ) {
		#if sys
			return sys.FileSystem.readDirectory( path );
		#elseif nodejs
			return js.node.Fs.readdirSync( path );
		#else
			throw "Error: Platform not supported.";
		#end
	}
	
	public static function stat( path:String ) {
		#if sys
			return sys.FileSystem.stat( path );
		#elseif nodejs
			return js.node.Fs.readdirSync( path );
		#else
			throw "Error: Platform not supported.";
		#end
	}
}