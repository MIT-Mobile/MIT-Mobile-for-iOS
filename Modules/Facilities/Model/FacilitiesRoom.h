#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class FacilitiesLocation;

@interface FacilitiesRoom : NSManagedObject
@property (nonatomic, strong) NSString * floor;
@property (nonatomic, strong) NSString * number;
@property (nonatomic, strong) NSString * building;

- (NSString*)displayString;
- (NSString*)description;
@end
