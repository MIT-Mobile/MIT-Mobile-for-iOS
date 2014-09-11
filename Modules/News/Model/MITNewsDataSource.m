#import "MITNewsDataSource.h"
#import "MITCoreDataController.h"
#import <objc/runtime.h>

#import "MITNewsStory.h"
#import "MITNewsCategory.h"

static void const *MITDataSourceCachedObjectsClearedKey = &MITDataSourceCachedObjectsClearedKey;

NSString* const MITNewsDataSourceDidBeginUpdatingNotification = @"MITNewsDataSourceDidBeginUpdatingNotification";
NSString* const MITNewsDataSourceDidEndUpdatingNotification = @"MITNewsDataSourceDidEndUpdatingNotification";

@interface MITNewsDataSource ()
@property(strong) id parentContextDidSaveObserverToken;
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
        id firstRunToken = objc_getAssociatedObject(self, MITDataSourceCachedObjectsClearedKey);
        
        if (!firstRunToken) {
            __block NSError *error = nil;
            BOOL updatePassed = [[MITCoreDataController defaultController] performBackgroundUpdateAndWait:^(NSManagedObjectContext *context, NSError *__autoreleasing *error) {
                return [self clearCachedObjectsWithManagedObjectContext:context error:error];
            } error:&error];
            
            if (!updatePassed) {
                DDLogWarn(@"failed to clear cached objects for %@: %@",NSStringFromClass(self),[error localizedDescription]);
            }
            
            objc_setAssociatedObject(self, MITDataSourceCachedObjectsClearedKey, @(YES), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        }
    }];
    
    [[NSOperationQueue mainQueue] addOperation:blockOperation];
}

- (instancetype)initWithManagedObjectContext:(NSManagedObjectContext*)managedObjectContext
{
    self = [super init];
    if (self) {
        [[self class] _clearCachedObjects];

        NSManagedObjectContext *childContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
        childContext.parentContext = managedObjectContext;

        id notificationToken = [[NSNotificationCenter defaultCenter] addObserverForName:NSManagedObjectContextDidSaveNotification object:managedObjectContext queue:nil usingBlock:^(NSNotification *note) {
            [childContext mergeChangesFromContextDidSaveNotification:note];
        }];
        self.parentContextDidSaveObserverToken = notificationToken;

        _managedObjectContext = childContext;
    }

    return self;
}

- (void)dealloc
{
    if (self.parentContextDidSaveObserverToken) {
        [[NSNotificationCenter defaultCenter] removeObserver:self.parentContextDidSaveObserverToken];
    }
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
