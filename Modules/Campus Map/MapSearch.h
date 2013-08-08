#import <CoreData/CoreData.h>


@interface MapSearch :  NSManagedObject
@property (nonatomic, copy) NSString * searchTerm;
@property (nonatomic, strong) NSDate * date;

@end



