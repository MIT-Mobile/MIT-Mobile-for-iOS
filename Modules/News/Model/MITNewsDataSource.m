#import "MITNewsDataSource.h"
#import "MITCoreDataController.h"
#import <objc/runtime.h>

#import "MITNewsStory.h"
#import "MITNewsCategory.h"

static NSString* const MITNewsDataSourceObjectKeyCacheWasCleared;

@interface MITNewsDataSource ()

@end

@implementation MITNewsDataSource
@synthesize managedObjectContext = _managedObjectContext;
+ (BOOL)clearCachedObjectsWithManagedObjectContext:(NSManagedObjectContext*)context error:(NSError**)error
{
    /* Do Nothing, just fail-by-success for the default implementation */
    return YES;
}

+ (void)_clearCachedObjects
{
    // This most likely will be a fairly espensive operation
    // since it involves potentially deleting a large number of
    // CoreData objects (especially with a number of subclasses)
    NSBlockOperation *blockOperation = [NSBlockOperation blockOperationWithBlock:^{
        id firstRunToken = objc_getAssociatedObject(self, (__bridge const void*)MITNewsDataSourceObjectKeyCacheWasCleared);
        
        if (!firstRunToken) {
            __block NSError *error = nil;
            BOOL updateDidFail = [[MITCoreDataController defaultController] performBackgroundUpdateAndWait:^(NSManagedObjectContext *context, NSError *__autoreleasing *error) {
                return [self clearCachedObjectsWithManagedObjectContext:context error:error];
            } error:&error];
            
            if (updateDidFail) {
                DDLogWarn(@"failed to clear cached objects for %@: %@",NSStringFromClass(self),[error localizedDescription]);
            }
            
            objc_setAssociatedObject(self, (__bridge const void*)MITNewsDataSourceObjectKeyCacheWasCleared, @(YES), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        }
    }];
    
    [[NSOperationQueue mainQueue] addOperation:blockOperation];
}

- (instancetype)initWithManagedObjectContext:(NSManagedObjectContext*)managedObjectContext
{
    self = [super init];
    if (self) {
        [[self class] _clearCachedObjects];
        
        _managedObjectContext = managedObjectContext;
    }

    return self;
}

- (BOOL)isUpdating
{
    return NO;
}

- (BOOL)hasNextPage
{
    return NO;
}

- (void)nextPage:(void(^)(NSError *error))block
{
    if (block) {
        block(nil);
    }
}

- (void)refresh:(void(^)(NSError *error))block
{
    if (block) {
        block(nil);
    }
}

@end
