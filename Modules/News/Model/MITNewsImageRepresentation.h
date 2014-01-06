#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class MITNewsImage;

@interface MITNewsImageRepresentation : NSManagedObject

@property (nonatomic, strong) NSNumber * height;
@property (nonatomic, strong) NSNumber * width;
@property (nonatomic, retain) NSString * url;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, strong) MITNewsImage *image;

+ (NSString*)entityName;
@end
