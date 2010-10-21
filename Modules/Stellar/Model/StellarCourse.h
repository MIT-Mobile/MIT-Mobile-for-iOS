
#import <CoreData/CoreData.h>

@class StellarClass;

@interface StellarCourse :  NSManagedObject  
{
}

@property (nonatomic, retain) NSDate * lastCache;
@property (nonatomic, retain) NSString * lastChecksum;
@property (nonatomic, retain) NSString * number;
@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) NSSet* stellarClasses;
@property (nonatomic, retain) NSString * term;

@end


@interface StellarCourse (CoreDataGeneratedAccessors)
- (void)addStellarClassesObject:(StellarClass *)value;
- (void)removeStellarClassesObject:(StellarClass *)value;
- (void)addStellarClasses:(NSSet *)value;
- (void)removeStellarClasses:(NSSet *)value;

@end

