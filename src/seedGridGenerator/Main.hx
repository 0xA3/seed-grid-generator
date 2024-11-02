package seedGridGenerator;

import CompileTime.readFile;
import Std.int;
import uheprng.UHEPRNG;

using StringTools;

class Main {
	
	static final BASE_NAME = "grid";
	static final GRIDS = 10;
	static final PAGES = 10;
	static final LINES_PER_PAGE = 57;
	static final NUMBERS_PER_LINE = 18;
	
	static final seedWords = readFile( "bip-0039/english.txt" ).split( "\n" ).map( s -> s.trim() ).filter( s -> s.length > 0 );

	static function main() {
		final range = seedWords.length;
		Sys.println( 'Seed word range: $range' );
		
		final contents = [for( i in 0...GRIDS ) {

			final prng = UHEPRNG.create();
			final lines = PAGES * LINES_PER_PAGE;

			Sys.println( 'Creating Grid $i with $lines lines and $NUMBERS_PER_LINE numbers per line' );
			
			final grid = [for( _ in 0...lines )
				[for( _ in 0...NUMBERS_PER_LINE ) {
					final random = int( prng.random( range ));
					final word = seedWords[random];
					final firstChars = word.substr( 0, 4 );
					
					firstChars;
				}].join( " " )
			].join( "\n" );

			grid;
		}];

		for( i in 0...contents.length ) {
			final prng = UHEPRNG.create();
			final direction = prng.random( 100 ) < 49 ? "h" : "v";
			final index = '$i'.lpad( "0", 3 );
			final random1 = '${prng.random( 100 )}'.lpad( "0", 3 );
			final random2 = '${prng.random( 100 )}'.lpad( "0", 3 );
			final path = '${BASE_NAME}_${index}_${direction}_${random1}_${random2}.txt';
			xa3.crossfile.sync.File.saveContent( path, contents[i] );
			Sys.println( 'Writing $path' );
		}

	}
}
