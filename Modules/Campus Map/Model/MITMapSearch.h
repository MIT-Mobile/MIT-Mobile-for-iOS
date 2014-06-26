#import <CoreData/CoreData.h>

@class MITMapPlace;
@class MITMapCategory;

@interface MITMapSearch :  NSManagedObject

@property (nonatomic, copy, readonly) NSString * token;
@property (nonatomic, copy) NSString * searchTerm;
@property (nonatomic, strong) NSDate * date;
@property (nonatomic, strong) MITMapPlace *place;
@property (nonatomic, strong) MITMapCategory *category;

+ (NSString*)entityName;

@end
