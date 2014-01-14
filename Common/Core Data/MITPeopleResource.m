#import "MITPeopleResource.h"
#import "MITAdditions.h"
#import "MITMobileResources.h"

@implementation MITPeopleResource

+ (void) peopleMatchingQuery:(NSString *)query loaded:(MITMobileResult)block
{
    NSDictionary *params = @{@"q": query};
    
    [[MITMobile defaultManager] getObjectsForResourceNamed:MITPeopleResourceName
                                                    object:nil
                                                parameters:params
                                                completion:^(RKMappingResult *result, NSError *error) {
                                                    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                                                        if (!error) {
                                                            NSManagedObjectContext *mainQueueContext = [[MITCoreDataController defaultController] mainQueueContext];
                                                            NSArray *mappedObjects = [mainQueueContext transferManagedObjects:[result array]];
                                                            
                                                            block(mappedObjects, nil);
                                                        } else {
                                                            block(nil,error);
                                                        }
                                                    }];
                                                }];
}


- (instancetype)initWithManagedObjectModel:(NSManagedObjectModel*)managedObjectModel
{
    self = [super initWithName:MITPeopleResourceName pathPattern:MITPeoplePathPattern managedObjectModel:managedObjectModel];
    if (self) {
        
    }
    return self;
}


@end
