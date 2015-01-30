#import "MITToursResource.h"
#import "MITMobileRouteConstants.h"
#import "MITToursTour.h"

@implementation MITToursResource

- (instancetype)initWithManagedObjectModel:(NSManagedObjectModel *)managedObjectModel
{
    self = [super initWithName:MITToursResourceName pathPattern:MITToursPathPattern managedObjectModel:managedObjectModel];
    if (self) {
        [self addMapping:[MITToursTour objectMapping]
               atKeyPath:nil
        forRequestMethod:RKRequestMethodGET];
    }
    
    return self;
}

- (NSFetchRequest *)fetchRequestForURL:(NSURL *)url
{
    RKPathMatcher *pathMatcher = [RKPathMatcher pathMatcherWithPath:[[url relativePath] stringByAppendingString:@"/"]];
    
    NSDictionary *parameters = nil;
    BOOL matches = [pathMatcher matchesPattern:self.pathPattern tokenizeQueryStrings:YES parsedArguments:&parameters];
    
    if (matches) {
        NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:[MITToursTour entityName]];
        fetchRequest.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"url" ascending:YES]];
        return fetchRequest;
    }
    return nil;
}

@end

@implementation MITToursTourResource

- (instancetype)initWithManagedObjectModel:(NSManagedObjectModel *)managedObjectModel
{
    self = [super initWithName:MITToursTourResourceName pathPattern:MITToursTourPathPattern managedObjectModel:managedObjectModel];
    if (self) {
        [self addMapping:[MITToursTour objectMapping]
               atKeyPath:nil
        forRequestMethod:RKRequestMethodGET];
    }
    
    return self;
}

- (NSFetchRequest *)fetchRequestForURL:(NSURL *)url
{
    RKPathMatcher *pathMatcher = [RKPathMatcher pathMatcherWithPath:[[url relativePath] stringByAppendingString:@"/"]];
    
    NSDictionary *parameters = nil;
    BOOL matches = [pathMatcher matchesPattern:self.pathPattern tokenizeQueryStrings:YES parsedArguments:&parameters];
    
    if (matches) {
        NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:[MITToursTour entityName]];
        fetchRequest.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"url" ascending:YES]];
        return fetchRequest;
    }
    return nil;
}

@end
