starling-extensions
===================

Extensions for the Starling Framework
Update 2013.01.23:
Performance boost.
Adding useBaseTexture argument in the constructor. If "true", Scrollimage will use whole texture area (without UV clipping, texture must be power of two size). This setting avoid calculate uv mapping what kill older desktop GPU and mobiles in HD resolution (e.g. ipad3).