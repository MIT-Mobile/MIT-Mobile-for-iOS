#import "MITManagedObject.h"
#import "MITCoreDataController.h"

@implementation MITManagedObject
+ (NSEntityDescription*)entityDescription
{
    NSAssert(self != [MITManagedObject class],@"%@ may only be called on %@ subclasses.",NSStringFromSelector(_cmd),NSStringFromClass([MITManagedObject class]));
    
    NSManagedObjectModel *managedObjectModel = [[MITCoreDataController defaultController] managedObjectModel];
    
    __block NSEntityDescription *entityDescription = nil;
    [[managedObjectModel entities] enumerateObjectsUsingBlock:^(NSEntityDescription *description, NSUInteger idx, BOOL *stop) {
        NSString *entityClassName = [description managedObjectClassName];
        Class entityClass = NSClassFromString(entityClassName);
        
        if ([entityClass isSubclassOfClass:self]) {
            entityDescription = description;
            (*stop) = YES;
        }
    }];
    
    NSAssert(entityDescription != nil, @"unable to find an entity description with class '%@'",NSStringFromClass(self));
    return entityDescription;
}

+ (NSString*)entityName
{
    return [[self entityDescription] name];
}

@end
