#import "MITMapAnnotationCalloutView.h"
#import "MITMapView.h"

// Corner radius for the callout bubble.
static const CGFloat kCornerRadius = 10;

// Width and height of the chevron that points to the called-out location.
static const CGFloat kChevronWidth = 28;
static const CGFloat kChevronHeight = 14;

static const CGFloat kCalloutWidth = 275;
static const CGFloat kBuffer = 10;
static const CGFloat kTitleFontSize = 16;
static const CGFloat kSubTitleFontSize = 12;

@interface MITMapAnnotationCalloutView(Private) 

-(CGRect) rectForAccessory;

@end


@implementation MITMapAnnotationCalloutView
@synthesize annotation = _annotation;

- (id)initWithAnnotation:(id <MKAnnotation>)annotation andMapView:(MITMapView*)mapView
{
	if (self = [super initWithFrame:CGRectMake(10, 150, 275, 125)])
	{
		_calloutAccessoryImage = [[UIImage imageNamed:@"map_disclosure.png"] retain];

		_mapView = mapView;
		
		self.annotation = annotation;
		self.opaque = NO;
		
	}
	
	return self;
}

- (void)dealloc
{
	[_annotation release];
	
	[_calloutAccessoryImage release];
	
	[super dealloc];
}

- (void)setOrigin:(CGPoint)origin
{
	CGRect frame = self.frame;
	frame.origin.x = origin.x;
	frame.origin.y = origin.y - (frame.size.height / 2);
	[self setNeedsDisplay];
}

-(void) setAnnotation:(id<MKAnnotation>)annotation
{
	[_annotation release];
	_annotation = [annotation retain];
	
	// setting the annotation determines the frame based on the content of the annotation.
	CGSize size = [[_annotation title] sizeWithFont:[UIFont boldSystemFontOfSize:kTitleFontSize] 
					constrainedToSize:CGSizeMake(kCalloutWidth - kBuffer * 3 - _calloutAccessoryImage.size.width, 400) 
						lineBreakMode:UILineBreakModeWordWrap];
	
	size.height += kBuffer * 2; // buffer for above and below the title
	
	
	NSString* subtitle = nil;
	if([_annotation respondsToSelector:@selector(subtitle)])
		subtitle = [_annotation subtitle];

	if (nil != subtitle) 
	{
		CGSize subSize = [subtitle sizeWithFont:[UIFont systemFontOfSize:kSubTitleFontSize] 
						constrainedToSize:CGSizeMake(kCalloutWidth - kBuffer * 3 - _calloutAccessoryImage.size.width, 400) 
							lineBreakMode:UILineBreakModeWordWrap];
		
		size.height += (subSize.height);
		if(subSize.width > size.width)
			size.width = subSize.width;
			
	}
	
	// add the chevron height
	size.height += kChevronHeight;
	
	self.frame = CGRectMake(self.frame.origin.x, self.frame.origin.y,
							size.width + kBuffer * 3 + _calloutAccessoryImage.size.width, size.height);
	
}

-(void) touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
	// if the touch was inside our rect, navigate. 
	UITouch* touch = [touches anyObject];
	
	CGPoint locationInView = [touch locationInView:self];
	
	CGRect accessoryRect = [self rectForAccessory];
	
	// pad the rect a little so it is more easily hit
	accessoryRect = CGRectMake(accessoryRect.origin.x - 5, accessoryRect.origin.y - 5, accessoryRect.size.width + 10, accessoryRect.size.height + 10);
	
	if(CGRectContainsPoint(accessoryRect, locationInView))
	{
		if ([_mapView.delegate respondsToSelector:@selector(mapView:annotationViewcalloutAccessoryTapped:)]) {
			[_mapView.delegate mapView:_mapView annotationViewcalloutAccessoryTapped:self];
		}
	}
	
	
	
}

- (void)drawRect:(CGRect)rect
{
	CGContextRef context = UIGraphicsGetCurrentContext();
	
	// Account for the chevron before drawing our paths.
	rect.size.height -= kChevronHeight;
	
	// Create a rounded rectangle to form the callout box.
	CGMutablePathRef path = CGPathCreateMutable();
	
	// Begin at top left.
	CGPathMoveToPoint(path, NULL, rect.origin.x, rect.origin.y + kCornerRadius);
	
	// Draw top right.
	CGPathAddArcToPoint(
		path, NULL,
		rect.origin.x, rect.origin.y,
		rect.origin.x + kCornerRadius, rect.origin.y,
		kCornerRadius
	);
	CGPathAddLineToPoint(path, NULL, rect.origin.x + rect.size.width - kCornerRadius, rect.origin.y);
	
	// Draw lower right.
	CGPathAddArcToPoint(
		path, NULL,
		rect.origin.x + rect.size.width, rect.origin.y,
		rect.origin.x + rect.size.width, rect.origin.y + kCornerRadius,
		kCornerRadius
	);
	
	CGPathAddLineToPoint(path, NULL, rect.origin.x + rect.size.width, rect.origin.y + rect.size.height - kCornerRadius);
	
	// Draw lower right.
	CGPathAddArcToPoint(
						path, NULL,
						rect.origin.x + rect.size.width, rect.origin.y + rect.size.height,
						rect.origin.x + rect.size.width - kCornerRadius, rect.origin.y + rect.size.height,
						kCornerRadius
						);
	
	CGFloat midX = (rect.origin.x + rect.size.width) / 2;
	CGFloat halfChevWidth = kChevronWidth / 2;
	CGPathAddLineToPoint(path, NULL, midX + halfChevWidth, rect.origin.y + rect.size.height);
	CGPathAddLineToPoint(path, NULL, midX,                 rect.origin.y + rect.size.height + kChevronHeight);
	CGPathAddLineToPoint(path, NULL, midX - halfChevWidth, rect.origin.y + rect.size.height);
	CGPathAddLineToPoint(path, NULL, rect.origin.x + kCornerRadius, rect.origin.y + rect.size.height);
	
	// Finish with the bottom left.
	CGPathAddArcToPoint(
						path, NULL,
						rect.origin.x, rect.origin.y + rect.size.height,
						rect.origin.x, rect.origin.y + rect.size.height - kCornerRadius,
						kCornerRadius
						);
	
	// draw line back to upper left. 
	CGPathAddLineToPoint(path, NULL, rect.origin.x, rect.origin.y + kCornerRadius);

	// Create the gradient of the bubble.
	CGFloat colors[8] = {
		1.0,  1.0,  1.0,  0.83,  // #FFFFFF 83% alpha.
		0.83, 0.83, 0.83, 0.83   // #D4D4D4 83% alpha.
	};
	CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
	CGGradientRef gradient = CGGradientCreateWithColorComponents(colorSpace, colors, NULL, 2);
	CGColorSpaceRelease(colorSpace);
	
	// Fill the new path with our gradient.
	CGContextSaveGState(context);
	CGContextAddPath(context, path);
	CGContextClip(context);
	CGContextDrawLinearGradient(context, gradient, CGPointMake(0, 0), CGPointMake(0, CGRectGetHeight(rect) + kChevronHeight), 0);
	CGContextRestoreGState(context);
	
	// Set the stroke color.
	CGContextAddPath(context, path);
	CGFloat color[4] = { 0.6, 0.6, 0.6, 1.0 };  // #999999 100% alpha.
	CGContextSetStrokeColor(context, color);
	
	// Stroke our path.
	CGContextStrokePath(context);
	
	// Cleanup.
	CGPathRelease(path);
	CGGradientRelease(gradient);
	
	// Draw the title.
	CGContextSetFillColorWithColor(context, [UIColor blackColor].CGColor);
	[[_annotation title] drawInRect:CGRectMake(kBuffer, kBuffer, rect.size.width - kBuffer * 2 - _calloutAccessoryImage.size.width, 400)
						   withFont:[UIFont boldSystemFontOfSize:kTitleFontSize]
					  lineBreakMode:UILineBreakModeWordWrap];
	
	NSString* subTitle = nil;
	if ([_annotation respondsToSelector:@selector(subtitle)]) {
		subTitle = [_annotation subtitle];
	}
	if(nil != subTitle)
	{
		// get the size of the text that was drawn for the title
		CGSize titleSize = [[_annotation title] sizeWithFont:[UIFont boldSystemFontOfSize:kTitleFontSize] 
										   constrainedToSize:CGSizeMake(kCalloutWidth - kBuffer * 3 - _calloutAccessoryImage.size.width, 400) 
											   lineBreakMode:UILineBreakModeWordWrap];
		
		// draw the subtitle below the title
		CGSize subTitleSize = [subTitle sizeWithFont:[UIFont systemFontOfSize:kSubTitleFontSize]
								   constrainedToSize:CGSizeMake(kCalloutWidth - kBuffer * 3 - _calloutAccessoryImage.size.width, 400)
									   lineBreakMode:UILineBreakModeWordWrap];
		
		
		CGRect subTitleRect = CGRectMake(kBuffer, titleSize.height + kBuffer, subTitleSize.width, subTitleSize.height);
		[subTitle drawInRect:subTitleRect withFont:[UIFont systemFontOfSize:kSubTitleFontSize] lineBreakMode:UILineBreakModeWordWrap];
		 
	 }
	
	
	CGRect accessoryRect = [self rectForAccessory];
	
	// draw the callout accessory
	[_calloutAccessoryImage drawInRect:accessoryRect];
	
}

-(CGRect) rectForAccessory
{
	
	CGSize size = [[_annotation title] sizeWithFont:[UIFont boldSystemFontOfSize:kTitleFontSize] 
								  constrainedToSize:CGSizeMake(kCalloutWidth - kBuffer * 3 - _calloutAccessoryImage.size.width, 400) 
									  lineBreakMode:UILineBreakModeWordWrap];
	
	NSString* subTitle = [_annotation subtitle];
	
	if(nil != subTitle)
	{
		CGSize subTitleSize = [subTitle sizeWithFont:[UIFont systemFontOfSize:kSubTitleFontSize]
								   constrainedToSize:CGSizeMake(kCalloutWidth - kBuffer * 3 - _calloutAccessoryImage.size.width, 400)
									   lineBreakMode:UILineBreakModeWordWrap];
		if (subTitleSize.width > size.width) {
			size.width = subTitleSize.width;
		}
	}
	
	CGRect rect = CGRectMake(size.width + kBuffer * 2, (self.frame.size.height - kChevronHeight - _calloutAccessoryImage.size.height) / 2,
							 _calloutAccessoryImage.size.width, _calloutAccessoryImage.size.height);
	
	return rect;
}

@end
