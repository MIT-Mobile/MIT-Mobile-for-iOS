#import <CoreData/CoreData.h>
#import "NewsImageRep.h"

@interface NewsImage : NSManagedObject

@property (nonatomic, strong) NewsImageRep *thumbImage;
@property (nonatomic, strong) NewsImageRep *smallImage;
@property (nonatomic, strong) NewsImageRep *fullImage;

@property (nonatomic, copy) NSString *credits;
@property (nonatomic, copy) NSString *caption;

@property (nonatomic, strong) NSNumber *ordinality;

@end
