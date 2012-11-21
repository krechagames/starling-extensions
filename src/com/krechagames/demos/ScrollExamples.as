package com.krechagames.demos 
{
	import flash.utils.getTimer;
	import starling.display.BlendMode;
	import starling.display.Image;
	import starling.display.Sprite;
	import starling.events.Event;
	import starling.extensions.krecha.ScrollImage;
	import starling.extensions.krecha.ScrollTile;
	import starling.textures.Texture;
	import starling.textures.TextureAtlas;
	/**
	 * ...
	 * @author 
	 */
	public class ScrollExamples extends Sprite
	{
		[Embed(source="../../../../lib/textures/examples.png")]
		public var Atlas:Class;
		[Embed(source="../../../../lib/textures/examples.xml", mimeType="application/octet-stream")]
		public var AtlasXml:Class;
		
		
		private var counter1:ScrollImage;
		private var counter2:ScrollImage;
		private var lines:ScrollImage;
		private var water:ScrollImage;
		private var wave:ScrollImage;
		private var tvLines:ScrollImage;
		
		
		
		public function ScrollExamples() 
		{
			if (stage) init(null); else addEventListener(Event.ADDED_TO_STAGE, init);
		}
		
		private function init(e:Event):void 
		{
			removeEventListener(Event.ADDED_TO_STAGE, init);
			
			//atlas
			var atlas:TextureAtlas = new TextureAtlas ( Texture.fromBitmap(new Atlas(), false), XML(new AtlasXml ()));	
			
			//tiles
			var scrollTile:ScrollTile;
			
			//counter
			counter1 = new ScrollImage ( 50, 50 );
			counter2 = new ScrollImage ( 50, 50 );
			counter1.x = 50;
			counter2.x = 100;
			counter1.y = counter2.y = 50;	
			
			scrollTile = counter1.addLayer (  new ScrollTile (atlas.getTexture ('counter')) )
			scrollTile = counter2.addLayer (  new ScrollTile (atlas.getTexture ('counter')) )		
			
			addChild ( counter1 );
			addChild ( counter2 );
			
			//lines
			lines = new ScrollImage (300, 70);			
			lines.x = 50;
			lines.y = 150;
			scrollTile = lines.addLayer (  new ScrollTile (atlas.getTexture ('line_1')) );			
			scrollTile = lines.addLayer (  new ScrollTile (atlas.getTexture ('line_2')) );
			lines.tilesPivotX = 150;
			lines.tilesPivotY = 35;
			
			addChild (lines);
			
			//water
			water = new ScrollImage (15, 150);	
			water.x = 465;
			water.y = 110;
			
			var tap:Image = new Image (atlas.getTexture ('tap'));
			tap.x = 400;
			tap.y = 50;			
			
			scrollTile = water.addLayer (  new ScrollTile (atlas.getTexture ('water')) );			
			
			addChild (water);
			addChild (tap);
			
			//wave
			wave = new ScrollImage (500, 60);			
			wave.x = 50;
			wave.y = 280;			
			
			scrollTile = wave.addLayer (  new ScrollTile (atlas.getTexture ('wave'), true) );
			scrollTile.offsetY = - 40;
			scrollTile.color = 0x008080;
			scrollTile.alpha = .4;
			scrollTile.paralax = .7;		
			
			scrollTile = wave.addLayer (  new ScrollTile (atlas.getTexture ('wave'), true) );		
			scrollTile.offsetY = - 35;
			scrollTile.color = 0x008080;
			scrollTile.alpha = .5;
			scrollTile.paralax = 1;
			scrollTile.scaleX = scrollTile.scaleY = .8;
			
			scrollTile = wave.addLayer (  new ScrollTile (atlas.getTexture ('wave'), true) );		
			scrollTile.offsetY = - 40;
			scrollTile.color = 0x008080;
			scrollTile.alpha = .2;
			scrollTile.paralax = 1;
			scrollTile.scaleX = scrollTile.scaleY = .6;
			
			wave.tilesPivotY = 60;			
			
			addChild ( wave );
			
			//tv
			var tv:Image = new Image (atlas.getTexture ('tv'))
			tv.x = 150;
			tv.y = 380;
			
			tvLines = new ScrollImage ( 175, 127 );
			tvLines.x = tv.x + 25;
			tvLines.y = tv.y + 25;
			tvLines.blendMode = BlendMode.ADD;
			scrollTile = tvLines.addLayer (  new ScrollTile (atlas.getTexture ('tv_line')) );	
			tvLines.tilesScaleY = .3;
			
			
			addChild (tv);
			addChild (tvLines);
			
			addEventListener ( Event.ENTER_FRAME, update );				
		}
		
		private function update(e:Event):void 
		{			
			//counter
			counter1.tilesOffsetY -= .5;
			counter2.tilesOffsetY -= 5;
			
			//lines
			lines.getLayerAt(0).offsetX += 2;
			lines.getLayerAt (1).offsetX += 8;
			lines.getLayerAt (1).scaleY = 1 + Math.abs (Math.sin (getTimer () / 500) * .2);
			lines.getLayerAt (1).color = 0x00FF00 + Math.abs (Math.sin (getTimer () / 500) * 0xA6A6A6);
			
			//water
			water.tilesOffsetY += 3;
			
			//wave
			wave.tilesOffsetX += 2//Math.sin (getTimer () / 500);	
			wave.getLayerAt (0).offsetY = -20 - Math.sin (getTimer () / 1000)*20;
			wave.getLayerAt (1).offsetY = -25 - Math.sin (100 + getTimer () / 1000) * 5;
			
			//tv
			tvLines.color = Math.random () * 0x252525;
			tvLines.tilesScaleY = 1 + Math.random () *.5;
			tvLines.tilesOffsetY += 1;			
		}
		
	}

}