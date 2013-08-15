#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@interface NewsImageRep : NSManagedObject
@property (nonatomic, copy) NSString *url;
@property (nonatomic, strong) NSNumber *width;
@property (nonatomic, strong) NSNumber *height;
@property (nonatomic, copy) NSData *data;

@end
