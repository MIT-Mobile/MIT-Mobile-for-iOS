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

- (void)setupSubviews;

@end


@implementation MITMapAnnotationCalloutView

@synthesize annotationView = _annotationView, mapView = _mapView;

- (id)initWithAnnotationView:(MITMapAnnotationView *)annotationView mapView:(MITMapView*)mapView
{
	self = [super initWithFrame:CGRectMake(10, 150, 275, 125)];
	if (self) {
		_mapView = mapView;
		self.annotationView = annotationView;
		self.opaque = NO;
		[self setupSubviews];
	}
	
	return self;
}

- (void)dealloc
{
    self.annotationView = nil;
	[super dealloc];
}
/*
- (void)setOrigin:(CGPoint)origin
{
	CGRect frame = self.frame;
	frame.origin.x = origin.x;
	frame.origin.y = origin.y - frame.size.height / 2;
	[self setNeedsDisplay];
}
*/
- (void)setupSubviews
{
    UIImage *calloutImage = [UIImage imageNamed:@"map/map_disclosure.png"];
	
	// setting the annotation determines the frame based on the content of the annotation.
	CGSize size = [[_annotationView.annotation title] sizeWithFont:[UIFont boldSystemFontOfSize:kTitleFontSize] 
					constrainedToSize:CGSizeMake(kCalloutWidth - kBuffer * 3 - calloutImage.size.width, 400) 
						lineBreakMode:UILineBreakModeWordWrap];
	
	size.height += kBuffer * 2; // buffer for above and below the title
	
	if ([_annotationView.annotation respondsToSelector:@selector(subtitle)]) {
		NSString *subtitle = [_annotationView.annotation subtitle];
        if(subtitle) {
            CGSize subSize = [subtitle sizeWithFont:[UIFont systemFontOfSize:kSubTitleFontSize] 
						constrainedToSize:CGSizeMake(kCalloutWidth - kBuffer * 3 - calloutImage.size.width, 400) 
							lineBreakMode:UILineBreakModeWordWrap];
		
            size.height += (subSize.height);
            if(subSize.width > size.width)
                size.width = subSize.width;
        }
	}
	
	// add the chevron height
	size.height += kChevronHeight;
	
	self.frame = CGRectMake(self.frame.origin.x, self.frame.origin.y,
							size.width + kBuffer * 3 + calloutImage.size.width, size.height);
	
	UIButton *accessoryButton = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
	accessoryButton.exclusiveTouch = YES;
	accessoryButton.enabled = YES;
	[accessoryButton addTarget:self 
						action:@selector(calloutAccessoryTapped:) 
			  forControlEvents:UIControlEventTouchUpInside | UIControlEventTouchCancel];
	
	accessoryButton.frame = CGRectMake(self.bounds.size.width - accessoryButton.frame.size.width - 10, 
									   round((self.bounds.size.height - kChevronHeight - accessoryButton.frame.size.height) / 2.0), 
									   accessoryButton.frame.size.width, 
									   accessoryButton.frame.size.height);
    
	[self addSubview:accessoryButton];
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
	
	CGFloat midX = round((rect.origin.x + rect.size.width) / 2);
	CGFloat halfChevWidth = round(kChevronWidth / 2);
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
    UIImage *calloutImage = [UIImage imageNamed:@"map/map_disclosure.png"];

	CGContextSetFillColorWithColor(context, [UIColor blackColor].CGColor);
	[[_annotationView.annotation title] drawInRect:CGRectMake(kBuffer, kBuffer, rect.size.width - kBuffer * 2 - calloutImage.size.width, 400)
						   withFont:[UIFont boldSystemFontOfSize:kTitleFontSize]
					  lineBreakMode:UILineBreakModeWordWrap];
	
	if ([_annotationView.annotation respondsToSelector:@selector(subtitle)]) {
		NSString *subTitle = [_annotationView.annotation subtitle];

		// get the size of the text that was drawn for the title
		CGSize titleSize = [[_annotationView.annotation title] sizeWithFont:[UIFont boldSystemFontOfSize:kTitleFontSize] 
                                                          constrainedToSize:CGSizeMake(kCalloutWidth - kBuffer * 3 - calloutImage.size.width, 400) 
                                                              lineBreakMode:UILineBreakModeWordWrap];
		
		// draw the subtitle below the title
		CGSize subTitleSize = [subTitle sizeWithFont:[UIFont systemFontOfSize:kSubTitleFontSize]
								   constrainedToSize:CGSizeMake(kCalloutWidth - kBuffer * 3 - calloutImage.size.width, 400)
									   lineBreakMode:UILineBreakModeWordWrap];
		
		
		CGRect subTitleRect = CGRectMake(kBuffer, titleSize.height + kBuffer, subTitleSize.width, subTitleSize.height);
		[subTitle drawInRect:subTitleRect withFont:[UIFont systemFontOfSize:kSubTitleFontSize] lineBreakMode:UILineBreakModeWordWrap];
		 
	 }

}


- (void)calloutAccessoryTapped:(id)sender {
    // _mapView.mapView is the MKMapView object attached to the MITMapView
    [_mapView mapView:_mapView.mapView annotationView:self.annotationView calloutAccessoryControlTapped:sender];
}

@end
