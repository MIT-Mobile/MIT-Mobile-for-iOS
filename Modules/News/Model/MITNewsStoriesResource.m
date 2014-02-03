#import "MITNewsStoriesResource.h"
#import "MITMobileRouteConstants.h"
#import "MITNewsStory.h"

@implementation MITNewsStoriesResource
- (instancetype)initWithManagedObjectModel:(NSManagedObjectModel*)managedObjectModel
{
    self = [super initWithName:MITNewsStoriesResourceName pathPattern:MITNewsStoriesPathPattern managedObjectModel:managedObjectModel];
    if (self) {
        [self addMapping:[MITNewsStory objectMapping]
               atKeyPath:nil
        forRequestMethod:RKRequestMethodGET];
    }

    return self;
}

@end
