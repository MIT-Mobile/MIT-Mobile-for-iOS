#import "MITMapAnnotationCalloutView.h"
#import "MITMapView.h"
#import "MITMapAnnotationView.h"

static const CGFloat kCalloutWidth = 275;
static const CGFloat kBuffer = 10;
static const CGFloat kTitleFontSize = 16;
static const CGFloat kSubTitleFontSize = 12;

@interface MITMapAnnotationCalloutView(Private) 

- (void)setupSubviews;

@end


@implementation MITMapAnnotationCalloutView
@synthesize annotationView = _annotationView;
@synthesize mapView = _mapView;

- (id)initWithAnnotationView:(MITMapAnnotationView *)annotationView mapView:(MITMapView*)mapView
{
	self = [super initWithFrame:CGRectMake(10, 150, 275, 125)];
	if (self) {
		self.mapView = mapView;
		self.annotationView = annotationView;
        
        self.titleLabel.text = [self.annotationView.annotation title];
        self.titleLabel.font = [UIFont boldSystemFontOfSize:kTitleFontSize];
        self.titleLabel.numberOfLines = 0;
        self.titleLabel.lineBreakMode = UILineBreakModeWordWrap;
        self.titleLabel.textColor = [UIColor darkTextColor];
        
        self.detailLabel.text = [self.annotationView.annotation subtitle];
        self.detailLabel.font = [UIFont systemFontOfSize:kSubTitleFontSize];
        self.detailLabel.numberOfLines = 0;
        self.detailLabel.lineBreakMode = UILineBreakModeWordWrap;
        self.detailLabel.textColor = [UIColor lightGrayColor];
        
        [self sizeToFit];
	}
	
	return self;
}

/*
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
	
	
	self.frame = CGRectMake(self.frame.origin.x, self.frame.origin.y,
							size.width + kBuffer * 3 + calloutImage.size.width, size.height);
}*/

/*
- (CGSize)sizeThatFits:(CGSize)size {
    size.height = MAX(size.height,125);
    size.width = MAX(MIN(size.width,kCalloutWidth),kCalloutWidth);
    
    
    NSString *title = @"";
    NSString *detail = @"";
    if (self.annotationView.annotation) {
        id<MKAnnotation> annotation = self.annotationView.annotation;
        title = [annotation title];
        detail = [annotation subtitle];
    }
    
    CGSize titleSize = [title sizeWithFont:[ constrainedToSize:<#(CGSize)#> lineBreakMode:<#(NSLineBreakMode)#>]
}

- (void)drawRect:(CGRect)rect
{
	CGContextRef context = UIGraphicsGetCurrentContext();

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
*/

@end
