#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class FacilitiesLocation;

@interface FacilitiesPropertyOwner : NSManagedObject {
@private
}
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSString * phone;
@property (nonatomic, retain) NSString * email;
@property (nonatomic, retain) NSSet* locations;

- (void)addLocationsObject:(FacilitiesLocation *)value;
- (void)removeLocationsObject:(FacilitiesLocation *)value;
- (void)addLocations:(NSSet *)value;
- (void)removeLocations:(NSSet *)value;

@end
