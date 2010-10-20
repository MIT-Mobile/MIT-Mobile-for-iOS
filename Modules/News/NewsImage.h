#import <CoreData/CoreData.h>
#import "NewsImageRep.h"

@interface NewsImage : NSManagedObject

@property (nonatomic, retain) NewsImageRep *thumbImage;
@property (nonatomic, retain) NewsImageRep *smallImage;
@property (nonatomic, retain) NewsImageRep *fullImage;

@property (nonatomic, retain) NSString *credits;
@property (nonatomic, retain) NSString *caption;

@property (nonatomic, retain) NSNumber *ordinality;

@end
