#import <Foundation/Foundation.h>
#import "MITMobileWebAPI.h"

typedef enum {
    TourSiteVisited,
    TourSiteNotVisited,
    TourSiteVisiting
} TourSiteVisitStatus;

extern NSString * const TourInfoLoadedNotification;
extern NSString * const TourInfoFailedToLoadNotification;
extern NSString * const TourDetailsLoadedNotification;
extern NSString * const TourDetailsFailedToLoadNotification;

@class CampusTour, TourSiteOrRoute, MITGenericMapRoute, CampusTourSideTrip;

@interface ToursDataManager : NSObject <JSONLoadedDelegate> {
    NSMutableDictionary *_tours;
    
    CampusTour *_activeTour;
    NSArray *_sites;
    NSArray *_routes;
    MITGenericMapRoute *_mapRoute;
}

+ (UIImage *)imageForVisitStatus:(TourSiteVisitStatus)visitStatus;
+ (NSString *)labelForVisitStatus:(TourSiteVisitStatus)visitStatus;
+ (ToursDataManager *)sharedManager;
- (NSArray *)allTours;
- (BOOL)setActiveTourID:(NSString *)tourID;
- (CampusTour *)activeTour;
- (NSArray *)startLocationsForTour;
- (NSArray *)allSitesForTour;
- (NSArray *)allSitesOrSideTripsForSites:(NSArray *)sites;
- (NSArray *)allRoutesForTour;
- (MITGenericMapRoute *)mapRouteForTour;
- (MITGenericMapRoute *)mapRouteFromSideTripToSite:(CampusTourSideTrip *)sideTrip;
- (NSArray *)allSitesStartingFrom:(TourSiteOrRoute *)site;
- (NSArray *)allRoutesStartingFrom:(TourSiteOrRoute *)route;

@end
