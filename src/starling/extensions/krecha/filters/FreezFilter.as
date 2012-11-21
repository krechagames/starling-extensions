package starling.extensions.krecha.filters
{
    import flash.display3D.Context3D;
    import flash.display3D.Program3D;
	import starling.filters.FragmentFilter;
    
    import starling.textures.Texture;

	/**
	 * Filter draw object only once - use clearCache() to unfreez. Based on starling.filters.IdentityFilter.
	 */
    public class FreezFilter extends FragmentFilter
    {
        private var mShaderProgram:Program3D;
        
        public function FreezFilter()
        {
            super ();		
			cache ();
        }

		/**
		 * Update view
		 */
		public function update ():void
		{
			clearCache ();
			cache ();
		}

		/**
		 * @inheritDocs
		 */
        public override function dispose():void
        {
            if (mShaderProgram) mShaderProgram.dispose();
            super.dispose();
        }

		/**
		 * @inheritDocs
		 */
        protected override function createPrograms():void
        {
            var fragmentProgramCode:String =
                "tex oc, v0, fs0 <2d, clamp, linear, mipnone>"; // just forward texture color
            
            mShaderProgram = assembleAgal(fragmentProgramCode);
        }

		/**
		 * @inheritDocs
		 */
        protected override function activate(pass:int, context:Context3D, texture:Texture):void
        {
            // already set by super class:
            // 
            // vertex constants 0-3: mvpMatrix (3D)
            // vertex attribute 0:   vertex position (FLOAT_2)
            // vertex attribute 1:   texture coordinates (FLOAT_2)
            // texture 0:            input texture
            
            context.setProgram(mShaderProgram);
        }
    }
}