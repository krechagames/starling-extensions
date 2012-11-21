package com.krechagames.demos 
{
	import flash.ui.Keyboard;
	import flash.utils.getTimer;
	import starling.core.Starling;
	import starling.display.Image;
	import starling.display.Sprite;
	import starling.events.Event;
	import starling.extensions.krecha.filters.FreezFilter;
	import starling.extensions.krecha.ScrollImage;
	import starling.extensions.krecha.ScrollTile;
	import starling.textures.Texture;
	import starling.textures.TextureAtlas;
	import uk.co.bigroom.input.KeyPoll;
	/**
	 * ...
	 * @author 
	 */
	public class ScrollCar extends Sprite
	{
		[Embed(source="../../../../lib/textures/car.png")]
		public var Atlas:Class;
		[Embed(source="../../../../lib/textures/car.xml", mimeType="application/octet-stream")]
		public var AtlasXml:Class;
		
		private var ground:ScrollImage;
		private var clouds:ScrollImage;
		
		private var centerX:int = 300;
		private var centerY:int = 400;
		private var car:Image;
		private var angle:Number;
		private var velocity:Number;
		private var zoom:Number;

		private var keyPoll:KeyPoll;
		
		public function ScrollCar() 
		{
			angle = 0;
			velocity = 0;
			zoom = 1;
			
			if (stage) init (null); else addEventListener (Event.ADDED_TO_STAGE, init);
		}
		
		private function init(e:Event):void 
		{
			removeEventListener(Event.ADDED_TO_STAGE, init);
			
			//atlas
			var atlas:TextureAtlas = new TextureAtlas ( Texture.fromBitmap(new Atlas(), false), XML(new AtlasXml ()));	
			
			var scrollTile:ScrollTile;
			//setup ground
			ground = new ScrollImage ( 600, 600 );
			ground.color = 0x528762
			scrollTile = ground.addLayer (  new ScrollTile ( atlas.getTexture ('grass'), true ) );				
			
			//pivot must be set after add first layer
			ground.tilesPivotX = centerX;
			ground.tilesPivotY = centerY;		
			
			//setup clouds
			clouds = new ScrollImage ( 600, 600 ) ;				
			scrollTile = clouds.addLayer (  new ScrollTile ( atlas.getTexture ('clouds'), true ) );			
			scrollTile.alpha = .5;
			scrollTile.paralax = 1.3;	
			
			scrollTile = clouds.addLayer (  new ScrollTile ( atlas.getTexture ('clouds'), true ) );			
			scrollTile.alpha = .2;
			scrollTile.paralax = 1.5;
			scrollTile.offsetX = 50;
			scrollTile.scaleX = scrollTile.scaleY = 1.2;	
			
			//pivot must be set after add first layer
			clouds.tilesPivotX = centerX;
			clouds.tilesPivotY = centerY;			
			
			//car
			car = new Image (  atlas.getTexture ('car') );	
			car.x = centerX;
			car.y = centerY;
			car.pivotX = car.width / 2;
			car.pivotY = car.height / 2;			
			
			addChild ( ground );
			addChild ( car );
			addChild (clouds);

			addEventListener ( Event.ENTER_FRAME, update );			
			
			keyPoll = new KeyPoll (Starling.current.stage);
			
		}
		
		private function update(e:Event):void 
		{					
			if ( keyPoll.isDown ( Keyboard.W ) ) {
				if ( velocity < 10 ) velocity += .1				
			}else if (  keyPoll.isDown ( Keyboard.S ) ){
				if ( velocity > -5 ) velocity -= .2
			}else {
				if ( velocity > 0 ) {
					velocity -= .1;
				} else if ( velocity < 0 )  {
					velocity += .1;
				}
			}		
			
		
			if ( keyPoll.isDown ( Keyboard.A ) ) {
				angle -= .002 * velocity;
			}else if ( keyPoll.isDown ( Keyboard.D ) ) {
				angle += .002 * velocity;
			}
			
			if ( Math.abs (velocity) < .1 ) velocity = 0;
			zoom = 1 - velocity / 40;						
			
			var x:Number = Math.cos (angle) * velocity;
			var y:Number = Math.sin (angle) * velocity;
			var rotation:Number = -angle + Math.PI / 2;
		
			
			car.scaleX = car.scaleY = zoom;
			updateTilese ( ground, x, y, rotation, zoom );
			updateTilese ( clouds, x, y, rotation, zoom );			
		}
		
		private function updateTilese(tile:ScrollImage, x:Number, y:Number, rotation:Number, zoom:Number):void 
		{
			tile.tilesOffsetX += x;
			tile.tilesOffsetY += y;
			tile.tilesRotation = rotation;
			tile.tilesScaleX = tile.tilesScaleY =  zoom;				
		}
		
	}

}