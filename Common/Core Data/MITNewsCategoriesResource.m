#import "MITNewsCategoriesResource.h"

#import "MITMobile.h"
#import "MITMobileRouteConstants.h"

#import "MITNewsStory.h"
#import "MITNewsCategory.h"
#import "MITNewsImage.h"
#import "MITNewsImageRepresentation.h"

@implementation MITNewsCategoriesResource
- (instancetype)initWithManagedObjectModel:(NSManagedObjectModel*)managedObjectModel
{
    self = [super initWithName:MITNewsCategoriesResourceName pathPattern:MITNewsCategoriesPathPattern managedObjectModel:managedObjectModel];
    if (self) {
        [self addMapping:[MITNewsCategory objectMapping]
               atKeyPath:nil
        forRequestMethod:RKRequestMethodGET];
    }

    return self;
}

@end
