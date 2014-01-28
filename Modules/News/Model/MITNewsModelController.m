#import "MITNewsModelController.h"

#import "MITCoreData.h"
#import "MITMobileResources.h"
#import "MITAdditions.h"

#import "MITNewsStory.h"
#import "MITNewsCategory.h"

@implementation MITNewsModelController
+ (instancetype)sharedController
{
    static MITNewsModelController *sharedModelController = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedModelController = [[self alloc] init];
    });

    return sharedModelController;
}

- (void)categories:(void (^)(NSArray *categories, NSError *error))block
{
    [[MITMobile defaultManager] getObjectsForResourceNamed:MITNewsCategoriesResourceName
                                                parameters:nil
                                                completion:^(RKMappingResult *result, NSHTTPURLResponse *response, NSError *error) {
                                                    if (block) {
                                                        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                                                            if (!error) {
                                                                NSManagedObjectContext *mainQueueContext = [[MITCoreDataController defaultController] mainQueueContext];
                                                                NSArray *objects = [mainQueueContext transferManagedObjects:[result array]];
                                                                block(objects,nil);
                                                            } else {
                                                                block(nil,error);
                                                            }
                                                        }];
                                                    }
                                                }];
}

- (MITMobileResultsPaginator*)storiesInCategory:(MITNewsCategory*)category batchSize:(NSUInteger)numberOfStories completion:(void (^)(NSArray *stories, NSError *error))block
{
    void (^localBlock)(NSArray *stories, NSError *error) = nil;
    if (!block) {
        localBlock = ^(NSArray *stories, NSError *error) {
            if (error) {
                DDLogWarn(@"failed to updates 'stories': %@", error);
            }
        };
    } else {
        localBlock = ^(NSArray *stories, NSError *error) {
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                if (!error) {
                    NSManagedObjectContext *mainContext = [[MITCoreDataController defaultController] mainQueueContext];
                    NSArray *mainQueueStories = [mainContext transferManagedObjects:stories];
                    block(mainQueueStories,nil);
                } else {
                    block(nil,error);
                }
            }];
        };
    }
    
    [[MITMobile defaultManager] getObjectsForURL:category.url
                                      completion:^(RKMappingResult *result, NSHTTPURLResponse *response, NSError *error) {
                                          if (!error) {
                                              [[MITCoreDataController defaultController] performBackgroundUpdate:^(NSManagedObjectContext *context, NSError **error) {
                                                  NSArray *stories = [context transferManagedObjects:[result array]];
                                                  MITNewsCategory *blockCategory = (MITNewsCategory*)[context objectWithID:[category objectID]];
                                                  
                                                  [blockCategory addStories:[NSSet setWithArray:stories]];
                                              } completion:^(NSError *error) {
                                                  localBlock([result array],error);
                                              }];
                                          } else {
                                              localBlock(nil,error);
                                          }
                                      }];
    
    return nil;
}

@end
