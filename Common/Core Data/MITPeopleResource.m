#import "MITPeopleResource.h"

#import "MITMobileRouteConstants.h"
#import "MITMobile.h"
#import "MITCoreData.h"
#import "MITAdditions.h"

@implementation MITPeopleResource

+ (void) peopleMatchingQuery:(NSString *)query loaded:(MITMobileResult)block
{
    NSDictionary *params = @{@"q": query};
    
    [[MITMobile defaultManager] getObjectsForResourceNamed:MITPeopleResourceName
                                                parameters:params
                                                completion:^(RKMappingResult *result, NSHTTPURLResponse *response, NSError *error) {
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
