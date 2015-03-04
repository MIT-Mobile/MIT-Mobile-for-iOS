#import "MITPersonResource.h"

#import "MITMobileRouteConstants.h"
#import "MITMobile.h"
#import "MITCoreData.h"
#import "MITAdditions.h"

@implementation MITPersonResource

+ (void) personWithID:(NSString *)uid loaded:(MITMobileResult)block
{
    NSDictionary *object = @{@"person": uid};
    
    [[MITMobile defaultManager] getObjectsForResourceNamed:MITPersonResourceName
                                                parameters:object
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
    self = [super initWithName:MITPersonResourceName pathPattern:MITPersonPathPattern managedObjectModel:managedObjectModel];
    if (self) {
        
    }
    return self;
}




- (void)loadMappings
{
    NSEntityDescription *personDetailsEntity = [self.managedObjectModel entitiesByName][PersonDetailsEntityName];
    NSAssert(personDetailsEntity,@"[%@] entity %@ does not exist in the managed object model",self.name,PersonDetailsEntityName);
    
    RKEntityMapping *personMapping = [[RKEntityMapping alloc] initWithEntity:personDetailsEntity];
    personMapping.identificationAttributes = @[@"uid"]; // RKEntityMapping converts this to an NSAttributeDescription internally
    personMapping.assignsNilForMissingRelationships = YES;
    [personMapping addAttributeMappingsFromDictionary:@{@"id" : @"uid",
                                                        @"url" : @"url",
                                                        @"givenname" : @"givenname",
                                                        @"surname" : @"surname",
                                                        @"name" : @"name",
                                                        @"dept" : @"dept",
                                                        @"title" : @"title",
                                                        @"affiliation" : @"affiliation",
                                                        @"email" : @"email",
                                                        @"phone" : @"phone",
                                                        @"homephone" : @"homephone",
                                                        @"fax" : @"fax",
                                                        @"website" : @"website",
                                                        @"office" : @"office",
                                                        @"street" : @"street",
                                                        @"city" : @"city",
                                                        @"state" : @"state"}];
    
    [self addMapping:personMapping atKeyPath:nil forRequestMethod:RKRequestMethodAny];
}

@end
