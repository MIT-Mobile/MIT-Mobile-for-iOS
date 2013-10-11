#import <CoreData/CoreData.h>


@interface MapSearch :  NSManagedObject
@property (nonatomic, copy, readonly) NSString * token;
@property (nonatomic, copy) NSString * searchTerm;
@property (nonatomic, strong) NSDate * date;

@end
