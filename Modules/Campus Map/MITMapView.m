#import "MITMapView.h"
#import "MapLevel.h"
#import "MITMapUserLocation.h"
#import "MITMapSearchResultAnnotation.h"
#import "NSString+SBJSON.h"
#import "RouteView.h"
#import "MITMapAnnotationCalloutView.h"
#import "CalendarEventMapAnnotation.h"
#import "ShuttleLocation.h"
#import "ShuttleStopMapAnnotation.h"
#import "MapTileOverlay.h"

@class MITMapAnnotationCalloutView;
@class CalendarEventMapAnnotation;

// if the map is tracking user location but there are no annotations
// on the map (including MKUserLocation), the map will spontaneously
// move to the north pole.
// this class a is hack to keep the map view in place
@interface InvisibleAnnotation : NSObject <MKAnnotation>

@property (nonatomic, readonly) CLLocationCoordinate2D coordinate;

@end

@implementation InvisibleAnnotation

- (CLLocationCoordinate2D) coordinate {
    return DEFAULT_MAP_CENTER;
}

- (NSString *)title {
    return nil;
}

@end


@implementation MITMapView

@synthesize stayCenteredOnUserLocation = _stayCenteredOnUserLocation;
@synthesize delegate = _mapDelegate;
@synthesize routes = _routes;
@synthesize mapView = _mapView;

@dynamic currentAnnotation;


- (void)dealloc {
    _mapView.delegate = nil;
    [_mapView release];
	[_routes release];
    [_routePolylines release];
    [tileOverlay release];
    if (customCallOutView) {
        [customCallOutView release];
    }
    self.delegate = nil;
    [super dealloc];
}


- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) 
	{
		self.stayCenteredOnUserLocation = NO;
        _mapView = [[MKMapView alloc] initWithFrame:frame];
		_mapView.delegate = self;
        self.clipsToBounds = YES;
		
		addRemoveCustomAnnotationCombo = NO;
    }
    return self;
}

-(id) initWithCoder:(NSCoder *)aDecoder
{
	self = [super initWithCoder:aDecoder];
	if (self) {
		//[self createSubviews];
		self.stayCenteredOnUserLocation = NO;
        _mapView = [[MKMapView alloc] initWithCoder:aDecoder];
		_mapView.delegate = self;
        self.clipsToBounds = YES;
		
		addRemoveCustomAnnotationCombo = NO;
	}
	
	return self;
}

- (void)drawRect:(CGRect)rect {
    if (![_mapView isDescendantOfView:self]) {
        _mapView.autoresizingMask = self.autoresizingMask;
        _mapView.frame = rect;
        [self addSubview:_mapView];
        [self adjustCustomCallOut];
    }
    if (!tileOverlay) {
        [[MITMKProjection sharedProjection] addObserver:self];
    }
}

- (void)enableProjectedFeatures {
    // immediately add tile overlay so it is the bottommost overlay
    tileOverlay = [[MapTileOverlay alloc] init];
    [self addTileOverlay];
    //[_mapView addOverlay:tileOverlay];
}

- (void)fixateOnCampus {
    InvisibleAnnotation *annotation = [[[InvisibleAnnotation alloc] init] autorelease];
    [_mapView addAnnotation:annotation];
}

#pragma mark Property forwarding

- (CGFloat)zoomLevel {
	return log(360.0f / _mapView.region.span.longitudeDelta) / log(2.0f) - 1;
}

- (void)setZoomLevel:(CGFloat)zoomLevel {
    CGFloat longitudeDelta = 360.0f / pow(2.0f, zoomLevel + 1);
    CGFloat latitudeDelta = longitudeDelta;
    MKCoordinateRegion region = _mapView.region;
    region.span = MKCoordinateSpanMake(latitudeDelta, longitudeDelta);
    _mapView.region = region;
}

- (CLLocationCoordinate2D)centerCoordinate {
    return _mapView.centerCoordinate;
}

- (void)setCenterCoordinate:(CLLocationCoordinate2D)coord {
    _mapView.centerCoordinate = coord;
}

- (void)setCenterCoordinate:(CLLocationCoordinate2D)coord animated:(BOOL)animated {
    [_mapView setCenterCoordinate:coord animated:animated];
}

- (MKCoordinateRegion)region {
    return _mapView.region;
}

- (void)setRegion:(MKCoordinateRegion)theRegion {
    _mapView.region = theRegion;
}

- (BOOL)scrollEnabled {
    return _mapView.scrollEnabled;
}

- (void)setScrollEnabled:(BOOL)enabled {
    _mapView.scrollEnabled = enabled;
}

- (BOOL)showsUserLocation {
    return _mapView.showsUserLocation;
}

- (void)setShowsUserLocation:(BOOL)shows {
    _mapView.showsUserLocation = shows;
}

- (MKUserLocation *)userLocation {
    return _mapView.userLocation;
}

- (CGPoint)convertCoordinate:(CLLocationCoordinate2D)coordinate toPointToView:(UIView *)view {
    return [_mapView convertCoordinate:coordinate toPointToView:view];
}

- (CLLocationCoordinate2D)convertPoint:(CGPoint)point toCoordinateFromView:(UIView *)view {
    return [_mapView convertPoint:point toCoordinateFromView:view];
}

#pragma mark Annotations

- (NSArray*)annotations {
	return [_mapView annotations];
}

- (void)addAnnotation:(id<MKAnnotation>)anAnnotation {
    [_mapView addAnnotation:anAnnotation];
}

- (void)addAnnotations:(NSArray *)annotations {
    [_mapView addAnnotations:annotations];
}

// programmatically select and recenter on an annotation. Must be in our list of annotations
- (void)selectAnnotation:(id<MKAnnotation>) annotation{
	[_mapView selectAnnotation:annotation animated:YES];
}

- (void)selectAnnotation:(id<MKAnnotation>)annotation animated:(BOOL)animated withRecenter:(BOOL)recenter{
    if (recenter) {
        [_mapView setCenterCoordinate:annotation.coordinate animated:animated];
    }
	[_mapView selectAnnotation:annotation animated:animated];
}

- (void)deselectAnnotation:(id<MKAnnotation>)annotation animated:(BOOL)animated {
    [_mapView deselectAnnotation:annotation animated:animated];
}

- (void)removeAllAnnotations:(BOOL)includeUserLocation {
    if (includeUserLocation) {
        [_mapView removeAnnotations:_mapView.annotations];
    } else {
        NSArray *existingAnnotations = [NSArray arrayWithArray:_mapView.annotations];
        for (id <MKAnnotation> anAnnotation in existingAnnotations) {
            if (![anAnnotation isKindOfClass:[MKUserLocation class]] && ![anAnnotation isKindOfClass:[InvisibleAnnotation class]]) {
                [_mapView removeAnnotation:anAnnotation];
            }
        }
    }
}

- (void)removeAnnotation:(id<MKAnnotation>)annotation {
    [_mapView removeAnnotation:annotation];
}

- (void)removeAnnotations:(NSArray *)annotations {
    [_mapView removeAnnotations:annotations];
}

-(void) refreshCallout
{	
	for(id<MKAnnotation> annotation in _mapView.selectedAnnotations) {
        // TODO: don't we want MITMapView to handle this?
		MKAnnotationView *annoView = [_mapView viewForAnnotation:annotation];
		if (nil != annoView) {
            
			if (annoView.selected) {
                [_mapView deselectAnnotation:annotation animated:NO];
				[_mapView selectAnnotation:annotation animated:NO];
            }
		}
	}
}


-(void) positionAnnotationView:(MITMapAnnotationView*)annotationView
{
	
	BOOL isSelected = NO;
	
	if ([_mapView.selectedAnnotations containsObject:annotationView.annotation])
		isSelected = YES;
    
	if (nil != annotationView.annotation) {
		if ([_mapView.annotations containsObject:annotationView.annotation]) {			
			[_mapView removeAnnotation:annotationView.annotation];	
		}
		[_mapView addAnnotation:annotationView.annotation];
	}
	
	if (isSelected == YES)
		[_mapView selectAnnotation:annotationView.annotation animated:NO];
	
	
}

- (id<MKAnnotation>) currentAnnotation {
	//return _currentCallout.annotation;
	
	if (nil != [_mapView.selectedAnnotations lastObject])
		return [_mapView.selectedAnnotations lastObject];
	else
		return nil;
    
}


- (void) adjustCustomCallOut {
	
	if (nil != customCallOutView) {
        id<MKAnnotation>annotation = customCallOutView.annotationView.annotation;
		CGPoint point =  [_mapView convertCoordinate:annotation.coordinate toPointToView:self];
		CGFloat width =  customCallOutView.frame.size.width;
		CGFloat height = customCallOutView.frame.size.height;

        // if anchorPoint is centered, this will be zero
        // if anchorPoint is lower (> 0.5), this will be positive which makes the callout start higher
        CGFloat heightAdjustment = (customCallOutView.annotationView.layer.anchorPoint.y - 0.5) * 2;

        CGRect frame = CGRectMake(floor(point.x - (width/2.0)),
                                  floor(point.y - height - (customCallOutView.annotationView.frame.size.height * heightAdjustment)),
                                  width, height);
        
        customCallOutView.frame = frame;
		
		[self addSubview:customCallOutView];
	}
}

#pragma mark Overlays

- (void)addRoute:(id<MITMapRoute>)route
{
	if (nil == _routes) {
		_routes = [[NSMutableArray alloc] initWithCapacity:1];
	}
    NSInteger routeIndex = [_routes count];
	[_routes addObject:route];

	if ([route respondsToSelector:@selector(annotations)]) {
        // add any annotations associated with this route
        [_mapView addAnnotations:[route annotations]];
    }
    
    if ([route pathLocations] != nil) {
        // add overlay
        NSInteger count = [[route pathLocations] count];
        CLLocationCoordinate2D *pointArr = malloc(sizeof(CLLocationCoordinate2D) * count);
        
        for (int idx = 0; idx < count; idx++){
            CLLocation *location = [[route pathLocations] objectAtIndex:idx];
            CLLocationCoordinate2D coordinate = location.coordinate;
            pointArr[idx] = coordinate;
        }
        
        MKPolyline *polyline = [MKPolyline polylineWithCoordinates:pointArr count:count];
        free(pointArr);
        
        if (!_routePolylines) {
            _routePolylines = [[NSMutableDictionary alloc] initWithCapacity:1];
        }
        [_routePolylines setObject:polyline forKey:[NSNumber numberWithInt:routeIndex]];
        
        [_mapView addOverlay:polyline];
    }
}

- (void)removeAllRoutes {
    for (MKPolyline *polyline in [_routePolylines allValues]) {
        [_mapView removeOverlay:polyline];
    }
    for (id<MITMapRoute> route in _routes) {
        if ([route respondsToSelector:@selector(annotations)]) {
            [_mapView removeAnnotations:[route annotations]];
        }
    }
    [_routes removeAllObjects];
    [_routePolylines removeAllObjects];
}

/*
 *  this method can easily fail if they keys for the polylines get
 *  out of synch not sure the best way to fix this.
 */
- (void)removeRoute:(id<MITMapRoute>) route
{
    if ([route respondsToSelector:@selector(annotations)]) {
        [_mapView removeAnnotations:[route annotations]];
    }

    NSNumber *key = [NSNumber numberWithInt:[_routes indexOfObject:route]];
    MKPolyline *polyline = [_routePolylines objectForKey:key];
    [_mapView removeOverlay:polyline];
    [_routePolylines removeObjectForKey:key];
	[_routes removeObject:route];
}

- (void)addTileOverlay {
    if (tileOverlay && ![_mapView.overlays containsObject:tileOverlay]) {
        if ([_mapView.overlays count]) {
            [_mapView insertOverlay:tileOverlay atIndex:0];
        } else {
            [_mapView addOverlay:tileOverlay];
        }
    }
}

- (void)removeTileOverlay {
    [_mapView removeOverlay:tileOverlay];
}

- (void)removeAllOverlays {
    [_mapView removeOverlays:_mapView.overlays];
}

- (MKCoordinateRegion)regionForRoute:(id<MITMapRoute>)route {
	double minLat = 90;
	double maxLat = -90;
	double minLon = 180;
	double maxLon = -180;
    
    for (CLLocation *aLocation in route.pathLocations) {
        CLLocationCoordinate2D coordinate = aLocation.coordinate;
		if (coordinate.latitude < minLat) {
			minLat = coordinate.latitude;
		}
		if (coordinate.latitude > maxLat) {
			maxLat = coordinate.latitude;
		}
		if(coordinate.longitude < minLon) {
			minLon = coordinate.longitude;
		}
		if (coordinate.longitude > maxLon) {
			maxLon = coordinate.longitude;
		}
    }
    
	CLLocationCoordinate2D center;
	center.latitude = minLat + (maxLat - minLat) / 2;
	center.longitude = minLon + (maxLon - minLon) / 2;
	
	double latDelta = maxLat - minLat;
	double lonDelta = maxLon - minLon; 
	
	MKCoordinateSpan span = MKCoordinateSpanMake(latDelta + latDelta / 4, lonDelta + lonDelta / 4);
	MKCoordinateRegion region = MKCoordinateRegionMake(center, span);
	
	return region;
}

- (MKCoordinateRegion)regionForAnnotations:(NSArray *)annotations {
	double minLat = 90;
	double maxLat = -90;
	double minLon = 180;
	double maxLon = -180;
    
    for (id<MKAnnotation> anAnnotation in annotations) {
        CLLocationCoordinate2D coordinate = anAnnotation.coordinate;
		if (coordinate.latitude < minLat) {
			minLat = coordinate.latitude;
		}
		if (coordinate.latitude > maxLat) {
			maxLat = coordinate.latitude;
		}
		if(coordinate.longitude < minLon) {
			minLon = coordinate.longitude;
		}
		if (coordinate.longitude > maxLon) {
			maxLon = coordinate.longitude;
		}
    }
    
	CLLocationCoordinate2D center;
	center.latitude = minLat + (maxLat - minLat) / 2;
	center.longitude = minLon + (maxLon - minLon) / 2;
	
	double latDelta = maxLat - minLat;
	double lonDelta = maxLon - minLon; 
	
	MKCoordinateSpan span = MKCoordinateSpanMake(latDelta + latDelta / 4, lonDelta + lonDelta / 4);
	MKCoordinateRegion region = MKCoordinateRegionMake(center, span);
	
	return region;
}


#pragma mark MKMapView delegation
/*
// this is being called by other classes
- (void)didUpdateUserLocation:(MKUserLocation *)userLocation {
    // this is the proper delegate method
    [self mapView:_mapView didUpdateUserLocation:userLocation];
}
*/

- (void)mapView:(MKMapView *)mapView didUpdateUserLocation:(MKUserLocation *)userLocation {
    // there are better ways to do this, this is just a lazy solution
    // http://stackoverflow.com/questions/214416/set-the-location-in-iphone-simulator
#if TARGET_IPHONE_SIMULATOR
    CLLocationCoordinate2D coord;
    switch (arc4random() % 4) {
        case 0:
            coord.latitude = 42.3614;
            coord.longitude = -71.0967;
            DLog(@"Pretending that we are in n42");
            break;
        case 1:
            coord.latitude = 42.3629;
            coord.longitude = -71.0862;
            DLog(@"Pretending that we are in kendall square");
            break;
        default:
            coord.latitude = 42.3948;
            coord.longitude = -71.1446;
            DLog(@"Pretending that we are in alewife");
            break;
    }
    
    CLLocation *newLocation = [[[CLLocation alloc] initWithLatitude:coord.latitude longitude:coord.longitude] autorelease];
#else
    CLLocation *newLocation = userLocation.location;
#endif
    if ([self.delegate respondsToSelector:@selector(mapView:didUpdateUserLocation:)]) {
        [self.delegate mapView:self didUpdateUserLocation:newLocation];
    }
    else if (self.showsUserLocation && self.stayCenteredOnUserLocation) {
        if (CLLocationCoordinate2DIsValid(newLocation.coordinate)) {
            _mapView.centerCoordinate = newLocation.coordinate;
        }
    }
}

- (void)mapView:(MKMapView *)mapView didFailToLocateUserWithError:(NSError *)error {
    if ([self.delegate respondsToSelector:@selector(locateUserFailed)]) {
        [self.delegate locateUserFailed:self];
    }
}

/*
- (void)mapView:(MKMapView *)mapView didAddOverlayViews:(NSArray *)overlayViews {

}
*/

- (MKOverlayView *)mapView:(MKMapView *)mapView viewForOverlay:(id <MKOverlay>)overlay
{
	if ([self.delegate respondsToSelector:@selector(mapView:viewForOverlay:)]) 
		return [self.delegate mapView:self viewForOverlay:overlay];
	
    if (overlay == tileOverlay) {
        MapTileOverlayView *overlayView = [[[MapTileOverlayView alloc] initWithOverlay:overlay] autorelease];
        return overlayView;
    }
    else if ([overlay isKindOfClass:[MKPolyline class]]) {
        MKPolylineView *polylineView = nil;
        for (NSNumber *index in [_routePolylines allKeys]) {
            MKPolyline *polyline = [_routePolylines objectForKey:index];
            if (polyline == overlay) {
                polylineView = [[[MKPolylineView alloc] initWithPolyline:polyline] autorelease];
                id<MITMapRoute> mapRoute = [_routes objectAtIndex:[index intValue]];
                polylineView.fillColor = [mapRoute fillColor];
                polylineView.strokeColor = [mapRoute strokeColor];
                polylineView.lineWidth = [mapRoute lineWidth];
                polylineView.lineDashPattern = [mapRoute lineDashPattern];
            }
        }
        return polylineView;
    }
    
	return nil;
}

- (void)mapView:(MKMapView *)mapView regionDidChangeAnimated:(BOOL)animated {

	if ([self.delegate respondsToSelector:@selector(mapViewRegionDidChange:)]) {
		[self.delegate mapViewRegionDidChange:self];
	}
	[self adjustCustomCallOut];
}

- (void)mapView:(MKMapView *)mapView regionWillChangeAnimated:(BOOL)animated {
	if (nil != customCallOutView) {
		[customCallOutView removeFromSuperview];
	}
	if ([self.delegate respondsToSelector:@selector(mapViewRegionWillChange:)]) 
		[self.delegate mapViewRegionWillChange:self];
}

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id <MKAnnotation>)annotation {
    MKAnnotationView *annotationView = nil;
    if (annotation == mapView.userLocation) {
        ; // return nil for "blue dot"
	}
    else if ([annotation isKindOfClass:[InvisibleAnnotation class]]) {
        annotationView = [[[MKAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:@"invisible"] autorelease];
        annotationView.image = [UIImage imageNamed:@"map/invisible-pixel.png"];
    }
    else if ([self.delegate respondsToSelector:@selector(mapView:viewForAnnotation:)]) {
		annotationView = [self.delegate mapView:self viewForAnnotation:annotation];
	}
    else {
        MITPinAnnotationView *pinView = [[[MITPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:@"pin"] autorelease];
        pinView.animatesDrop = YES;
        annotationView = pinView;
    }
    return annotationView;
}

- (void)mapView:(MKMapView *)mapView didAddAnnotationViews:(NSArray *)views
{
    NSArray *sortedViews = [views sortedArrayUsingComparator:^NSComparisonResult(id a, id b) {
        MITPinAnnotationView *view1 = (MITPinAnnotationView *)a;
        MITPinAnnotationView *view2 = (MITPinAnnotationView *)b;
        
        CGFloat x1 = view1.frame.origin.x;
        CGFloat x2 = view2.frame.origin.x;
        
        if (x1 < x2) return NSOrderedAscending;
        if (x2 < x1) return NSOrderedDescending;
        
        return NSOrderedSame;
    }];
    
    // animation completion callback
    void (^autoSelectLonelyAnnotation)(BOOL) = ^(BOOL finished) {
        NSMutableArray *annotations = [[mapView.annotations mutableCopy] autorelease];
        NSInteger count = [annotations count];
        
        if (count > 3
        || mapView.userInteractionEnabled == NO 
        || [mapView.selectedAnnotations count] > 0) {
            return;
        }
        
        NSIndexSet *selectableIndexes = [annotations indexesOfObjectsPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
            if ([obj isKindOfClass:[MKUserLocation class]] 
            || [obj isKindOfClass:[InvisibleAnnotation class]]) {
                return NO;
            } else {
                return YES;
            }
        }];
        
        if ([selectableIndexes count] == 1) {
            id<MKAnnotation> annotation = [annotations objectAtIndex:[selectableIndexes firstIndex]];
            [mapView selectAnnotation:annotation animated:YES];
        }
    };
    
    // animate pins dropping
    CGFloat pinDropDuration = 0.7;
    CGFloat pinDropDelay = 0;
    CGFloat pinDropInterval = 0.07;
    
    NSInteger i = 0, limit = [sortedViews count];
    for (MKAnnotationView *aView in sortedViews) {
        i++;
        if ([aView isKindOfClass:[MITPinAnnotationView class]]) {
            MITPinAnnotationView *pin = (MITPinAnnotationView *)aView;
            if (pin.animatesDrop) {
                CGRect dstFrame = pin.frame;
                CGRect srcFrame = pin.frame;
                srcFrame.origin.y -= mapView.frame.size.height;
                pin.frame = srcFrame;
                
                // only call completion when the last pin lands
                void (^completionBlock)(BOOL) = (i < limit) ? nil : autoSelectLonelyAnnotation;
                // ease in provides the same fake gravity seen in Maps.app
                [UIView animateWithDuration:pinDropDuration 
                                      delay:pinDropDelay 
                                    options:UIViewAnimationOptionCurveEaseIn 
                                 animations:^(void) { pin.frame = dstFrame; }
                                 completion:completionBlock];
                pinDropDelay += pinDropInterval;
            }
        }
    }
    
    if ([self.delegate respondsToSelector:@selector(mapView:didAddAnnotationViews:)]) {
        [self.delegate mapView:self didAddAnnotationViews:views];
    }
}

- (void)mapView:(MKMapView *)mapView didSelectAnnotationView:(MKAnnotationView *)view {

	if ([self.delegate respondsToSelector:@selector(mapView:annotationSelected:)]) {
		[self.delegate mapView:self annotationSelected:view.annotation];
	}

    // TODO: all delegates that currently implement -annotationSelected:
    // currently have empty implementations or only save state.
    // we might want customCalloutView to be the default but allow
    // classes to override it using -annotationSelected:

    if ([view isKindOfClass:[MITMapAnnotationView class]] && ((MITMapAnnotationView *)view).showsCustomCallout) {
        if (nil != customCallOutView) {
            [customCallOutView removeFromSuperview];
            [customCallOutView release];
            addRemoveCustomAnnotationCombo = YES;
        }
        customCallOutView = [[MITMapAnnotationCalloutView alloc] initWithAnnotationView:(MITMapAnnotationView *)view mapView:self];
        
        // this calls [self adjustCustomCallOut] as a side effect
        [_mapView setCenterCoordinate:view.annotation.coordinate animated:YES];
        //[self adjustCustomCallOut];
    }
}

- (void)mapView:(MKMapView *)mapView didDeselectAnnotationView:(MKAnnotationView *)view {
    if ((nil != customCallOutView) && (addRemoveCustomAnnotationCombo == NO)) {
        [customCallOutView removeFromSuperview];
        [customCallOutView release];
        customCallOutView = nil;
    }
    else if (addRemoveCustomAnnotationCombo == YES) {
        addRemoveCustomAnnotationCombo = NO;
    }
}

- (void)mapView:(MKMapView *)mapView annotationView:(MKAnnotationView *)view calloutAccessoryControlTapped:(UIControl *)control
{
	if ([view isKindOfClass:[MITMapAnnotationView class]]
        && [self.delegate respondsToSelector:@selector(mapView:annotationViewCalloutAccessoryTapped:)])
    {
        [self.delegate mapView:self annotationViewCalloutAccessoryTapped:(MITMapAnnotationView *)view];
	}
}

@end