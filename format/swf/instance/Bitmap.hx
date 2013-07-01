package format.swf.instance;


import flash.display.BitmapData;
import flash.display.Loader;
import flash.events.Event;
import flash.geom.Point;
import flash.geom.Rectangle;
import flash.utils.ByteArray;
import format.swf.data.consts.BitmapFormat;
import format.swf.tags.IDefinitionTag;
import format.swf.tags.TagDefineBits;
import format.swf.tags.TagDefineBitsLossless;
import format.swf.tags.TagDefineBitsJPEG2;


class Bitmap extends flash.display.Bitmap {
	
	var loader:Loader;
	
	public function new (tag:IDefinitionTag) {
		
		super ();
		
		if (Std.is (tag, TagDefineBitsLossless)) {
			
			var data:TagDefineBitsLossless = cast tag;
			
			var transparent = (data.level > 1);
			var buffer = data.zlibBitmapData;
			
			try {
				
				buffer.uncompress ();
				
			} catch (e:Dynamic) { }
			
			buffer.position = 0;
			
			if (data.bitmapFormat == BitmapFormat.BIT_8) {
				
				var colorTable = new Array <Int> ();
				
				for (i in 0...data.bitmapColorTableSize) {
					
					var r = buffer.readByte ();
					var g = buffer.readByte ();
					var b = buffer.readByte ();
					
					if (transparent) {
						
						var a = buffer.readByte ();
						colorTable.push ((a << 24) + (r << 16) + (g << 8) + b);
						
					} else {
						
						colorTable.push ((r << 16) + (g << 8) + b);
						
					}
					
				}
				
				var imageData = new ByteArray ();
				var padding = Math.ceil (data.bitmapWidth / 4) - Math.floor (data.bitmapWidth / 4);
				
				for (y in 0...data.bitmapHeight) {
					
					for (x in 0...data.bitmapWidth) {
						
						imageData.writeUnsignedInt (colorTable[buffer.readByte ()]);
						
					}
					
					buffer.position += padding;
					
				}
				
				buffer = imageData;
				buffer.position = 0;
				
			}
			
			var bitmapData = new BitmapData (data.bitmapWidth, data.bitmapHeight, transparent);
			bitmapData.setPixels (new Rectangle (0, 0, data.bitmapWidth, data.bitmapHeight), buffer);
			
			this.bitmapData = bitmapData;
			
		} else if (Std.is (tag, TagDefineBits)) {
			var bitsTag:TagDefineBits = cast tag;
			
			var data:ByteArray = bitsTag.bitmapData;
			
			// Have to get the image's width and height to create a bitmapData. The real data will be loaded and parsed later
			var i:Int = 4;
			var w:Int = 2;
			var h:Int = 2;
			//Retrieve the block length of the first block since the first block will not contain the size of file
			var block_length:Int = data[i] * 256 + data[i+1];
			while (i < data.length) {
				i+=block_length;               //Increase the file index to get to the next block

				if(data[i+1] == 0xC0) {            //0xFFC0 is the "Start of frame" marker which contains the file size
				   //The structure of the 0xFFC0 block is quite simple [0xFFC0][ushort length][uchar precision][ushort x][ushort y]
				   h = data[i+5]*256 + data[i+6];
				   w = data[i+7]*256 + data[i+8];
				}
				else
				{
				   i+=2;                              			//Skip the block marker
				   block_length = data[i] * 256 + data[i+1];    //Go to the next block
				}
			}
			
			bitmapData = new BitmapData(w, h, true, 0);
			
			loader = new Loader ();
			//this.alpha = alpha;

			loader.contentLoaderInfo.addEventListener (Event.COMPLETE, loader_onComplete);
			loader.loadBytes (data);
			
		}
	}
	
	/*private function createWithAlpha (data:BitmapData, alpha:ByteArray):BitmapData {

		var alphaBitmap = new BitmapData (data.width, data.height, true);
		var index = 0;

		for (y in 0...data.height) {

			for (x in 0...data.width) {

				#if (!neko || haxe3)

				alphaBitmap.setPixel32 (x, y, data.getPixel (x, y) + (alpha[index ++] << 24));

				#else

				var pixel = data.getPixel32 (x, y);
				pixel.a = alpha[index ++];
				alphaBitmap.setPixel32 (x, y, pixel);

				#end

			}

		}

		return alphaBitmap;

	}*/




	// Event Handlers





	private function loader_onComplete (event:Event):Void {

		//bitmapData.copyPixels(event.currentTarget.content.bitmapData, bitmapData.rect, new Point());
		bitmapData.setVector(bitmapData.rect, event.currentTarget.content.bitmapData.getVector(bitmapData.rect));
		
		/*if (alpha != null && bitmapData != null) {

			var width = bitmapData.width;
			var height = bitmapData.height;

			if (Std.int (alpha.length) != Std.int (width * height)) {

				throw ("Alpha size mismatch");

			}

			bitmapData = createWithAlpha (bitmapData, alpha);

		}*/

		loader.removeEventListener (Event.COMPLETE, loader_onComplete);
		loader = null;
		//alpha = null;

	}
	
	
}