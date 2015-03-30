#import <Foundation/Foundation.h>

@interface MITMobiusAttributesDataSource : NSObject
@property (nonatomic,strong) NSDate *lastUpdated;

- (NSArray*)attributesInManagedObjectContext:(NSManagedObjectContext*)managedObjectContext;
- (void)attributes:(void(^)(MITMobiusAttributesDataSource *dataSource, NSError* error))completion;
@end
