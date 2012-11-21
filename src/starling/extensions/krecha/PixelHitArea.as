package starling.extensions.krecha 
{
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.geom.Matrix;
	import flash.sampler.getSize;
	import flash.utils.Dictionary;
	import flash.utils.getTimer;
	import starling.utils.Color;

	/**	 
	 * Create and manage pixel hit areas.
	 * @author KrechaGames - Łukasz 'Cywil' Cywiński
	 */
	public class PixelHitArea	
	{	
		private static var hitAreas:Dictionary;
		private static var id:int = 0;	

		public var width:Number;
		public var height:Number;
		public var name:String;	
		public var scaleBitmapData:Number;
		private var sampleWidth:uint;
		private var sampleHeight:uint;
		private var alphaData:Vector.<uint>;
		private var tempData:Vector.<uint>;	
		private var createTime:int;

		private var _disposed:Boolean;

		public function PixelHitArea ( bitmap:Bitmap, bitmapSampling:Number = 1, name:String = '' ):void
		{			
			var time:int = getTimer ();
			if ( name == '' ) {
				name = '_hit#' + id;
				id ++;
			}
			PixelHitArea.registerHitArea ( this, name );

			this.width = bitmap.width;
			this.height = bitmap.height;
			this.scaleBitmapData = bitmapSampling;	

			if ( bitmapSampling > 1 || bitmapSampling < .1 ) throw new Error ('Incorrect bitmap sampling, correct range is 0.1 - 1')

			var tempBitmapData:BitmapData = new BitmapData ( Math.ceil ( bitmap.width * bitmapSampling) , Math.ceil ( bitmap.height * bitmapSampling ), true, 0x00000000 );			
			bitmapSampling < 1 ? tempBitmapData.draw ( bitmap.bitmapData, new Matrix ( bitmapSampling, 0, 0, bitmapSampling, 0, 0) ) : tempBitmapData = bitmap.bitmapData.clone ();

			this.sampleWidth = tempBitmapData.width;
			this.sampleHeight = tempBitmapData.height;

			tempData = tempBitmapData.getVector ( tempBitmapData.rect );			
			alphaData = new Vector.<uint> (  Math.ceil((sampleWidth * sampleHeight) / 4 ), true );

			var j:uint = 0;
			for ( var i:uint = 0; i < alphaData.length; i ++ ) {				
				alphaData[i] = ( getAlpha ( j ) << 24 ) | ( getAlpha (j + 1) << 16 ) | ( getAlpha ( j + 2 ) << 8 ) |  ( getAlpha (  j + 3 ) );
				j += 4;				
			}			
			tempData = null;
			tempBitmapData.dispose ();
			tempBitmapData = null;			

			createTime = getTimer () - time;		
		}

		private function getAlpha ( index:uint ):uint
		{			
			return index < tempData.length ? Color.getAlpha ( tempData[index] ) : 0;
		}


		public function getAlphaPixel ( x:uint, y:uint ):uint
		{			
			var cell:Number = ( ( Math.floor ( y*scaleBitmapData) * sampleWidth) +  Math.floor (x*scaleBitmapData) ) / 4;
			var rest:Number = cell % Math.floor ( cell );

			var alphaGroup:uint = alphaData [ Math.floor(cell) ];

			if ( rest == 0 ) 	return Color.getAlpha ( alphaGroup );			
			if ( rest == .25 )	return Color.getRed ( alphaGroup );			
			if ( rest == .5 ) 	return Color.getGreen ( alphaGroup );			
			if ( rest == .75 ) 	return Color.getBlue ( alphaGroup );
			return 0;
		}		

		public function dispose():void 
		{
			alphaData = null;
			disposed = true;
		}		

		public function getMemorySize():Number 
		{
			return alphaData ? getSize (alphaData) : 0;
		}

		public function getCreatTime ():Number 
		{
			return createTime;
		}

		public function get disposed():Boolean 
		{
			return _disposed;
		}

		public function set disposed(value:Boolean):void 
		{
			_disposed = value;
		}		

		//-----------------------------------------
		//static functions
		//-----------------------------------------
		static private function registerHitArea ( hitArea:PixelHitArea, name:String ):void 
		{
			if ( hitAreas == null ) hitAreas = new Dictionary ();	
			if ( hitAreas[name] != null ) throw ( new Error('PixelTouch: hitArea name duplicate'));
			hitAreas[name] = hitArea;
		}

		static public function disposeHitArea ( hitArea:PixelHitArea ):void
		{
			for (var area:Object in hitAreas )			
			{				
				if ( hitAreas[area] == hitArea ) {				
					hitArea.dispose ();				
					hitAreas[area] = null;
				}				
			}
		}

		static public function dispose ():void
		{
			for (var area:Object in hitAreas )			
			{			
				var hitArea:PixelHitArea = hitAreas[area];
				if ( hitArea ) {
					hitArea.dispose ();				
					hitAreas[area] = null;
				}				
			}
			hitAreas = null;
			id = 0;
		}

		static public function getHitArea( name:String ):PixelHitArea 
		{			
			if ( hitAreas[name] ) return hitAreas [name];
			throw new Error ('HitArea ' + name + ' not found');
			return null;		
		}

		/* Get info about size of hit area and time need to create it - use it in debug mode, in normal mode size = 0*/
		static public function getDebugInfo ():String 
		{			
			var res:String = 'HitArea memory size:\r';
			var totalMem:Number = 0;
			var totalTime:Number = 0;
			for (var area:Object in hitAreas )			
			{					
				var hitArea:PixelHitArea = hitAreas[area];
				if ( hitArea ){		
					var memory:Number = ( hitArea.getMemorySize () / 1024 / 1024 );
					totalMem += memory;
					totalTime += hitArea.getCreatTime ();
					res += area + ':\t' + memory.toFixed(2) + ' mb \t';
					res += 'create time:\t' + hitArea.createTime + ' ms\r';
				}				
			}
			res += '-----------------------\r'
			res += 'total:\t\t' + totalMem.toFixed(2) +' mb \t\t\t' + totalTime +' ms';
			return res;
		}
		//-----------------------------------------
		//end static functions
		//-----------------------------------------
	}
}