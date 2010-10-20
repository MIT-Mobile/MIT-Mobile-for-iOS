
#import "MITMapAnnotationView.h"

NSString* const kMITMapAnnotationViewTapped = @"MITMapViewAnnotationViewTouchesEnded";

@implementation MITMapAnnotationView
@synthesize annotation = _annotation;
@synthesize canShowCallout = _canShowCallout;
@synthesize mapView = _mapView;
@synthesize centeredVertically = _centeredVertically;

- (id)initWithAnnotation:(id <MKAnnotation>)annotation
{
	if(self = [super init])
	{
		self.annotation = annotation;
		self.multipleTouchEnabled = YES;
	}
	
	return self;
}

- (void)drawRect:(CGRect)rect {
    // Drawing code
}


- (void)dealloc {
	self.annotation = nil;
	self.mapView = nil;
	
    [super dealloc];
}

- (void)touchesEnded:(NSSet*)touches withEvent:(UIEvent*)event
{
	if (event.allTouches.count > 1) 
	{
		[super touchesEnded:touches withEvent:event];
	}
	else
	{
		[[NSNotificationCenter defaultCenter] postNotificationName:kMITMapAnnotationViewTapped object:self];		
	}


}

-(void) touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
	if (event.allTouches.count > 1) 
	{	
		[super touchesBegan:touches withEvent:event];		
	}

}


@end
