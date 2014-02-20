#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "MITManagedObject.h"
#import "MITMappedObject.h"

@class MITNewsImage;

@interface MITNewsImageRepresentation : MITManagedObject <MITMappedObject>

@property (nonatomic, strong) NSNumber * height;
@property (nonatomic, strong) NSNumber * width;
@property (nonatomic, retain) NSURL * url;
@property (nonatomic, strong) MITNewsImage *image;

@end
