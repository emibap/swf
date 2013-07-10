package format.swf.instance;


import flash.display.BitmapData;
import flash.display.DisplayObject;
import flash.display.Shape;
import flash.display.Sprite;
import flash.geom.ColorTransform;
import flash.geom.Matrix;
import flash.geom.Rectangle;
import flash.text.TextField;
import flash.text.TextFieldAutoSize;
import flash.text.TextFormat;
import flash.events.Event;
import flash.Lib;
import format.swf.data.SWFButtonRecord;
import format.swf.exporters.AS3GraphicsDataShapeExporter;
import format.swf.exporters.ShapeCommandExporter;
import format.swf.tags.TagDefineBits;
import format.swf.tags.TagDefineBitsLossless;
import format.swf.tags.TagDefineButton;
import format.swf.tags.TagDefineButton;
import format.swf.tags.TagDefineButton;
import format.swf.tags.TagDefineButton2;
import format.swf.tags.TagDefineEditText;
import format.swf.tags.TagDefineShape;
import format.swf.tags.TagDefineSprite;
import format.swf.tags.TagDefineText;
import format.swf.tags.TagPlaceObject;
import format.swf.timeline.FrameObject;


class SimpleButton extends flash.display.SimpleButton {
	
	private var data:TagDefineButton2;
	
	public function new (data:TagDefineButton2) {
		
		super();
		
		this.data = data;
		
		
		createStates ();
		
		
		
	}
	
	private function createStates():Void {
		
		var recs:Array<SWFButtonRecord> = data.getRecordsByState(TagDefineButton.STATE_UP);
		if (recs != null) {
			upState = getState(recs);	
		}
		recs = data.getRecordsByState(TagDefineButton.STATE_DOWN);
		if (recs != null) {
			downState = getState(recs);	
		}
		recs = data.getRecordsByState(TagDefineButton.STATE_OVER);
		if (recs != null) {
			overState = getState(recs);	
		}
		recs = data.getRecordsByState(TagDefineButton.STATE_HIT);
		if (recs != null) {
			hitTestState = getState(recs);	
		} else {
			if (upState != null) hitTestState = upState;
		}
		
		
	}
	
	function getState(records:Array<SWFButtonRecord>) :DisplayObject
	{
		var stateContainer:Sprite = new Sprite();
		var displayObject:DisplayObject = null;
		for (object in records) {
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
				
			} else if (Std.is (symbol, TagDefineButton2)) {
				
				displayObject = new SimpleButton(cast symbol);
				
			}
			
			if (displayObject != null) {
				placeRecord(displayObject, object);
				stateContainer.addChild(displayObject);
			}
		}
		
		if (stateContainer.numChildren == 0) stateContainer = null;
		
		return stateContainer;
	}
	
	
	private function placeRecord (displayObject:DisplayObject, record:SWFButtonRecord):Void {
		
		if ( record.colorTransform != null && !record.colorTransform.isIdentity()) {
			displayObject.transform.colorTransform = record.colorTransform.colorTransform;
		}
		
		if ( record.placeMatrix != null && !record.placeMatrix.isIdentity()) {
			var matrix = record.placeMatrix.matrix;
			matrix.tx *= 1 / 20;
			matrix.ty *= 1 / 20;
			
			displayObject.transform.matrix = matrix;
		}
		
		if ( record.hasFilterList) {
			var filters_arr:Array<Dynamic> = [];
			for (i in 0...record.filterList.length) { filters_arr[i] = record.filterList[i].filter; }
			displayObject.filters = filters_arr;
		}
		
	}
	
	
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
	
}