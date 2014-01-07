#import <CoreData/CoreData.h>


@interface MITMapSearch :  NSManagedObject
@property (nonatomic, copy, readonly) NSString * token;
@property (nonatomic, copy) NSString * searchTerm;
@property (nonatomic, strong) NSDate * date;

+ (NSString*)entityName;
@end
