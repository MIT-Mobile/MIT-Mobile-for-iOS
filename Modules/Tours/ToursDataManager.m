#import "ToursDataManager.h"
#import "CoreDataManager.h"
#import "CampusTourSideTrip.h"
#import "TourSiteOrRoute.h"
#import "CampusTour.h"
#import "MITMapRoute.h"
#import "MorseCodePattern.h"
#import "TourStartLocation.h"
#import "TourLink.h"
#import "MobileRequestOperation.h"

@interface ToursDataManager (Private)

- (void)populateComponentsForTour;
- (CampusTour *)tourWithID:(NSString *)tourID;
- (TourSiteOrRoute *)tourSiteWithID:(NSString *)siteID;
- (TourSiteOrRoute *)tourRouteWithStartID:(NSString *)siteID;
- (NSManagedObject *)managedObjectWithEntityName:(NSString *)entityName predicate:(NSPredicate *)predicate;
- (void)requestTourList;
- (void)requestTour:(NSString *)tourID;
- (TourSiteOrRoute *)findSiteWithID:(NSString *)siteID;
- (TourStartLocation *)tourStartLocationWithID:(NSString *)locationID;

@end

NSString * const TourInfoLoadedNotification = @"TourInfoDidLoad";
NSString * const TourInfoFailedToLoadNotification = @"TourInfoFailedToLoad";
NSString * const TourDetailsLoadedNotification = @"TourDetailsDidLoad";
NSString * const TourDetailsFailedToLoadNotification = @"TourDetailsFailedToLoad";

@implementation ToursDataManager

static ToursDataManager *s_toursDataManager = nil;

#pragma mark Constants

+ (UIImage *)imageForVisitStatus:(TourSiteVisitStatus)visitStatus {
    switch (visitStatus) {
        case TourSiteVisited:
            return [UIImage imageNamed:@"tours/map_past.png"];
        case TourSiteVisiting:
            return [UIImage imageNamed:@"tours/map_currentstop.png"];
        case TourSiteNotVisited:
            return [UIImage imageNamed:@"tours/map_future.png"];
        default:
            return nil;
    }
}

+ (NSString *)labelForVisitStatus:(TourSiteVisitStatus)visitStatus {
    switch (visitStatus) {
        case TourSiteVisited:
            return @"Visited";
        case TourSiteVisiting:
            return @"Current stop";
        case TourSiteNotVisited:
            return @"Not yet visited";
        default:
            return nil;
    }
}

#pragma mark Public

+ (ToursDataManager *)sharedManager {
    if (s_toursDataManager == nil) {
        s_toursDataManager = [[ToursDataManager alloc] init];
        [s_toursDataManager requestTourList];
    }
    return s_toursDataManager;
}

- (BOOL)setActiveTourID:(NSString *)tourID {
    [_activeTour release];
    [_routes release];
    _routes = nil;
    [_sites release];
    _sites = nil;
    [_mapRoute release];
    _mapRoute = nil;
    
    _activeTour = [[_tours objectForKey:tourID] retain];
    if (_activeTour == nil) {
        _activeTour = [[self tourWithID:tourID] retain];
    }
    return (_activeTour != nil);
}

- (CampusTour *)activeTour {
    return _activeTour;
}

- (NSArray *)allTours {
    // TODO: this needs to be sorted when we have multiple tours
    if ([_tours count]) {
        return [_tours allValues];
    } else {
        [self requestTourList];
    }
    return nil;
}

- (void)populateComponentsForTour {
    NSMutableArray *sites = [NSMutableArray array];
    NSMutableArray *routes = [NSMutableArray array];
    
    NSSet *components = _activeTour.components;
    if (!components.count) {
        [self requestTour:_activeTour.tourID];
        return;
    }
    
	NSArray *descriptors = [NSArray arrayWithObjects:
							[NSSortDescriptor sortDescriptorWithKey:@"type" ascending:NO],       // put sites first
							[NSSortDescriptor sortDescriptorWithKey:@"sortOrder" ascending:YES], // so we ignore route sortOrder
							nil];
	NSArray *sortedComponents = [components sortedArrayUsingDescriptors:descriptors];
	TourSiteOrRoute *firstComponent = [sortedComponents objectAtIndex:0];
    if ([firstComponent.type isEqualToString:@"site"]) {
        [sites addObject:firstComponent];
    } else if ([firstComponent.type isEqualToString:@"route"]) {
        [routes addObject:firstComponent];
    }
    
    TourSiteOrRoute *currentComponent = firstComponent.nextComponent;
    while (currentComponent != firstComponent) {
        if ([currentComponent.type isEqualToString:@"site"]) {
            [sites addObject:currentComponent];
        }
        else if ([currentComponent.type isEqualToString:@"route"]) {
            [routes addObject:currentComponent];
        }
        currentComponent = currentComponent.nextComponent;
    }
    
    _routes = [[NSArray alloc] initWithArray:routes];
    _sites = [[NSArray alloc] initWithArray:sites];
}

- (NSArray *)allRoutesForTour {
    if (!_activeTour) return nil;
    
    if (!_routes) {
        [self populateComponentsForTour];
    }
    return _routes;
}

- (MITGenericMapRoute *)mapRouteForTour {
    if (!_activeTour) return nil;
    
    if (!_mapRoute) {
        NSMutableArray *pathLocations = [NSMutableArray array];
        for (TourSiteOrRoute *aRoute in [self allRoutesForTour]) {
            [pathLocations addObjectsFromArray:[aRoute pathAsArray]];
        }
        _mapRoute = [[MITGenericMapRoute alloc] init];
        UIColor *color = [UIColor colorWithRed:0.8 green:0 blue:0 alpha:1];
        _mapRoute.fillColor = color;
        _mapRoute.strokeColor = color;
        _mapRoute.pathLocations = pathLocations;
    }
    return _mapRoute;
}

- (MITGenericMapRoute *)mapRouteFromSideTripToSite:(CampusTourSideTrip *)sideTrip {
    CLLocation *source = [[CLLocation alloc] initWithLatitude:[sideTrip.latitude floatValue] longitude:[sideTrip.longitude floatValue]];
    TourSiteOrRoute *site = sideTrip.site;
    CLLocation *dest = [[CLLocation alloc] initWithLatitude:[site.latitude floatValue] longitude:[site.longitude floatValue]];
    
    NSArray *pathLocations = [NSArray arrayWithObjects:source, dest, nil];
    [source release];
    [dest release];
    MITGenericMapRoute *mapRoute = [[MITGenericMapRoute alloc] init];
    mapRoute.fillColor = [UIColor blackColor];
    mapRoute.strokeColor = [UIColor blackColor];
    mapRoute.pathLocations = pathLocations;
    MorseCodePattern *morseCode = [MorseCodePattern new];
    // MIT, M = dash dash, I = dot dot, T = dash
    [[[[[[[[morseCode dash] dash] pause] dot] dot] pause] dash] pause];
    mapRoute.lineDashPattern = [morseCode lineDashPattern];
    [morseCode release];
    //mapRoute.lineDashPattern = [NSArray arrayWithObjects:[NSNumber numberWithInt:3], [NSNumber numberWithInt:5], nil];
    mapRoute.lineWidth = 2.0;
    return [mapRoute autorelease];
}


- (NSArray *)allSitesForTour {
    if (!_activeTour) return nil;
    
    if (!_sites) {
        [self populateComponentsForTour];
    }
    return _sites;
}

/*
 *  takes an array of sites of returns
 *  an array of sites and side trips with
 *  each site followed by its N side trips
 *   
 */
- (NSArray *)allSitesOrSideTripsForSites:(NSArray *)sites {
    NSMutableArray *sitesOrSideTrips = [NSMutableArray array];
    for (TourSiteOrRoute *site in sites) {
        [sitesOrSideTrips addObject:site];
        
        // not sure if this order is dependable
        for (CampusTourSideTrip *aTrip in site.sideTrips) {
            [sitesOrSideTrips addObject:aTrip];
        }
        for(CampusTourSideTrip *aTrip in site.nextComponent.sideTrips) {
            [sitesOrSideTrips addObject:aTrip];
        }
            
    }
    return sitesOrSideTrips;
}

- (NSArray *)allSitesStartingFrom:(TourSiteOrRoute *)site {
    NSArray *defaultSites = [self allSitesForTour];
    NSInteger index = [defaultSites indexOfObject:site];
    if (index == NSNotFound) {
        index = [defaultSites indexOfObject:site.nextComponent.nextComponent];
    }
    NSInteger len = [defaultSites count] - index;
    NSMutableArray *orderedSites = [NSMutableArray arrayWithArray:[defaultSites subarrayWithRange:NSMakeRange(index, len)]];
    [orderedSites addObjectsFromArray:[defaultSites subarrayWithRange:NSMakeRange(0, index)]];
    return orderedSites;
}

- (NSArray *)allRoutesStartingFrom:(TourSiteOrRoute *)route {
    NSArray *defaultRoutes = [self allRoutesForTour];
    NSInteger index = [defaultRoutes indexOfObject:route];
    if (index == NSNotFound) {
        for (TourSiteOrRoute *aRoute in defaultRoutes) {
            index++;
            if ([aRoute.componentID isEqualToString:route.componentID] || [aRoute.nextComponent.componentID isEqualToString:route.componentID]) {
                break;
            }
        }
    }
    NSInteger len = [defaultRoutes count] - index;
    NSMutableArray *orderedRoutes = [NSMutableArray arrayWithArray:[defaultRoutes subarrayWithRange:NSMakeRange(index, len)]];
    [orderedRoutes addObjectsFromArray:[defaultRoutes subarrayWithRange:NSMakeRange(0, index)]];
    
    return orderedRoutes;
}

- (NSArray *)startLocationsForTour {
    if (!_activeTour) return nil;

	NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"componentID" ascending:NO];
	NSArray *sortDescriptors = [NSArray arrayWithObject:sortDescriptor];

	NSPredicate *predicate = [NSPredicate predicateWithFormat:@"startSite IN %@", _activeTour.components];
	NSArray *locations = [CoreDataManager objectsForEntity:TourStartLocationEntityName
											matchingPredicate:predicate
											  sortDescriptors:sortDescriptors];

    if ([locations count] == 0) {
        locations = nil;
        [self requestTour:_activeTour.tourID];
    }
    return locations;
}

- (TourSiteOrRoute *)findSiteWithID:(NSString *)siteID {
    NSString *fullID = [NSString stringWithFormat:@"site-%@", siteID];
    return [CoreDataManager getObjectForEntity:TourSiteOrRouteEntityName attribute:@"componentID" value:fullID];
}

#pragma mark -
#pragma mark Core Data object creation

- (CampusTour *)tourWithID:(NSString *)tourID {
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"tourID=%@", tourID];
    CampusTour *theTour = (CampusTour *)[self managedObjectWithEntityName:CampusTourEntityName predicate:pred];
    if (theTour.tourID == nil)
        theTour.tourID = tourID;
    return theTour;
}

- (TourSiteOrRoute *)tourSiteWithID:(NSString *)siteID {
    NSString *fullID = [NSString stringWithFormat:@"site-%@", siteID];
    
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"componentID=%@", fullID];
    TourSiteOrRoute *component = (TourSiteOrRoute *)[self managedObjectWithEntityName:TourSiteOrRouteEntityName predicate:pred];
    if (component.componentID == nil)
        component.componentID = fullID;
    if (component.type == nil)
        component.type = @"site";
    return component;
}

- (TourSiteOrRoute *)tourRouteWithStartID:(NSString *)siteID {
    NSString *fullID = [NSString stringWithFormat:@"route-%@", siteID];
    
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"componentID=%@", fullID];
    TourSiteOrRoute *component = (TourSiteOrRoute *)[self managedObjectWithEntityName:TourSiteOrRouteEntityName predicate:pred];
    if (component.componentID == nil)
        component.componentID = fullID;
    if (component.type == nil)
        component.type = @"route";
    return component;
}

- (TourStartLocation *)tourStartLocationWithID:(NSString *)locationID {
    NSString *fullID = [NSString stringWithFormat:@"startloc-%@", locationID];
    
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"componentID=%@", fullID];
    TourStartLocation *component = (TourStartLocation *)[self managedObjectWithEntityName:TourStartLocationEntityName predicate:pred];
    if (component.componentID == nil)
        component.componentID = fullID;
    return component;
}

- (NSManagedObject *)managedObjectWithEntityName:(NSString *)entityName predicate:(NSPredicate *)predicate {
    NSArray *matches = [CoreDataManager objectsForEntity:entityName matchingPredicate:predicate];
    NSManagedObject *result = nil;
    if ([matches count]) {
        result = [matches lastObject];
    } else {
        result = [CoreDataManager insertNewObjectForEntityForName:entityName];
    }
    return result;
}

#pragma mark -
#pragma mark API Requests

- (void)requestTourList {
    MobileRequestOperation *request = [[[MobileRequestOperation alloc] initWithModule:@"tours"
                                                                              command:@"toursList"
                                                                           parameters:nil] autorelease];

    request.completeBlock = ^(MobileRequestOperation *operation, id jsonResult, NSString *contentType, NSError *error) {
        if (!error && [jsonResult isKindOfClass:[NSArray class]]) {
        NSMutableSet *oldTourKeys = [NSMutableSet setWithArray:[_tours allKeys]];
        
            for (NSDictionary *tourData in jsonResult) {
            NSString *tourID = [tourData objectForKey:@"id"];
            CampusTour *aTour = [self tourWithID:tourID];

            NSInteger lastModified = [[tourData objectForKey:@"last-modified"] integerValue];
            NSDate *remoteModified = [NSDate dateWithTimeIntervalSince1970:lastModified];
            if (lastModified) {
                NSDate *localModified = aTour.lastModified;
                if (!localModified || [remoteModified compare:localModified] == NSOrderedDescending) {
                    DDLogVerbose(@"local: %@ remote: %@", localModified, remoteModified);

                    aTour.title = [tourData objectForKey:@"title"];
                    aTour.summary = [tourData objectForKey:@"description"];
                    aTour.lastModified = remoteModified;

                    DDLogVerbose(@"deleting old data for tour %@ (%@)", aTour.title, aTour.tourID);
                    for (TourSiteOrRoute *aComponent in aTour.components) {
                        [aComponent deleteCachedMedia];
                        [CoreDataManager deleteObject:aComponent];
                    }
                    
                    for (TourLink *aLink in aTour.links) {
                        [CoreDataManager deleteObject:aLink];
                    }
                }
            }
            [_tours setObject:aTour forKey:tourID];
            [oldTourKeys removeObject:tourID];
        }
        
        for (NSString *oldTourKey in oldTourKeys) {
            CampusTour *aTour = [self tourWithID:oldTourKey];
            DDLogVerbose(@"deleting old tour %@ (%@)", aTour.title, aTour.tourID);
            [_tours removeObjectForKey:aTour.tourID];
            [aTour deleteCachedMedia];
            [CoreDataManager deleteObject:aTour];
        }
        [CoreDataManager saveData];
        
            [[NSNotificationCenter defaultCenter] postNotificationName:TourInfoLoadedNotification 
                                                                object:self 
                                                              userInfo:nil];

        } else {
            [[NSNotificationCenter defaultCenter] postNotificationName:TourInfoFailedToLoadNotification 
                                                                object:self 
                                                              userInfo:nil];
    }
    };
    
    [[NSOperationQueue mainQueue] addOperation:request];
}

- (void)requestTour:(NSString *)tourID {
    NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:tourID, @"tourId", nil];
    MobileRequestOperation *request = [[[MobileRequestOperation alloc] initWithModule:@"tours"
                                                                              command:@"tourDetails"
                                                                           parameters:params] autorelease];
    
    request.completeBlock = ^(MobileRequestOperation *operation, id jsonResult, NSString *contentType, NSError *error) {
        if (error) {
            [[NSNotificationCenter defaultCenter] postNotificationName:TourDetailsFailedToLoadNotification 
                                                            object:self 
                                                          userInfo:[NSDictionary dictionaryWithObjectsAndKeys:tourID, @"tourID", nil]];
        } else {
        CampusTour *aTour = [self tourWithID:tourID];
            aTour.title = [jsonResult objectForKey:@"title"];
            aTour.summary = [jsonResult objectForKey:@"description-top"];
            aTour.moreInfo = [jsonResult objectForKey:@"description-bottom"];
            aTour.feedbackSubject = [[jsonResult objectForKey:@"feedback"] objectForKey:@"subject"];
        
        NSInteger sortOrder = 0;
            for (NSDictionary *linkInfo in [jsonResult objectForKey:@"links"]) {
            TourLink *aLink = [CoreDataManager insertNewObjectForEntityForName:@"TourLink"];
            aLink.title = [linkInfo objectForKey:@"title"];
            aLink.url = [linkInfo objectForKey:@"url"];
            aLink.sortOrder = [NSNumber numberWithInt:sortOrder];
            aLink.tour = aTour;
            sortOrder++;
        }
        
        TourSiteOrRoute *firstSite = nil;
        TourSiteOrRoute *lastRoute = nil;
        
        sortOrder = 0;
            for (NSDictionary *siteInfo in [jsonResult objectForKey:@"sites"]) {
            NSString *siteID = [siteInfo objectForKey:@"id"];
            TourSiteOrRoute *aSite = [self tourSiteWithID:siteID];
            aSite.title = [siteInfo objectForKey:@"title"];
            aSite.tour = aTour;
            aSite.previousComponent = lastRoute;
            
            NSDictionary *coords = [siteInfo objectForKey:@"latlon"];
            if (coords) {
                aSite.latitude = [NSNumber numberWithFloat:[[coords objectForKey:@"latitude"] floatValue]];
                aSite.longitude = [NSNumber numberWithFloat:[[coords objectForKey:@"longitude"] floatValue]];
            }
            aSite.photoURL = [siteInfo objectForKey:@"photo-url"];
            aSite.audioURL = [siteInfo objectForKey:@"audio-url"];
            
            [aSite updateBody:[siteInfo objectForKey:@"content"]];
            NSDictionary *routeInfo = [siteInfo objectForKey:@"exit-directions"];

            lastRoute = [self tourRouteWithStartID:siteID];
            [lastRoute updateRouteWithInfo:routeInfo];
            lastRoute.previousComponent = aSite;
            lastRoute.tour = aTour;
            
            if (firstSite == nil)
                firstSite = aSite;
            
            aSite.sortOrder = [NSNumber numberWithInt:sortOrder];
            sortOrder++;
        }
        
        // link last stop to first to make a loop
        firstSite.previousComponent = lastRoute;
        [CoreDataManager saveData];
        
            NSDictionary *startInfo = [jsonResult objectForKey:@"start-locations"];
        aTour.startLocationHeader = [startInfo objectForKey:@"header"];
        NSArray *startLocations = [startInfo objectForKey:@"items"];
        
        for (NSDictionary *siteInfo in startLocations) {
            NSString *locationID = [siteInfo objectForKey:@"id"];
            TourStartLocation *aStartLocation = [self tourStartLocationWithID:locationID];
            
            aStartLocation.title = [siteInfo objectForKey:@"title"];
            aStartLocation.photoURL = [siteInfo objectForKey:@"photo-url"];
            aStartLocation.body = [siteInfo objectForKey:@"content"];
            NSString *siteID = [siteInfo objectForKey:@"start-site"];
            aStartLocation.startSite = [self findSiteWithID:siteID];
        }
        
        [CoreDataManager saveData];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:TourDetailsLoadedNotification 
                                                            object:self 
                                                          userInfo:[NSDictionary dictionaryWithObjectsAndKeys:tourID, @"tourID", nil]];
    }
    };

    [[NSOperationQueue mainQueue] addOperation:request];
}

#pragma mark -

- (id)init {
    self = [super init];
    
    if (self) {
        _tours = [[NSMutableDictionary alloc] init];
        NSArray *allTours = [CoreDataManager objectsForEntity:CampusTourEntityName matchingPredicate:nil];
        for (CampusTour *aTour in allTours) {
            [_tours setObject:aTour forKey:aTour.tourID];
        }
        _activeTour = nil;
        _routes = nil;
        _sites = nil;
        _mapRoute = nil;
    }
    return self;
}

- (void)dealloc {
    [_activeTour release];
    [_routes release];
    [_sites release];
    [_mapRoute release];
    [_tours release];
    [super dealloc];
}

@end
