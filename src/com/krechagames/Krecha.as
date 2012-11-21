package com.krechagames
{
	import cf.tools.console.Console;
	import com.krechagames.demos.ScrollCar;
	import com.krechagames.demos.ScrollExamples;
	import flash.display.Sprite;
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;
	import flash.events.Event;
	import flash.geom.Rectangle;
	import flash.ui.Multitouch;
	import flash.ui.MultitouchInputMode;
	import starling.core.Starling;

	[SWF(width="600", height="600", frameRate="60", backgroundColor="0xFFEECA")]
	public class Krecha extends Sprite
	{
		private var mStarling:Starling;			
		
		public function Krecha()
		{
			if ( stage )
				init( null );
			else
				addEventListener( Event.ADDED_TO_STAGE, init );
		}
		
		private function init( e:Event ):void
		{
			removeEventListener( Event.ADDED_TO_STAGE, init );
			
			Multitouch.inputMode = MultitouchInputMode.TOUCH_POINT;
			stage.align = StageAlign.TOP_LEFT;
			stage.scaleMode = StageScaleMode.NO_SCALE;
			
			Starling.multitouchEnabled = true;
			

			var viewport:Rectangle = new Rectangle ( 0, 0, stage.stageWidth, stage.stageHeight );			
			
			//mStarling = new Starling ( ScrollCar, stage, viewport, null, "auto" );
			mStarling = new Starling ( ScrollExamples, stage, viewport, null, "auto" );
			
			Starling.current.stage.stageWidth = stage.stageWidth;	
			Starling.current.stage.stageHeight = stage.stageHeight;
						
			mStarling.antiAliasing = 1;
			mStarling.start();
			mStarling.showStats = true;		
		}
	
	}
}
