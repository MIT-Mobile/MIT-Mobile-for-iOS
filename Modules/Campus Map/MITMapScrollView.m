
#import "MITMapScrollView.h"
#import "MITMapView.h"

#define kDoubleTapThreshold -0.30

@implementation MITMapScrollView


- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}


- (void)drawRect:(CGRect)rect {
    // Drawing code
}


- (void)dealloc {
    [super dealloc];
	
	[_lastTouchDate release];
}

-(void) touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
	[super touchesEnded:touches withEvent:event];

	// if there are two touches, it may have been a two fingered tap to zoom out
	if ([event allTouches].count == 2) 
	{
		CGFloat newScale = self.maximumZoomScale;
		CGFloat currentScale = self.zoomScale;
		
		while (currentScale - newScale < 1.0 && newScale > self.minimumZoomScale) {
			newScale /= 2;
		}
		
		//newScale += .01;
		
		if (newScale < self.minimumZoomScale) {
			newScale = self.minimumZoomScale;
		}
		
		[self setZoomScale:newScale animated:YES];
	}
	else if(touches.count == 1)
	{
		// look for double taps
		UITouch* touch = [touches anyObject];
		if (touch.tapCount > 1) 
		{
			[UIView cancelPreviousPerformRequestsWithTarget:self.superview selector:@selector(hideCallout) object:nil];
			
			MITMapView* mapView = (MITMapView*)[self superview];
			mapView.stayCenteredOnUserLocation = NO;
			
			// we want to zoom in to just below the next zoom level
			// determine our highest map level
			CGFloat newZoom = self.maximumZoomScale;
			CGFloat currentZoom = self.zoomScale;
			
			while (newZoom > currentZoom) {
				newZoom /= 2;
			}
			
			newZoom *= 2;

						
			// determine the new size of the visible area in pixels
			CGSize visibleSize;
			visibleSize.height = self.frame.size.height / newZoom;
			visibleSize.width = self.frame.size.width / newZoom;
			
			CGPoint touchedPoint = [touch locationInView:self];
			touchedPoint.x = touchedPoint.x / currentZoom;
			touchedPoint.y = touchedPoint.y / currentZoom;
			
			CGRect rect = CGRectMake(touchedPoint.x - visibleSize.width / 2, touchedPoint.y - visibleSize.height / 2, visibleSize.width, visibleSize.height);
			
			[self zoomToRect:rect animated:YES];
			

			
		}
		else
		{
			// hide any displayed callouts
			MITMapView* mapView = (MITMapView*)[self superview];
			[mapView performSelector:@selector(hideCallout) withObject:nil afterDelay:0.30];
		}

	}

	
}

/*
-(BOOL) touchesShouldBegin:(NSSet *)touches withEvent:(UIEvent *)event inContentView:(UIView *)view
{
	if ([event allTouches].count == 2) 
	{
		CGFloat newScale = self.zoomScale / 2;
		if (newScale < self.minimumZoomScale) {
			newScale = self.minimumZoomScale;
		}
		
		[self setZoomScale:newScale animated:YES];
	}
	
	return YES;
}
 */

-(void) touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
	//[super touchesBegan:touches withEvent:event];
	
	MITMapView* mapView = (MITMapView*)[self superview];
	if (![mapView.delegate respondsToSelector:@selector(mapView:wasTouched:)]) {
		return;
	}
	
    for (UITouch *touch in touches) {
		[mapView.delegate mapView:mapView wasTouched:touch];
    }
}
@end
