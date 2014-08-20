#import "MITNewsDataSource.h"
#import "MITCoreDataController.h"
#import <objc/runtime.h>

#import "MITNewsStory.h"
#import "MITNewsCategory.h"

static NSString* const MITNewsDataSourceAssociatedObjectKeyFirstRun;

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
    dispatch_sync(dispatch_get_main_queue(), ^{
        id firstRunToken = objc_getAssociatedObject(self, (__bridge const void*)MITNewsDataSourceAssociatedObjectKeyFirstRun);

        if (!firstRunToken) {
            __block NSError *error = nil;
            BOOL updateDidFail = [[MITCoreDataController defaultController] performBackgroundUpdateAndWait:^(NSManagedObjectContext *context, NSError *__autoreleasing *error) {
                return [self clearCachedObjectsWithManagedObjectContext:context error:error];
            } error:&error];

            if (updateDidFail) {
                DDLogWarn(@"failed to clear cached objects for %@: %@",NSStringFromClass(self),[error localizedDescription]);
            }

            objc_setAssociatedObject(self, (__bridge const void*)MITNewsDataSourceAssociatedObjectKeyFirstRun, @(YES), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        }
    });
}

- (instancetype)initWithManagedObjectContext:(NSManagedObjectContext*)managedObjectContext
{
    self = [super init];
    if (self) {
        _managedObjectContext = managedObjectContext;
    }

    return self;
}


- (BOOL)hasNextPage
{
    return NO;
}

- (BOOL)nextPage:(void(^)(NSError *error))block
{
    if (block) {
        block(nil);
    }

    return NO;
}

- (void)refresh:(void(^)(NSError *error))block
{
    if (block) {
        block(nil);
    }
}

@end
