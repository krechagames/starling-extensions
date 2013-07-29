package starling.extensions.krecha
{
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import starling.display.DisplayObject;
	import starling.display.Image;
	import starling.textures.SubTexture;
	import starling.textures.Texture;
  
	/**
	 * Create Image object with pixel perfect touch.
	 * @author KrechaGames - Łukasz 'Cywil' Cywiński
	 */
	public class PixelImageTouch extends Image
	{
		private var _hitArea:PixelHitArea;
		private var _threshold:uint;
		private var frame:Rectangle;

		public function PixelImageTouch ( texture:Texture, hitArea:PixelHitArea=null, threshold:uint = 0xFF )
		{
			super ( texture );				
			this.hitArea = hitArea;				
			this.threshold = threshold;			
			this.frame = new Rectangle ( -texture.frame.x, -texture.frame.y, texture.width, texture.height );	
		}

		override public function hitTest(localPoint:Point, forTouch:Boolean = false):DisplayObject 
		{						
			if ( hitArea && !hitArea.disposed )
            {				
				if ( frame.containsPoint (localPoint )){
					var clippingX:Number = texture is SubTexture ? SubTexture (texture).clipping.x : 0;
					var clippingY:Number = texture is SubTexture ? SubTexture (texture).clipping.y : 0;				
					return _hitArea.getAlphaPixel ( localPoint.x + texture.frame.x + hitArea.width * clippingX, localPoint.y + texture.frame.y + hitArea.height * clippingY ) >= _threshold ? this : null;				
				}else {
					return null;
				}
            } else {				
				return super.hitTest ( localPoint, forTouch );
			} 			
		}	

		override public function dispose():void 
		{
			if ( hitArea && hitArea.disposed ) hitArea = null;
			super.dispose();
		}

		public function get hitArea():PixelHitArea 
		{
			return _hitArea;
		}

		public function set hitArea(value:PixelHitArea):void 
		{
			_hitArea = value;
		}
		
		public function get threshold():uint 
		{
			return _threshold;
		}
		
		public function set threshold(value:uint):void 
		{
			_threshold = value;
		}
	}
 
}
