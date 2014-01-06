#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class MITMapPlace;

@interface MITMapBookmark : NSManagedObject

@property (nonatomic, strong) NSNumber * order;
@property (nonatomic, strong) MITMapPlace *place;

+ (NSString*)entityName;
@end
