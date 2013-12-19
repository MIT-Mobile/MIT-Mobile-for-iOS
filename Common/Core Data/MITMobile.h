#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import <RestKit/RestKit.h>

@class MITMobileResource;

#pragma mark /calendars
FOUNDATION_EXTERN NSString* const MITMobileCalendars;
FOUNDATION_EXTERN NSString* const MITMobileCalendar;
FOUNDATION_EXTERN NSString* const MITMobileCalendarEvents;
FOUNDATION_EXTERN NSString* const MITMobileCalendarEvent;

#pragma mark /dining
FOUNDATION_EXTERN NSString* const MITMobileDining;
FOUNDATION_EXTERN NSString* const MITMobileDiningVenueIcon;
FOUNDATION_EXTERN NSString* const MITMobileDiningHouseVenues;
FOUNDATION_EXTERN NSString* const MITMobileDiningRetailVenues;

#pragma mark /links
FOUNDATION_EXTERN NSString* const MITMobileLinks;

#pragma mark /maps
FOUNDATION_EXTERN NSString* const MITMobileMapCategories;
FOUNDATION_EXTERN NSString* const MITMobileMapPlaces;

#pragma mark /news
FOUNDATION_EXTERN NSString* const MITMobileNewsCategories;
FOUNDATION_EXTERN NSString* const MITMobileNewsStories;

#pragma mark /people
FOUNDATION_EXTERN NSString* const MITMobilePeople;
FOUNDATION_EXTERN NSString* const MITMobilePerson;

#pragma mark /shuttles
FOUNDATION_EXTERN NSString* const MITMobileShuttlesRoutes;
FOUNDATION_EXTERN NSString* const MITMobileShuttlesRoute;
FOUNDATION_EXTERN NSString* const MITMobileShuttlesStop;

#pragma mark /techccash
FOUNDATION_EXTERN NSString* const MITMobileTechcash;
FOUNDATION_EXTERN NSString* const MITMobileTechcashAccounts;
FOUNDATION_EXTERN NSString* const MITMobileTechcashAccount;


typedef void (^MITMobileResult)(NSOrderedSet *objects, NSError *error);

/** The callback handler for any requests which can be fulfilled by
 *  CoreData.
 *
 *  @param objects A sorted set of the fetched objects. These are guaranteed to be in the main queue context. This will be nil if an error occurs.
 *  @param fetchRequest The fetch request used to retreive the returned objects.  This will be nil if an error occurs.
 *  @param lastUpdated The date of the last successfully refresh of the cached data.
 *  @param error An error.
 */
typedef void (^MITMobileManagedResult)(NSFetchRequest *fetchRequest, NSDate *lastUpdated, NSError *error);

@interface MITMobile : NSObject
@property (nonatomic,readonly) NSDictionary *resources;

+ (MITMobile*)defaultManager;

- (instancetype)init;
- (void)setManagedObjectStore:(RKManagedObjectStore *)managedObjectStore;

- (MITMobileResource*)resourceForName:(NSString*)name;
- (void)setResource:(MITMobileResource*)resource forName:(NSString*)name;

- (NSFetchRequest*)getObjectsForResourceNamed:(NSString *)routeName object:(id)object parameters:(NSDictionary *)parameters completion:(void (^)(RKMappingResult *result, NSError *error))loaded;
@end
