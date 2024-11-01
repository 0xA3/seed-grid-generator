package uheprng;

import Math.ffloor;
import Std.int;
// "use strict";
/*	============================================================================
									Gibson Research Corporation
				UHEPRNG - Ultra High Entropy Pseudo-Random Number Generator
	============================================================================
	LICENSE AND COPYRIGHT:  THIS CODE IS HEREBY RELEASED INTO THE PUBLIC DOMAIN
	Gibson Research Corporation releases and disclaims ALL RIGHTS AND TITLE IN
	THIS CODE OR ANY DERIVATIVES. Anyone may be freely use it for any purpose.
	============================================================================
	This is GRC's cryptographically strong PRNG (pseudo-random number generator)
	for Haxe. It is driven by 1536 bits of entropy, stored in an array of
	48, 32-bit Haxe variables.  Since many applications of this generator,
	including ours with the "Off The Grid" Latin Square generator, may require
	the deterministic re-generation of a sequence of PRNs, this PRNG's initial
	entropic state can be read and written as a static whole, and incrementally
	evolved by pouring new source entropy into the generator's internal state.
	----------------------------------------------------------------------------
	ENDLESS THANKS are due Johannes Baagoe for his careful development of highly
	robust JavaScript implementations of JS PRNGs.  This work was based upon his
	JavaScript "Alea" PRNG which is based upon the extremely robust Multiply-
	With-Carry (MWC) PRNG invented by George Marsaglia. MWC Algorithm References:
	http://www.GRC.com/otg/Marsaglia_PRNGs.pdf
	http://www.GRC.com/otg/Marsaglia_MWC_Generators.pdf
	----------------------------------------------------------------------------
	The quality of this algorithm's pseudo-random numbers have been verified by
	multiple independent researchers. It handily passes the fermilab.ch tests as
	well as the "diehard" and "dieharder" test suites.  For individuals wishing
	to further verify the quality of this algorithm's pseudo-random numbers, a
	256-megabyte file of this algorithm's output may be downloaded from GRC.com,
	and a Microsoft Windows scripting host (WSH) version of this algorithm may be
	downloaded and run from the Windows command prompt to generate unique files
	of any size:
	The Fermilab "ENT" tests: http://fourmilab.ch/random/
	The 256-megabyte sample PRN file at GRC: https://www.GRC.com/otg/uheprng.bin
	The Windows scripting host version: https://www.GRC.com/otg/wsh-uheprng.js
	----------------------------------------------------------------------------
	Qualifying MWC multipliers are: 187884, 686118, 898134, 1104375, 1250205,
	1460910 and 1768863. (We use the largest one that's < 2^21)
	============================================================================ */

class UHEPRNG {

	public static function create() {

		final o = 48; // set the 'order' number of ENTROPY-holding 32-bit values
		final s:Array<Float> = [o];
		// when our "uheprng" is initially invoked our PRNG state is initialized from the
		// browser's own local PRNG. This is okay since although its generator might not
		// be wonderful, it's useful for establishing large startup entropy for our usage.
		var mash = Mash();		// get a pointer to our high-performance "Mash" hash

		for (i in 0...o) s[i] = mash( Math.random() );	// fill the array with initial mash hash values

		// when our main outer "uheprng" function is called, after setting up our
		// initial variables and entropic state, we return an "instance pointer"
		// to the internal anonymous function which can then be used to access
		// the uheprng's various public functions.  As with the ".done" function
		// above, we should set the returned value to 'null' once we're finished
		// using any of these functions.
		return new UHEPRNG( o, s, mash );
	}

	var mash:(?v:Null<Dynamic>)->Float;

	final o:Int;
	var c:Float = 1;			// init the 'carry' used by the multiply-with-carry (MWC) algorithm
	var p :Int;					// init the 'phase' (max-1) of the intermediate variable pointer
	var s:Array<Float>;			// declare our intermediate variables array
	var i:Float = 0;			// general purpose locals
	var j:Float = 0;
	var k:Float = 0;

	function new( o:Int, s:Array<Float>, mash:(?v:Null<Dynamic>)->Float ) {
		this.o = o;
		this.s = s;
		p = o;
		this.mash = mash;
		s = [o];
	}

	// this private (internal access only) function is the heart of the multiply-with-carry
	// (MWC) PRNG algorithm. When called it returns a pseudo-random number in the form of a
	// 32-bit fraction (0.0 to <1.0) it is a private function used by the default
	// [0-1] return function, and by the random 'string(n)' function which returns 'n'
	// characters from 33 to 126.
	function rawprng() {
		if (++p >= o) p = 0;
		var t = 1768863 * s[p] + c * 2.3283064365386963e-10; // 2^-32
		c = ffloor( t );
		final dif = t - c;
		return s[p] = dif;
	}
	
	// this public function is the default function returned by this library.
	// The values returned are integers in the range from 0 to range-1. We first
	// obtain two 32-bit fractions (from rawprng) to synthesize a single high
	// resolution 53-bit prng (0 to <1), then we multiply this by the caller's
	// "range" param and take the "floor" to return a equally probable integer.
	public function  random( range:Float ) {
		return Math.ffloor(range * (rawprng() + (rawprng() * 0x200000) * 1.1102230246251565e-16)); // 2^-53
	}

	// this public function 'string(n)' returns a pseudo-random string of
	// 'n' printable characters ranging from chr(33) to chr(126) inclusive.
	public function string( count:Int ) {
		var s = "";
		for (i in 0...count) s += String.fromCharCode(33 + int( random(94)));
		return s;
	}

	// this private "hash" function is used to evolve the generator's internal
	// entropy state. It is also called by the public addEntropy() function
	// which is used to pour entropy into the PRNG.
	function hash( ?arguments:Array<Dynamic> ) {
		var args:Array<Dynamic> = [];
		if( arguments != null ) for (i in 0...arguments.length) {
			args.push(arguments[i]);
		}
		for (i in 0...args.length) {
			for (j in 0...o) {
				s[j] -= mash(args[i]);
				if (s[j] < 0) s[j] += 1;
			}
		}
	}

	// this public "clean string" function removes leading and trailing spaces and non-printing
	// control characters, including any embedded carriage-return (CR) and line-feed (LF) characters,
	// from any string it is handed. this is also used by the 'hashstring' function (below) to help
	// users always obtain the same EFFECTIVE uheprng seeding key.
	public function cleanString ( inStr:String ) {
		inStr = ~/(^\s*)|(\s*$)/gi.replace(inStr,""); // remove any/all leading spaces
		inStr = ~/[\x00-\x1F]/gi.replace(inStr,"");	// remove any/all control characters
		inStr = ~/\n /.replace(inStr,"\n");				// remove any/all trailing spaces
		return inStr;											// return the cleaned up result
	}
	
	// this public "hash string" function hashes the provided character string after first removing
	// any leading or trailing spaces and ignoring any embedded carriage returns (CR) or Line Feeds (LF)
	public function hashString ( inStr:String ) {
		inStr = cleanString(inStr);
		mash(inStr);											// use the string to evolve the 'mash' state
		for (i in 0...inStr.length) {			// scan through the characters in our string
			k = inStr.charCodeAt(i);						// get the character code at the location
			for (j in 0...o) {						//	"mash" it into the UHEPRNG state
				s[j] -= mash(k);
				if (s[j] < 0) s[j] += 1;
			}
		}
	}
			
	// this handy public function is used to add entropy to our uheprng at any time
	public function addEntropy( ?arguments:Array<Dynamic> ) {
		var args:Array<Dynamic> = [];
		if( arguments != null ) for (i in 0...arguments.length) args.push(arguments[i]);
		hash( ((k++) + (Date.now().getTime()) + args.join('') + Math.random()).split( "" ) );
	}
		
	// if we want to provide a deterministic startup context for our PRNG,
	// but without directly setting the internal state variables, this allows
	// us to initialize the mash hash and PRNG's internal state before providing
	// some hashing input
	public function initState() {
		mash();													// pass a null arg to force mash hash to init
		for (i in 0...o) s[i] = mash(' ');						// fill the array with initial mash hash values
		c = 1;													// init our multiply-with-carry carry
		p = o;													// init our phase
	}
		
	// we use this (optional) public function to signal the program
	// that we're finished using the "Mash" hash function so that it can free up the
	// local "instance variables" it will have been maintaining.  It's not strictly
	// necessary, of course, but it's good programming citizenship.
	public function done() {
		mash = null;
	}

/*	============================================================================
	This is based upon Johannes Baagoe's carefully designed and efficient hash
	function for use with Haxe.  It has a proven "avalanche" effect such
	that every bit of the input affects every bit of the output 50% of the time,
	which is good.	See: http://baagoe.com/en/RandomMusings/hash/avalanche.xhtml
	============================================================================*/
	static function Mash() {
		var n:Float = 4022871197; // 0xefc8249d;
		
		var mash = function( ?input:Null<Dynamic> ):Float {
			if (input != null) {
				var data = Std.string(input);
				for (i in 0...data.length) {
					n += data.charCodeAt(i);
					var h = 0.02519603282416938 * n;
					n = ffloor( h );
					h -= n;
					h *= n;
					n = ffloor( h );
					h -= n;
					n += h * 4294967296; //0x100000000; // 2^32
				}
				return ffloor( n ) * 2.3283064365386963e-10; // 2^-32
			}
			return n = 4022871197;
		}
		return mash;
	}
}

	