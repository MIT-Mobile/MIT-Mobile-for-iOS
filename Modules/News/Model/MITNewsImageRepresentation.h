#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "MITManagedObject.h"

@class MITNewsImage;

@interface MITNewsImageRepresentation : MITManagedObject

@property (nonatomic, strong) NSNumber * height;
@property (nonatomic, strong) NSNumber * width;
@property (nonatomic, retain) NSString * url;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, strong) MITNewsImage *image;
@end
