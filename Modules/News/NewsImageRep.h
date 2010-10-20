#import <CoreData/CoreData.h>


@interface NewsImageRep : NSManagedObject

@property (nonatomic, retain) NSString *url;
@property (nonatomic, retain) NSData *data;
@property (nonatomic, retain) NSNumber *width;
@property (nonatomic, retain) NSNumber *height;

@end
