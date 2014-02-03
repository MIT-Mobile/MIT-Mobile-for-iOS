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

- (NSFetchRequest*)fetchRequestForURL:(NSURL*)url
{
    if (!url) {
        return (NSFetchRequest*)nil;
    }

    RKPathMatcher *pathMatcher = [RKPathMatcher pathMatcherWithPath:[url relativePath]];
    BOOL matches = [pathMatcher matchesPattern:self.pathPattern tokenizeQueryStrings:NO parsedArguments:nil];

    if (matches) {
        NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"MapCategory"];
        fetchRequest.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"order" ascending:YES]];
        return fetchRequest;
    } else {
        return (NSFetchRequest*)nil;
    }
}
@end
