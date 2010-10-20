
#import <CoreData/CoreData.h>

@class StellarClass;

@interface StellarCourse :  NSManagedObject  
{
}

@property (nonatomic, retain) NSString * number;
@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) NSSet* stellarClasses;

@end


@interface StellarCourse (CoreDataGeneratedAccessors)
- (void)addStellarClassesObject:(StellarClass *)value;
- (void)removeStellarClassesObject:(StellarClass *)value;
- (void)addStellarClasses:(NSSet *)value;
- (void)removeStellarClasses:(NSSet *)value;

@end

