package format.swf.instance;


import flash.display.BitmapData;
import flash.display.DisplayObject;
import flash.display.Shape;
import flash.geom.ColorTransform;
import flash.geom.Matrix;
import flash.geom.Rectangle;
import flash.text.TextField;
import flash.text.TextFieldAutoSize;
import flash.text.TextFormat;
import flash.events.Event;
import flash.Lib;
import format.swf.exporters.AS3GraphicsDataShapeExporter;
import format.swf.exporters.ShapeCommandExporter;
import format.swf.tags.TagDefineBits;
import format.swf.tags.TagDefineBitsLossless;
import format.swf.tags.TagDefineEditText;
import format.swf.tags.TagDefineShape;
import format.swf.tags.TagDefineSprite;
import format.swf.tags.TagDefineText;
import format.swf.tags.TagPlaceObject;
import format.swf.timeline.FrameObject;


class MovieClip extends flash.display.MovieClip {
	
	
	private static var clips:Array <MovieClip>;
	private static var initialized:Bool;
	
	private var data:SWFTimelineContainer;
	private var lastUpdate:Int;
	private var playing:Bool;
	
	private var activeObjects:Map<Int, DisplayObject>;
	
	#if flash
	private var __currentFrame:Int;
	private var __totalFrames:Int;
	#end
	
	
	
	public function new (data:SWFTimelineContainer) {
		
		super ();
		
		this.data = data;
		
		if (!initialized) {
			
			clips = new Array <MovieClip> ();
			Lib.current.stage.addEventListener (Event.ENTER_FRAME, stage_onEnterFrame);
			
			initialized = true;
			
		}
		
		//currentFrame = 1;
		__currentFrame = 1;
		//__totalFrames = data.frames.length;
		__totalFrames = data.frames.length;
		
		activeObjects = new Map();
		
		//trace("frames: " + __totalFrames);
		
		update ();
		
		if (__totalFrames > 1) {
			
			play ();
			
		}
		
	}
	
	
	private inline function applyTween (start:Float, end:Float, ratio:Float):Float {
		
		return start + ((end - start) * ratio);
		
	}
	
	
	/*private function createBitmap (xfl:XFL, instance:DOMBitmapInstance):Bitmap {
		
		var bitmap = null;
		var bitmapData = null;
		
		if (xfl.document.media.exists (instance.libraryItemName)) {
			
			var bitmapItem = xfl.document.media.get (instance.libraryItemName);
			bitmapData = Assets.getBitmapData (Path.directory (xfl.path) + "/bin/" + bitmapItem.bitmapDataHRef);
			
		}
		
		if (bitmapData != null) {
			
			bitmap = new Bitmap (bitmapData);
			
			if (instance.matrix != null) {
				
				bitmap.transform.matrix = instance.matrix;
				
			}
			
		}
		
		return bitmap;
		
	}*/
	
	
	private function createDynamicText (symbol:TagDefineEditText):TextField {
		
		var textField = new TextField ();
		textField.selectable = !symbol.noSelect;
		
		var rect:Rectangle = symbol.bounds.rect;
		
		textField.width = rect.width;
		textField.height = rect.height;
		textField.multiline = symbol.multiline;
		textField.wordWrap = symbol.wordWrap;
		textField.autoSize = (symbol.autoSize)? TextFieldAutoSize.LEFT : TextFieldAutoSize.NONE;
		textField.border = symbol.border;
		
		return textField;
		
	}
	
	
	private function createShape (symbol:TagDefineShape):Shape {
		
		//var handler = new AS3GraphicsDataShapeExporter (data);
		//symbol.export (handler);
		//
		//var shape = new Shape ();
		//shape.graphics.drawGraphicsData (handler.graphicsData);
		
		var handler = new ShapeCommandExporter (data);
		symbol.export (handler);
		
		var shape = new Shape ();
		
		for (command in handler.commands) {
			
			switch (command.type) {
				
				case BEGIN_FILL: shape.graphics.beginFill (command.params[0], command.params[1]);
				case BEGIN_GRADIENT_FILL: shape.graphics.beginGradientFill (command.params[0], command.params[1], command.params[2], command.params[3], command.params[4], command.params[5], command.params[6], command.params[7]);
				case BEGIN_BITMAP_FILL: 
					
					var bitmap = new Bitmap (cast data.getCharacter (command.params[0]));
					shape.graphics.beginBitmapFill (bitmap.bitmapData, command.params[1], command.params[2], command.params[3]);
					
				case END_FILL: shape.graphics.endFill ();
				case LINE_STYLE: 
					
					if (command.params.length > 0) {
						
						shape.graphics.lineStyle (command.params[0], command.params[1], command.params[2], command.params[3], command.params[4], command.params[5], command.params[6], command.params[7]);
						
					} else {
						
						shape.graphics.lineStyle ();
						
					}
				
				case MOVE_TO: shape.graphics.moveTo (command.params[0], command.params[1]);
				case LINE_TO: shape.graphics.lineTo (command.params[0], command.params[1]);
				case CURVE_TO: shape.graphics.curveTo (command.params[0], command.params[1], command.params[2], command.params[3]);
				
			}
			
		}
		
		return shape;
		
	}
	
	
	private function createStaticText (symbol:TagDefineText):TextField {
		
		var textField = new TextField ();
		textField.selectable = false;
		
		//textField.x += instance.left;
		
		// xfl does not embed the font
		//textField.embedFonts = true;
		
		//var format = new TextFormat ();
		
		/*
		for (record in symbol.records) {
			
			var pos = textField.text.length;
			
			for (entry in record.glyphEntries) {
				
				entry.
				
			}
			
			textField.appendText (record.);
			
			if (textRun.textAttrs.face != null) format.font = textRun.textAttrs.face;
			if (textRun.textAttrs.alignment != null) format.align = Reflect.field (TextFormatAlign, textRun.textAttrs.alignment.toUpperCase ());
			if (textRun.textAttrs.size != 0) format.size = textRun.textAttrs.size;
			if (textRun.textAttrs.fillColor != 0) {
				
				if (textRun.textAttrs.alpha != 0) {
					
					// need to add alpha to color
					format.color = textRun.textAttrs.fillColor;
					
				} else {
					
					format.color = textRun.textAttrs.fillColor;
					
				}
				
			}
			
			textField.setTextFormat (format, pos, textField.text.length);
			
		}*/
		
		return textField;
		
	}
	
	
	/*private function createSprite (symbol:SWFTimelineContainer, object:FrameObject):MovieClip {
		
		var movieClip = new MovieClip (symbol, swf);
		
		if (movieClip != null) {
			
			if (object.matrix != null) {
				
				movieClip.transform.matrix = object.matrix;
				
			}
			
			/*if (instance.color != null) {
				
				movieClip.transform.colorTransform = instance.color;
				
			}*/
			
			//movieClip.cacheAsBitmap = instance.cacheAsBitmap;
			
			/*if (instance.exportAsBitmap) {
				
				movieClip.flatten ();
				
			}
			
		}
		
		return movieClip;
		
	}*/
	
	
	private function enterFrame ():Void {
		
		trace(name);
		if (this.name == "locoCuad") {
			trace(name);
		}
		
		if (lastUpdate == __currentFrame) {
			
			__currentFrame ++;
			
			if (__currentFrame > __totalFrames) {
				
				__currentFrame = 1;
				
			}
			
		}
		
		update ();
		
	}
	
	
	public /*override*/ function flatten ():Void {
		
		var bounds = getBounds (this);
		var bitmapData = null;
		
		if (bounds.width > 0 && bounds.height > 0) {
			
			bitmapData = new BitmapData (Std.int (bounds.width), Std.int (bounds.height), true, #if neko { a: 0, rgb: 0x000000 } #else 0x00000000 #end);
			var matrix = new Matrix ();
			matrix.translate (-bounds.left, -bounds.top);
			bitmapData.draw (this, matrix);
			
		}
		
		for (i in 0...numChildren) {
			
			var child = getChildAt (0);
			
			if (Std.is (child, MovieClip)) {
				
				untyped child.stop ();
				
			}
			
			removeChildAt (0);
			
		}
		
		if (bounds.width > 0 && bounds.height > 0) {
			
			var bitmap = new flash.display.Bitmap (bitmapData);
			bitmap.smoothing = true;
			bitmap.x = bounds.left;
			bitmap.y = bounds.top;
			addChild (bitmap);
			
		}
		
		stop();
		
	}
	
	
	private function getFrame (frame:Dynamic):Int {
		
		if (Std.is (frame, Int)) {
			
			return cast frame;
			
		} else if (Std.is (frame, String)) {
			
			// need to handle frame labels
			
		}
		
		return 1;
		
	}
	
	
	public override function gotoAndPlay (frame:#if flash flash.utils.Object #else Dynamic #end, scene:String = null):Void {
		
		__currentFrame = getFrame (frame);
		update ();
		play ();
		
	}
	
	
	public override function gotoAndStop (frame:#if flash flash.utils.Object #else Dynamic #end, scene:String = null):Void {
		
		__currentFrame = getFrame (frame);
		update ();
		stop ();
		
	}
	
	
	public override function nextFrame ():Void {
		
		var next = __currentFrame + 1;
		
		if (next > __totalFrames) {
			
			next = __totalFrames;
			
		}
		
		gotoAndStop (next);
		
	}
	
	
	private function placeObject (displayObject:DisplayObject, frameObject:FrameObject):Void {
		
		var firstTag:TagPlaceObject = cast data.tags [frameObject.placedAtIndex];
		var lastTag:TagPlaceObject = null;
		
		if (frameObject.lastModifiedAtIndex > 0) {
			
			lastTag = cast data.tags [frameObject.lastModifiedAtIndex];
			
		}
		
		if (lastTag != null && lastTag.hasName) {
			
			displayObject.name = lastTag.instanceName;
			
		} else if (firstTag.hasName) {
			
			displayObject.name = firstTag.instanceName;
			
		}
		
		if (lastTag != null && lastTag.hasMatrix) {
			
			var matrix = lastTag.matrix.matrix;
			matrix.tx *= 1 / 20;
			matrix.ty *= 1 / 20;
			
			displayObject.transform.matrix = matrix;
			
		} else if (firstTag.hasMatrix) {
			
			var matrix = firstTag.matrix.matrix;
			matrix.tx *= 1 / 20;
			matrix.ty *= 1 / 20;
			
			displayObject.transform.matrix = matrix;
			
		}
		
		if (lastTag != null && lastTag.hasColorTransform) {
			
			displayObject.transform.colorTransform = lastTag.colorTransform.colorTransform;
			
		} else if (firstTag.hasColorTransform) {
			
			displayObject.transform.colorTransform = firstTag.colorTransform.colorTransform;
			
		}
		
		if (lastTag != null && lastTag.hasFilterList) {
			var filters_arr:Array<Dynamic> = [];
			for (i in 0...lastTag.surfaceFilterList.length) { filters_arr[i] = lastTag.surfaceFilterList[i].filter; }
			displayObject.filters = filters_arr;
		} else if ( firstTag.hasFilterList) {
			var filters_arr:Array<Dynamic> = [];
			for (i in 0...firstTag.surfaceFilterList.length) { filters_arr[i] = firstTag.surfaceFilterList[i].filter; }
			displayObject.filters = filters_arr;
		}
		
	}
	
	
	public override function play ():Void {
		
		if (!playing && __totalFrames > 1) {
			
			playing = true;
			clips.push (this);
			
		}
		
	}
	
	
	public override function prevFrame ():Void {
		
		var previous = __currentFrame - 1;
		
		if (previous < 1) {
			
			previous = 1;
			
		}
		
		gotoAndStop (previous);
		
	}
	
	
	private function renderFrame (index:Int):Void {
		
		var frame = data.frames[index];
		
		//if (frame.frameNumber == currentFrame - 1 || frame.tweenType == null || frame.tweenType == "") {
		
		for (object in frame.objects) {
			
			var displayObject:DisplayObject = null;
			if (!activeObjects.exists(object.characterId)) {	
				var symbol = data.getCharacter (object.characterId);
				
				if (Std.is (symbol, TagDefineSprite)) {
					
					displayObject = new MovieClip (cast symbol);
					
				} else if (Std.is (symbol, TagDefineBitsLossless)) {
					
					trace ("png");
					//displayObject = createBitmap (cast symbol);
					
				} else if (Std.is (symbol, TagDefineBits)) {
					
					trace ("jpg");
					
				} else if (Std.is (symbol, TagDefineShape)) {
					
					displayObject = createShape (cast symbol);
					
				} else if (Std.is (symbol, TagDefineText)) {
					
					displayObject = createStaticText (cast symbol);
					
				} else if (Std.is (symbol, TagDefineEditText)) {
					
					displayObject = createDynamicText (cast symbol);
					
				}
			}
			
			
			
			if (displayObject != null) {
				
				placeObject (displayObject, object);
				addChild (displayObject);
				activeObjects.set(object.characterId, displayObject);
				
			}
			
		}
		
		var removeCandidate:DisplayObject;
		for (i in activeObjects.keys()) {
			removeCandidate = activeObjects.get(i);
			if (!contains(removeCandidate)) {
				if (Std.is(removeCandidate, MovieClip)) {
					untyped removeCandidate.stop ();
				}
				activeObjects.remove(i);
			}
		}
		
			/*for (element in frame.elements) {
				
				if (Std.is (element, DOMSymbolInstance)) {
					
					var movieClip = createSymbol (xfl, cast element);
					
					if (movieClip != null) {
						
						addChild (movieClip);
						
					}
					
				} else if (Std.is (element, DOMBitmapInstance)) {
					
					var bitmap = createBitmap (xfl, cast element);
					
					if (bitmap != null) {
						
						addChild (bitmap);
						
					}
					
				} else if (Std.is (element, DOMShape)) {
					
					var shape = new Shape (cast element);
					addChild (shape);
					
				} else if (Std.is (element, DOMDynamicText)) {
					
					var text = createDynamicText (cast element);
					
					if (text != null) {
						
						addChild (text);
						
					}
					
				} else if (Std.is (element, DOMStaticText)) {
					
					var text = createStaticText (cast element);
					
					if (text != null) {
						
						addChild (text);
						
					}
					
				}
				
			}*/
			
		/*} else if (frame.tweenType == "motion") {
			
			if (index < layer.frames.length - 1) {
				
				var firstInstance = null;
				
				for (element in frame.elements) {
					
					if (Std.is (element, DOMSymbolInstance)) {
						
						firstInstance = element;
						break;
						
					}
					
				}
				
				var secondFrame = layer.frames[index + 1];
				var secondInstance = null;
				
				for (element in secondFrame.elements) {
					
					if (Std.is (element, DOMSymbolInstance)) {
						
						secondInstance = element;
						break;
						
					}
					
				}
				
				if (firstInstance.libraryItemName == secondInstance.libraryItemName) {
					
					var instance:DOMSymbolInstance = firstInstance.clone ();
					var ratio = (currentFrame - frame.index) / frame.duration;
					
					if (secondInstance.matrix != null) {
						
						if (instance.matrix == null) instance.matrix = new Matrix ();
						
						instance.matrix.a = applyTween (instance.matrix.a, secondInstance.matrix.a, ratio);
						instance.matrix.b = applyTween (instance.matrix.b, secondInstance.matrix.b, ratio);
						instance.matrix.c = applyTween (instance.matrix.c, secondInstance.matrix.c, ratio);
						instance.matrix.d = applyTween (instance.matrix.d, secondInstance.matrix.d, ratio);
						instance.matrix.tx = applyTween (instance.matrix.tx, secondInstance.matrix.tx, ratio);
						instance.matrix.ty = applyTween (instance.matrix.ty, secondInstance.matrix.ty, ratio);
						
					}
					
					if (secondInstance.color != null) {
						
						if (instance.color == null) instance.color = new Color ();
						
						instance.color.alphaMultiplier = applyTween (instance.color.alphaMultiplier, secondInstance.color.alphaMultiplier, ratio);
						instance.color.alphaOffset = applyTween (instance.color.alphaOffset, secondInstance.color.alphaOffset, ratio);
						instance.color.blueMultiplier = applyTween (instance.color.blueMultiplier, secondInstance.color.blueMultiplier, ratio);
						instance.color.blueOffset = applyTween (instance.color.blueOffset, secondInstance.color.blueOffset, ratio);
						instance.color.greenMultiplier = applyTween (instance.color.greenMultiplier, secondInstance.color.greenMultiplier, ratio);
						instance.color.greenOffset = applyTween (instance.color.greenOffset, secondInstance.color.greenOffset, ratio);
						instance.color.redMultiplier = applyTween (instance.color.redMultiplier, secondInstance.color.redMultiplier, ratio);
						instance.color.redOffset = applyTween (instance.color.redOffset, secondInstance.color.redOffset, ratio);
						
					}
					
					var movieClip = createSymbol (xfl, instance);
					
					if (movieClip != null) {
						
						addChild (movieClip);
						
					}
					
				}
				
			}
			
		} else if (frame.tweenType == "motion object") {
			
			var instances = [];
			
			for (element in frame.elements) {
				
				if (Std.is (element, DOMSymbolInstance)) {
					
					instances.push (element.clone ());
					
				}
				
			}
			
			// temporarily render without tweening
			
			for (instance in instances) {
				
				var movieClip = createSymbol (xfl, instance);
				
				if (movieClip != null) {
					
					addChild (movieClip);
					
				}
				
			}
			
		}*/
		
	}
	
	
	public override function stop ():Void {
		
		if (playing) {
			
			playing = false;
			clips.remove (this);
			
		}
		
	}
	
	
	public /*override*/ function unflatten ():Void {
		
		lastUpdate = -1;
		update ();
		
	}
	
	
	private function update ():Void {
		
		if (this.name == "locoCuad") {
			trace(name);
		}
		
		if (__currentFrame != lastUpdate) {
			
			/*for (i in 0...numChildren) {
				
				var child = getChildAt (0);
				
				if (Std.is (child, MovieClip)) {
					
					untyped child.stop ();
					
				}
				
				removeChildAt (0);
				
			}
			*/
			
			//var frameIndex = -1;
			//
			//for (i in 0...data.frames.length) {
				//
				//if (data.frames[i]. <= currentFrame) {
					//
					//frameIndex = i;
					//
				//}
				//
			//}
			
			var frameIndex = __currentFrame - 1;
			
			if (frameIndex > -1) {
				
				renderFrame (frameIndex);
				
			}
			
		}
		
		lastUpdate = __currentFrame;
		
	}
	
	
	
	
	// Get & Set Methods
	
	
	
	
	#if flash
	@:getter public function get_currentFrame():Int {
		
		return __currentFrame;
		
	}
	
	
	@:getter public function get___totalFrames():Int {
		
		return __totalFrames;
		
	}
	#end
	
	
	
	
	// Event Handlers
	
	
	
	
	private static function stage_onEnterFrame (event:Event):Void {
		
		for (clip in clips) {
			
			clip.enterFrame ();
			
		}
		
	}
	
	
}