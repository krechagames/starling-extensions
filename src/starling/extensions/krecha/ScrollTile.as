package starling.extensions.krecha 
{
	import flash.geom.Rectangle;

	import starling.textures.ConcreteTexture;
	import starling.textures.SubTexture;
	import starling.textures.Texture;

	/**
	 * Tile layer used in ScrollImage
	 * @author KrechaGames - Łukasz 'Cywil' Cywiński
	 */
	public class ScrollTile 
	{
		//members
		private var mSubTexture:SubTexture;	
		private var mBaseClipping:Rectangle;
		private var mBaseTexture:Texture;
		
		//properties
		private var mColor:uint;
		private var mAlpha:Number;
		private var mColorTrans:Vector.<Number>;
		private var mParalax:Number = 1;
		
		//transform
		private var mOffsetX:Number = 0;
		private var mOffsetY:Number = 0;		
		private var mRotation:Number = 0;			
		private var mScaleX:Number = 1;			
		private var mScaleY:Number = 1;

		/**
		 * Creates a tile from texture.
		 * @param texture
		 * @param autoCrop
		 */
		public function ScrollTile ( texture:Texture, autoCrop:Boolean = false )
		{	
			 if ( texture == null ) throw new ArgumentError("Texture cannot be null");
			
			if ( texture is ConcreteTexture ) {
				mSubTexture = new SubTexture ( texture, null );
			} else {
				mSubTexture = SubTexture (texture);
			}

			mBaseTexture = mSubTexture.parent;

			while ( mBaseTexture is SubTexture )
			{					
				mBaseTexture = SubTexture (mBaseTexture).parent;
			}
			
			var propClippX:Number =  mSubTexture.parent.width / mBaseTexture.width;
			var propClippY:Number =  mSubTexture.parent.height / mBaseTexture.height;
			
			mBaseClipping = new Rectangle
				(
					mSubTexture.clipping.x * propClippX,
					mSubTexture.clipping.y * propClippY,
					mSubTexture.clipping.width * propClippX,
					mSubTexture.clipping.height * propClippY
				);

			if ( autoCrop ) crop (1, 1);
			mColorTrans = new Vector.<Number> (4);
			
			alpha = 1;	
			color = 0xFFFFFF;			
		}

		/**
		 * Set crop inside of texture - helps with borders artefact.
		 * @param x
		 * @param y
		 */
		public function crop ( x:Number = 2, y:Number = 2):void
		{		
			var dx:Number = x * 2 < mSubTexture.width ?  -x / mBaseTexture.width : 0;
			var dy:Number = y * 2 < mSubTexture.height ?  -y / mBaseTexture.height : 0;

			mBaseClipping.inflate ( dx, dy );	
		}

		/**
		 * Dispose
		 */
		public function dispose ():void
		{
			mSubTexture = null;
			mBaseTexture = null;
		}

		/**
		 * Return texture.
		 */
		public function get baseTexture ():Texture { return mBaseTexture; }

		/**
		 * Return texure clipping
		 */
		public function get baseClipping ():Rectangle { return mBaseClipping; }

		/**
		 * Return color of tile.
		 */
		public function get color():uint { return mColor; }

		/**
		 * Set color of tile.
		 * @param value
		 */
		public function set color (value:uint):void
		{ 
			mColor = value; 
		
			mColorTrans[0] = ((value >> 16) & 0xff) / 255.0;
			mColorTrans[1] = ((value >>  8) & 0xff) / 255.0;
			mColorTrans[2] = ( value 		 & 0xff) / 255.0;		
		}

		/**
		 * Return alpha color of tile
		 */
		public function get alpha ():Number { return mAlpha; }

		/**
		 * Set alpha of tile.
		 * @param value
		 */
		public function set alpha (value:Number):void 
		{
			mAlpha = value; 
			mColorTrans[3] = value;			
		}

		/**
		 * Alpha and color as Vector
		 */
		internal function get colorTrans():Vector.<Number> { return mColorTrans; }

		/**
		 * Width of tile in pixels.
		 */
		public function get width ():Number { return mSubTexture.width; }

		/**
		 * Return height of tile in pixels.
		 */
		public function get height():Number { return mSubTexture.height; }

		/**
		 * The scaleX of tile.
		 */
		public function get scaleX ():Number { return mScaleX; }

		/**
		 * The scaleX of tile.
		 */
		public function set scaleX (value:Number):void { mScaleX = value; }

		/**
		 * The scaleY of tile
		 */
		public function get scaleY():Number { return mScaleY; }

		/**
		 * The scaleY of tile
		 */
		public function set scaleY(value:Number):void { mScaleY = value; }

		/**
		 * The x offset of tile in pixels.
		 */
		public function get offsetX():Number { return mOffsetX; }

		/**
		 * The x offset of tile in pixels.
		 */
		public function set offsetX(value:Number):void { mOffsetX = value; }

		/**
		 * The x offset of tile in pixels.
		 */
		public function get offsetY():Number { return mOffsetY; }

		/**
		 * The x offset of tile in pixels.
		 */
		public function set offsetY (value:Number):void { mOffsetY = value; }

		/**
		 * The rotation of the tile in radians.
		 */
		public function get rotation():Number { return mRotation; }

		/**
		 * The rotation of the tile in radians.
		 */
		public function set rotation(value:Number):void { mRotation = value; }

		/**
		 * The paralx effect. Value == 1 means that there's no paralax effect.
		 */
		public function get paralax():Number { return mParalax; }

		/**
		 * The paralx effect. Value == 1 means that there's no paralax effect.
		 */
		public function set paralax(value:Number):void { mParalax = value; }

	}
}