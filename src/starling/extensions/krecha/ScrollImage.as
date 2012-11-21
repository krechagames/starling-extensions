package starling.extensions.krecha 
{
	import com.adobe.utils.AGALMiniAssembler;

	import flash.display3D.*;
	import flash.geom.*;
	import flash.utils.Dictionary;

	import starling.core.RenderSupport;
	import starling.core.Starling;
	import starling.display.DisplayObject;
	import starling.errors.MissingContextError;
	import starling.events.Event;
	import starling.textures.Texture;
	import starling.textures.TextureSmoothing;
	import starling.utils.VertexData;

	/**
	 * Display object with tile texture, may contain 16 TileTexture objects
	 * @author KrechaGames - Łukasz 'Cywil' Cywiński
	 * Thanks to Pierre Chamberlain - http://pierrechamberlain.ca/blog
	 */
	public class ScrollImage extends DisplayObject
	{
		private var mSyncRequired:Boolean;

		// vertex data
		private var mVertexData:VertexData;
		private var mVertexBuffer:VertexBuffer3D;

		// ShaderConstand and clipping index data
		private var mExtraBuffer:VertexBuffer3D;
		private var mExtraData:Vector.<Number>;

		// index data
		private var mIndexData:Vector.<uint>;
		private var mIndexBuffer:IndexBuffer3D;
		private var mTexture:Texture;

		// helper objects (to avoid temporary objects)
		private var sRenderColorAlpha:Vector.<Number> = new <Number>[1.0, 1.0, 1.0, 1.0];
		private var sMatrix:Matrix3D = new Matrix3D ();		
		private var sPremultipliedAlpha:Boolean;
		private var sRegister:uint;	
		private static var sProgramNameCache:Dictionary = new Dictionary ();
		
		//properties
		private var mCanvasWidth:Number;
		private var mCanvasHeight:Number;
		private var mTextureWidth:Number = 0;
		private var mTextureHeight:Number = 0;
		private var maxU:Number;
		private var maxV:Number;
		private var mColor:uint;
		private var tempWidth:Number;
		private var tempHeight:Number;		
		private var mMaxLayersAmount:uint;	
		private var mSmoothing:String = TextureSmoothing.BILINEAR;
		private var mMipMapping:Boolean = false;
		private var mBaseProgram:String;
		
		//layers
		private var mLayers:Vector.<ScrollTile> = new Vector.<ScrollTile> ();	
		private var mLayersMatrix:Vector.<Matrix3D> = new Vector.<Matrix3D> ();	
		private var mMainLayer:ScrollTile;
		private var mLayerVertexData:VertexData;
		private var mFreez:Boolean;
		
		//paralax		
		private var mPar:Boolean = true;
		private var mParOffset:Boolean = true;
		private var mParScale:Boolean = true;
		
		//transform		
		private var mTilesOffsetX:Number = 0;
		private var mTilesOffsetY:Number = 0;		
		private var mTilesRotation:Number = 0;			
		private var mTilesScaleX:Number = 1;			
		private var mTilesScaleY:Number = 1;		
		private var mTilesPivotX:Number = 0;		
		private var mTilesPivotY:Number = 0;		
		private var mTextureRatio:Number;

		/**
		 * Creates an object with tiled texture. Default without mipMapping to avoid some borders anrtefacts.
		 * @param width
		 * @param height
		 */
		public function ScrollImage ( width:Number, height:Number )
		{
			//0,1,2,3 - transform matrix, 4 - alpha, must start from vc5
			sRegister = 5;

			//maximum amount of layers
			mMaxLayersAmount = 16;

			//base program without tint/alpha/mipmaps and with blinear smoothing
			mBaseProgram = getImageProgramName ( false, mMipMapping, mSmoothing );
			this.mCanvasWidth = width;
			this.mCanvasHeight = height;				
			
			resetVertices ();		
			registerPrograms ();	
			
			color = 0xFFFFFF;
			
			mSyncRequired = false;	
			
			// handle lost context
			Starling.current.addEventListener(Event.CONTEXT3D_CREATE, onContextCreated);			
		}

		/**
		 * Context created handler
		 * @param event
		 */
		private function onContextCreated(event:Event):void
		{
			//the old context was lost, so we create new buffers and shaders.
			createBuffers();
			registerPrograms ();
		}

		/**
		 * Reset vertexData
		 */
		private function resetVertices ():void 
		{
			mVertexData = new VertexData ( 0 );
			mIndexData = new Vector.<uint>();	
			mExtraData = new Vector.<Number>();
		}

		/**
		 * Add layer on the top.
 		 * @param layer
		 * @return
		 */
		public function addLayer ( layer:ScrollTile ):ScrollTile
		{			
			return addLayerAt ( layer, numLayers + 1 );			
		}

		/**
		 * Add layer at index.
		 * @param layer
		 * @param index
		 * @return
		 */
		public function addLayerAt ( layer:ScrollTile, index:int ):ScrollTile
		{
			if ( index > numLayers ) index = numLayers + 1;

			if ( mLayers.length == 0 && mLayers.length < mMaxLayersAmount ) {
				mainSetup ( layer );				
			} else if ( mTexture != layer.baseTexture ) {
				throw new Error ( "Layers must use this same texture.");
				
			} else if ( mLayers.length >= mMaxLayersAmount ) {				
				throw new Error ( "Maximum layers amount has been reached! Max is " + mMaxLayersAmount );			
			}
			
			mLayers.splice ( index, 0, layer );	
			mLayersMatrix.splice ( index, 0,  new Matrix3D () );	
			
			updateMesh ();	
			return layer;
		}

		/**
		 * Remove layer at index.
		 * @param id
		 */
		public function removeLayerAt ( id:int ):void
		{			
			if ( mLayers.length && id < mLayers.length ){
				mLayers.splice ( id, 1 );
				mLayersMatrix.splice ( id, 1 );

				if ( mLayers.length ) {
					updateMesh ();
				}else {
					reset ();
				}
			}else {
				return;
			}
		}

		/**
		 * Remove all layers.
		 * @param dispose
		 */
		public function removeAll ( dispose:Boolean = false ):void
		{
			if ( dispose ){
				for (var i:int = 0; i < mLayers.length; i++) 
				{
					mLayers[i].dispose ();
				}
			}
			reset ();
		}
		
		/**
		 * Return layer at index.
		 * @param layer
		 */
		public function getLayerAt ( index:uint ):ScrollTile
		{
			if ( index < mLayers.length ) return  mLayers[index];;
			return null;
		}

		/**
		 * Setup object property using first layer.
		 * @param layer
		 */
		private function mainSetup ( layer:ScrollTile ):void 
		{	
			mMainLayer = layer;
			mTexture = mMainLayer.baseTexture;		
			sPremultipliedAlpha = mTexture.premultipliedAlpha;
			
			mTextureWidth = mTexture.width;
			mTextureHeight = mTexture.height;
			
			mTextureRatio =  mTextureWidth / mTextureHeight;
				
			maxU = mCanvasWidth / mTextureWidth;			
			maxV = mCanvasHeight / mTextureHeight;	
			
			if ( mLayerVertexData == null ) {
				mLayerVertexData = new VertexData (4);						

				mLayerVertexData.setPosition ( 0, 0, 0 );
				mLayerVertexData.setPosition ( 1, mCanvasWidth, 0);
				mLayerVertexData.setPosition ( 2, 0, mCanvasHeight);
				mLayerVertexData.setPosition ( 3, mCanvasWidth, mCanvasHeight);
					
				mLayerVertexData.setTexCoords (0, 0, 0);
				mLayerVertexData.setTexCoords (1, maxU, 0 );
				mLayerVertexData.setTexCoords (2, 0, maxV );
				mLayerVertexData.setTexCoords (3, maxU, maxV );	
			}
		}

		/**
		 * Update mesh
		 */
		private function updateMesh ():void
		{	
			if ( mMainLayer ) {				
				resetVertices ();
			
				for (var i:int = 0; i < mLayers.length; i++) 
				{
					setupVertices ( i, mLayers[i] );						
				}	
				if ( mLayers.length ) createBuffers ();
			}
		}

		/**
		 * Reset all resources.
		 */
		private function reset():void 
		{
			mLayers = new Vector.<ScrollTile> ();
			mLayersMatrix = new Vector.<Matrix3D> ();
			mMainLayer = null;
			mTextureWidth = mTextureHeight = 0;
			resetVertices ();
		}

		/**
		 * Returns a rectangle that completely encloses the object as it appears in another coordinate system.
		 * @param targetSpace
		 * @param resultRect
		 * @return
		 */
		public override function getBounds(targetSpace:DisplayObject, resultRect:Rectangle = null):Rectangle
		{
			if (resultRect == null)
				resultRect = new Rectangle();
			var transformationMatrix:Matrix = getTransformationMatrix(targetSpace);
			return mVertexData.getBounds(transformationMatrix, 0, -1, resultRect);
		}

		/**
		 * Creates vertex for a layer.
		 * @param id
		 * @param layer
		 */
		private function setupVertices ( id:int, layer:ScrollTile ):void
		{				
			mVertexData.append ( mLayerVertexData );	
			
			mIndexData[int(id*6  )] = id*4;
            mIndexData[int(id*6+1)] = id*4 + 1;
            mIndexData[int(id*6+2)] = id*4 + 2;
            mIndexData[int(id*6+3)] = id*4 + 1;
            mIndexData[int(id*6+4)] = id*4 + 3;
            mIndexData[int(id*6+5)] = id*4 + 2;		
			
			var i:int = -1;
			while (++i < 4 ) {
				mExtraData.push ( getColorRegister (id), getTransRegister (id), int (sPremultipliedAlpha), layer.baseClipping.x, layer.baseClipping.y, layer.baseClipping.width, layer.baseClipping.height );				
			}	
		}

		/**
		 * Return next free color register number.
		 * @param id
		 * @return
		 */
		private function getColorRegister  ( id:uint ):uint { return sRegister + ( id * 5 ); }

		/**
		 * Return next free transform register number.
		 * @param id
		 * @return
		 */
		private function getTransRegister  ( id:uint ):uint { return sRegister + ( id * 5 ) + 1; }

		/**
		 * Creates new vertex- and index-buffers and uploads our vertex- and index-data to those buffers.
		 */
		private function createBuffers():void
		{	
			//check if width/height was set before vertex creation
			if ( tempWidth ) width = tempWidth;
			if ( tempHeight ) height = tempHeight;
			
			var context:Context3D = Starling.context;
			if (context == null)
				throw new MissingContextError();
			
			if (mVertexBuffer)
				mVertexBuffer.dispose();
			if (mIndexBuffer)
				mIndexBuffer.dispose();
			if (mExtraBuffer)
				mExtraBuffer.dispose ();
				
			mVertexBuffer = context.createVertexBuffer(mVertexData.numVertices, VertexData.ELEMENTS_PER_VERTEX);
			mVertexBuffer.uploadFromVector(mVertexData.rawData, 0, mVertexData.numVertices);

			mExtraBuffer = context.createVertexBuffer( mVertexData.numVertices, 7 );
			mExtraBuffer.uploadFromVector(mExtraData, 0, mVertexData.numVertices);
			
			mIndexBuffer = context.createIndexBuffer(mIndexData.length);
			mIndexBuffer.uploadFromVector (mIndexData, 0, mIndexData.length);			
		}

		/**
		 * Renders the object with the help of a 'support' object and with the accumulated alpha of its parent object.
		 * @param support
		 * @param alpha
		 */
		public override function render(support:RenderSupport, alpha:Number):void
		{	
			if ( mLayers.length == 0) return;
			support.raiseDrawCount ();
			
			support.finishQuadBatch();
			if (mSyncRequired) syncBuffers();
			
			var context:Context3D = Starling.context;
			if (context == null)
				throw new MissingContextError();
			
			// apply the current blendmode
			support.applyBlendMode( sPremultipliedAlpha );	
			
			//set texture
			if (mTexture)
				context.setTextureAt(0, mTexture.base);
			
			//set buffers
			context.setVertexBufferAt(0, mVertexBuffer, VertexData.POSITION_OFFSET, Context3DVertexBufferFormat.FLOAT_2); //position			
			context.setVertexBufferAt(1, mVertexBuffer, VertexData.TEXCOORD_OFFSET, Context3DVertexBufferFormat.FLOAT_2); //UV
			context.setVertexBufferAt(2, mExtraBuffer, VertexData.POSITION_OFFSET, Context3DVertexBufferFormat.FLOAT_3); //vc for color and transform registers
			context.setVertexBufferAt(3, mExtraBuffer, 3, Context3DVertexBufferFormat.FLOAT_4); //clipping		
		
			//set alpha				
			sRenderColorAlpha[3] = this.alpha * alpha;
			
			//set object and layers data
			context.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX, 0, support.mvpMatrix3D, true);
			context.setProgramConstantsFromVector (Context3DProgramType.VERTEX, 4, sRenderColorAlpha, 1);
		
			var tintedlayer:Boolean = false;

			var layer:ScrollTile;			
			for (var i:int = 0; i < mLayers.length; i++) 
			{				
				layer = mLayers[i];
				
				tintedlayer = tintedlayer || layer.color != 0xFFFFFF || layer.alpha != 1.0;

				sMatrix = mFreez ? mLayersMatrix[i] : calculateMatrix ( layer, mLayersMatrix[i] );		
				
				context.setProgramConstantsFromVector (Context3DProgramType.VERTEX, getColorRegister (i), layer.colorTrans, 1);				
				context.setProgramConstantsFromMatrix (Context3DProgramType.VERTEX, getTransRegister (i), sMatrix, true);				
			}	
			
			// activate program (shader)
			var tinted:Boolean = (sRenderColorAlpha[3] != 1.0) || color != 0xFFFFFF || tintedlayer;			
			context.setProgram (Starling.current.getProgram ( getImageProgramName ( tinted, mMipMapping, mSmoothing, mTexture.format ) ));
			
			//draw the object
			context.drawTriangles( mIndexBuffer, 0, mIndexData.length/3 );
			
			//reset buffers
			if (mTexture) {
				context.setTextureAt(0, null);
			}

			context.setVertexBufferAt(0, null);
			context.setVertexBufferAt(1, null);
			context.setVertexBufferAt(2, null);
			context.setVertexBufferAt(3, null);
		}

		/**
		 * Uploads the raw data of all batched quads to the vertex buffer.
		 */
        private function syncBuffers():void
        {	
            if (mVertexBuffer == null)
                createBuffers();
            else
            {  
                mVertexBuffer.uploadFromVector(mVertexData.rawData, 0, mVertexData.numVertices);
                mSyncRequired = false;
            }		
        }

		/**
		 * Calculate matrix transform for a layer
		 * @param layer
		 * @param matrix
		 * @return
		 */
		private function calculateMatrix ( layer:ScrollTile, matrix:Matrix3D ):Matrix3D
		{
			var pOffset:Number = mParOffset ? layer.paralax : 1;
			var pScale:Number = mParScale ? layer.paralax : 1;
			var angle:Number = layer.rotation + tilesRotation;

			matrix.identity ();		
			
			matrix.prependTranslation ( -mTilesPivotX, - mTilesPivotY, 0);

			//for no square ratio, scale to square
			if ( mTextureRatio != 1 ) matrix.appendScale ( 1, 1 / mTextureRatio,  1 );

			matrix.appendScale ( 1 / (layer.scaleX * 1 / pScale) / tilesScaleX + 1 - pScale, 1 / (layer.scaleY * 1 / pScale) / tilesScaleY + 1 - pScale, 1 );
			matrix.appendRotation ( - angle * 180 / Math.PI, Vector3D.Z_AXIS );

			//for no square ratio, unscale from square to orginal ratio
			if ( mTextureRatio != 1 ) 	matrix.appendScale ( 1, mTextureRatio,  1 );

			matrix.appendTranslation ( mTilesPivotX - (layer.offsetX + mTilesOffsetX )  / mTextureWidth * pOffset, mTilesPivotY -(layer.offsetY + mTilesOffsetY ) / mTextureHeight * pOffset, 0);	
			return matrix;
		}


		/**
		 * Register the programs
		 */
		private function registerPrograms():void
		{
			var target:Starling = Starling.current;			
			if ( target.hasProgram( mBaseProgram ) )
				return; // already registered				
			
			// create vertex and fragment programs from assembly
            var vertexProgramAssembler:AGALMiniAssembler = new AGALMiniAssembler();
            var fragmentProgramAssembler:AGALMiniAssembler = new AGALMiniAssembler();
            
            var vertexProgramCode:String;
            var fragmentProgramCode:String;
			// va0 -> position
			// va1 -> UV
			// va2.x -> vc index for color
			// va2.y -> vc index for transformation
			// va2.z -> premultiplied alpha 1/0
			// va3 -> clipping
			// vc0 -> mvpMatrix (4 vectors, vc0 - vc3)
			// vc4 -> alpha and color
			
			//vc[va2.x] -> color and alpha for layer
			//vc[va2.y] -> matrix transform for layer
			
			//pass to fragment shader
			//v0 -> color
			//v1 -> uv
			//v2 -> x,y of start
			//v3 ->width, height and reciprocals
			
			for each (var tinted:Boolean in [true, false])
            {
				vertexProgramCode =		tinted ?
				"mov vt0, vc4 \n" + 						// store color in temp0			
				"mul vt0, vt0, vc[va2.x] \n"+ 				// multiply color with alpha for layer and pass it to fragment shader	
				"pow vt1, vt0.w, va2.z \n" + 				// if mPremulitply == 0 alpha multiplayer == 1				
				"mul vt0.xyz, vt0.xyz, vt1.xxx \n"+ 		// multiply color by alpha 		
				"mov v0, vt0 \n" 							// pass it to fragment shader				
				:
				"mov v0, vc4 \n";  							// pass color to fragment shader	
				
				vertexProgramCode +=	
				"mov vt2, va3 \n" +  						// store in temp1 the tile clipping			
				"mov v2, vt2 \n" +     						// pass the x and y of start		
				"mov v3.xy, vt2.zw \n" +   					// pass the width & height
				"rcp v3.z, vt2.z \n" +   					// pass the reciprocals of width
				"rcp v3.w, vt2.w \n" +  					// pass the reciprocals of heigh				
				
				"m44 vt2, va1, vc[va2.y] \n" + 				// mutliply UV by transform matrix
				"mov v1, vt2 \n" +  						// pass the uvs.	
				
				"m44 op, va0, vc0 \n" 						// 4x4 matrix transform to output space	
				
				vertexProgramAssembler.assemble(Context3DProgramType.VERTEX, vertexProgramCode);	
				fragmentProgramCode =				
				"mov ft0, v1 \n" + 							// sotre UV`a to temp0
				"mul ft0.xy, ft0.xy, v3.zw \n" + 			// multiply to larger number
				"frc ft0.xy, ft0.xy \n" +					// keep the fraction of the large number
				"mul ft0.xy, ft0.xy, v3.xy \n" + 			// multiply to smaller number
				"add ft0.xy, ft0.xy, v2.xy \n" +			// add the start x & y of the tile
				"tex ft1, ft0, fs0 <???> \n" 				// sample texture 0
				
				fragmentProgramCode +=	tinted ?				
				"kil v0.w \n" +								// kill pixel if tile alpha == 0
				"mul oc, ft1, v0 \n"   						// multiply color with texel color and output
				:
				"mov oc, ft1 \n"   							// output
				
				var smoothingTypes:Array = [
					TextureSmoothing.NONE,
					TextureSmoothing.BILINEAR,
					TextureSmoothing.TRILINEAR
				];
					
				var formats:Array = [
					Context3DTextureFormat.BGRA,
					Context3DTextureFormat.COMPRESSED,
					"compressedAlpha" // use explicit string for compatibility
				];
				
				for each (var mipmap:Boolean in [true, false])
						{
							for each (var smoothing:String in smoothingTypes)
							{
								for each (var format:String in formats)
								{
									var options:Array = ["2d"];
									
									if (format == Context3DTextureFormat.COMPRESSED)
										options.push("dxt1");
									else if (format == "compressedAlpha")
										options.push("dxt5");
									
									if (smoothing == TextureSmoothing.NONE)
										options.push("nearest", mipmap ? "mipnearest" : "mipnone");
									else if (smoothing == TextureSmoothing.BILINEAR)
										options.push("linear", mipmap ? "mipnearest" : "mipnone");
									else
										options.push("linear", mipmap ? "miplinear" : "mipnone");
								  
									fragmentProgramAssembler.assemble(Context3DProgramType.FRAGMENT,
										fragmentProgramCode.replace("???", options.join()));
								  
									target.registerProgram(
										getImageProgramName(tinted, mipmap, smoothing, format),
										vertexProgramAssembler.agalcode, fragmentProgramAssembler.agalcode);
									
								}
							}
						}		
			}
		}

		/**
		 * Return program name.
		 * @param tinted
		 * @param mipMap
		 * @param smoothing
		 * @param format
		 * @return
		 */
		private static function getImageProgramName( tinted:Boolean = false, mipMap:Boolean=true, smoothing:String="bilinear", format:String="bgra" ):String
        {
            var bitField:uint = 0;
            
            if (tinted) bitField |= 1;
            if (mipMap) bitField |= 2;
            
            if (smoothing == TextureSmoothing.NONE)
                bitField |= 1 << 3;
            else if (smoothing == TextureSmoothing.TRILINEAR)
                bitField |= 1 << 4;
            
            if (format == Context3DTextureFormat.COMPRESSED)
                bitField |= 1 << 5;
            else if (format == "compressedAlpha")
                bitField |= 1 << 6;
            
            var name:String = sProgramNameCache[bitField];
            
            if (name == null)
            {
                name = "SImage_i." + bitField.toString(16);
                sProgramNameCache[bitField] = name;
            }
            return name;
        }

		/**
		 * Disposes all resources of the display object.
		 */
		public override function dispose():void
		{
			Starling.current.removeEventListener(Event.CONTEXT3D_CREATE, onContextCreated);
			
			if (mVertexBuffer)
				mVertexBuffer.dispose();
			if (mIndexBuffer)
				mIndexBuffer.dispose();

			mLayers = null;
			mLayersMatrix = null;
			mTexture = null;

			super.dispose();
		}

		/**
		 * Tint color.
		 */
		public function get color():uint {
			return mColor;
		}

		/**
		 * Tint color.
		 */
		public function set color (value:uint):void {
			mColor = value;				
	
			sRenderColorAlpha[0] = ((color >> 16) & 0xff) / 255.0;
			sRenderColorAlpha[1] = ((color >>  8) & 0xff) / 255.0;
			sRenderColorAlpha[2] = ( color 		 & 0xff) / 255.0;	
		}

		/**
		 * Canvas width in pixels.
		 */
		public function get canvasWidth():Number {
			return mCanvasWidth;
		}

		/**
		 * Canvas width in pixels.
		 */
		public function set canvasWidth (value:Number):void 
		{ 			
			mCanvasWidth = value;
			if ( mMainLayer ){
				mainSetup ( mMainLayer );
				mSyncRequired = true;
			}
		}

		/**
		 * Canvas height in pixels.
		 */
		public function get canvasHeight():Number {
			return mCanvasHeight;
		}

		/**
		 * Canvas height in pixels.
		 */
		public function set canvasHeight (value:Number):void 
		{ 
			mCanvasHeight = value;

			if ( mMainLayer ){
				mainSetup ( mMainLayer );
				mSyncRequired = true;
			}
		}

		/**
		 * @inheritDocs
		 */
		override public function get width ():Number 
		{ 
			return numLayers == 0 ? super.width : 0;
		}

		/**
		 * @inheritDocs
		 */
		override public function set width (value:Number):void 
		{ 
			if ( mTextureWidth ) {
				super.width = value; 				
				tempWidth = 0;				
			}else {				
				tempWidth = value;
			}
		}

		/**
		 * @inheritDocs
		 */
		override public function get height ():Number 
		{ 
			return numLayers == 0 ? super.height : 0;
		}

		/**
		 * @inheritDocs
		 */
		override public function set height (value:Number):void 
		{ 
			if ( mTextureHeight ){
				super.height = value; 
				tempHeight = 0;
			}else {
				tempHeight = value;
			}
		}

		/**
		 * Texture used in object - from the layer on index 0.
		 */
		public function get texture():Texture { return mTexture; }

		/**
		 * The horizontal scale factor. '1' means no scale, negative values flip the tiles.
		 */
		public function get tilesScaleX():Number { return mTilesScaleX; }

		/**
		 * The horizontal scale factor. '1' means no scale, negative values flip the tiles.
		 */
		public function set tilesScaleX(value:Number):void { mTilesScaleX = value; }

		/**
		 * The vertical scale factor. '1' means no scale, negative values flip the tiles.
		 */
		public function get tilesScaleY():Number { return mTilesScaleY; }

		/**
		 * The vertical scale factor. '1' means no scale, negative values flip the tiles.
		 */
		public function set tilesScaleY(value:Number):void { mTilesScaleY = value; }

		/**
		 * The x offet of the tiles.
		 */
		public function get tilesOffsetX():Number { return mTilesOffsetX; }

		/**
		 * The x offet of the tiles.
		 */
		public function set tilesOffsetX (value:Number):void { mTilesOffsetX = value; }

		/**
		 * The y offet of the tiles.
		 */
		public function get tilesOffsetY():Number { return mTilesOffsetY; }

		/**
		 * The y offet of the tiles.
		 */
		public function set tilesOffsetY(value:Number):void { mTilesOffsetY = value; }

		/**
		 * The rotation of the tiles in radians.
		 */
		public function get tilesRotation():Number { return mTilesRotation; }

		/**
		 * The rotation of the tiles in radians.
		 */
		public function set tilesRotation (value:Number):void { mTilesRotation = value; }

		/**
		 * The x pivot for rotation and scale the tiles.
		 */
		public function get tilesPivotX():Number { return mTilesPivotX * mTextureWidth; }

		/**
		 * The x pivot for rotation and scale the tiles.
		 */
		public function set tilesPivotX (value:Number):void { mTilesPivotX = mTextureWidth ? value / mTextureWidth : 0; }

		/**
		 * The y pivot for rotation and scale the tiles.
		 */
		public function get tilesPivotY ():Number { return mTilesPivotY * mTextureHeight; }

		/**
		 * The y pivot for rotation and scale the tiles.
		 */
		public function set tilesPivotY (value:Number):void { mTilesPivotY = mTextureHeight ? value / mTextureHeight : 0; }

		/**
		 * Determinate parlax for offset.
		 */
		public function get paralaxOffset():Boolean { return mParOffset; }

		/**
		 * Determinate parlax for offset.
		 */
		public function set paralaxOffset (value:Boolean):void { mParOffset = value; }

		/**
		 * Determinate parlax for scale.
		 */
		public function get paralaxScale():Boolean { return mParScale; }

		/**
		 * Determinate parlax for scale.
		 */
		public function set paralaxScale(value:Boolean):void { mParScale = value; }

		/**
		 * Determinate parlax for all transformations.
		 */
		public function get paralax():Boolean { return mPar; }

		/**
		 * Determinate parlax for all transformations.
		 */
		public function set paralax(value:Boolean):void 
		{			
			mPar = value;
			paralaxOffset = value;
			paralaxScale = value;
		}

		/**
		 * Avoid all tiles transformations - for better performance matrixes are not calculate.
		 */
		public function get freez():Boolean { return mFreez; }

		/**
		 * Avoid all tiles transformations - for better performance matrixes are not calculate.
		 */
		public function set freez(value:Boolean):void 
		{
			for (var i:int = 0; i < mLayers.length; i++) 
			{
				calculateMatrix ( mLayers[i], mLayersMatrix[i] );
			}
			mFreez = value; 
		}

		/**
		 * Return number of layers
		 */
		public function get numLayers():int { return mLayers.length; }

		/**
		 * The smoothing filter that is used for the texture.
		 */
		public function get smoothing():String { return mSmoothing; }

		/**
		 * The smoothing filter that is used for the texture.
		 */
		public function set smoothing (value:String):void {	mSmoothing = value; }

		/**
		 * Determinate mipmapping for the texture - default set to false to avoid borders artefacts.
		 */
		public function get mipMapping():Boolean { return mMipMapping; }

		/**
		 * Determinate mipmapping for the texture - default set to false to avoid borders artefacts.
		 */
		public function set mipMapping (value:Boolean):void 
		{ 
			if ( mTexture ){
				mMipMapping = value ? mTexture.mipMapping : value; 
			}else {
				mMipMapping = value;
			}
		}

	}
}