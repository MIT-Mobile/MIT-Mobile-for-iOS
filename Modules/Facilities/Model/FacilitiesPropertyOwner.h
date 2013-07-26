#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class FacilitiesLocation;

@interface FacilitiesPropertyOwner : NSManagedObject
@property (nonatomic, strong) NSString* name;
@property (nonatomic, strong) NSString* phone;
@property (nonatomic, strong) NSString* email;
@property (nonatomic, strong) NSSet* locations;

- (void)addLocationsObject:(FacilitiesLocation *)value;
- (void)removeLocationsObject:(FacilitiesLocation *)value;
- (void)addLocations:(NSSet *)value;
- (void)removeLocations:(NSSet *)value;

@end
