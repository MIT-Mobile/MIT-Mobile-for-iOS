
#import "RouteView.h"
#import "ShuttleRoute.h"
#import "MITMapView.h"

@implementation RouteView
@synthesize map = _map;

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}


- (void)drawRect:(CGRect)rect 
{
/*
	// get the context 
	CGContextRef c = UIGraphicsGetCurrentContext();	
	
	// draw all the segments of all the routes. 
	for (ShuttleRoute* route in _map.routes)
	{
		CGContextSetLineWidth(c, route.lineWidth);
		CGContextSetStrokeColorWithColor(c, route.lineColor.CGColor);
		
		// move to the first point in this route
		if (route.pathLocations.count > 0) 
		{
			
			
			CGPoint firstPoint = [_map screenPointForCoordinate:[[route.pathLocations objectAtIndex:0] coordinate]];
			
			
			//CGContextBeginPath(c);
			CGContextMoveToPoint(c, firstPoint.x, firstPoint.y);
			
			for(CLLocation* location in route.pathLocations)
			{
				CGPoint point = [_map screenPointForCoordinate:location.coordinate];	
				
				CGContextAddLineToPoint(c, point.x, point.y);
			}
			
			CGContextStrokePath(c);
		}
		///CGContextClosePath(c);
		//CGContextStrokePath(c);
	}
	*/
}


- (void)dealloc {
    [super dealloc];
}


@end
