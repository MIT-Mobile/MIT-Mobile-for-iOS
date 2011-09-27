#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class FacilitiesLocation;

@interface FacilitiesRoom : NSManagedObject {
@private
}
@property (nonatomic, retain) NSString * floor;
@property (nonatomic, retain) NSString * number;
@property (nonatomic, retain) NSString * building;

- (NSString*)displayString;
- (NSString*)description;
@end
