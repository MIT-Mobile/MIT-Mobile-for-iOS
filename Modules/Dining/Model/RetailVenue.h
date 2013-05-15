#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class VenueLocation;

@interface RetailVenue : NSManagedObject

@property (nonatomic, retain) NSString *name;
@property (nonatomic, retain) NSString *shortName;
@property (nonatomic, retain) NSString *descriptionHTML;
@property (nonatomic, retain) NSArray *paymentMethods;
@property (nonatomic, retain) NSArray *cuisines;
@property (nonatomic, retain) NSString *url;
@property (nonatomic, retain) NSString *homepageURL;
@property (nonatomic, retain) NSString *menuURL;
@property (nonatomic, retain) NSString *iconURL;
@property (nonatomic, retain) NSArray *hours;
@property (nonatomic, retain) NSString *building;
@property (nonatomic, retain) NSString *sortableBuilding;
@property (nonatomic, retain) VenueLocation *location;

+ (RetailVenue *)newVenueWithDictionary:(NSDictionary *)dict;

@end
