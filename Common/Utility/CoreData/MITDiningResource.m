#import "MITMobile.h"
#import "MITMobileRouteConstants.h"
#import "MITDiningResource.h"
#import "MITDiningDining.h"

@implementation MITDiningResource


- (instancetype)initWithManagedObjectModel:(NSManagedObjectModel *)managedObjectModel
{
    self = [super initWithName:MITDiningResourceName pathPattern:MITDiningPathPattern managedObjectModel:managedObjectModel];
    if (self) {
        [self addMapping:[MITDiningDining objectMapping]
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
        NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:[MITDiningDining entityName]];
        fetchRequest.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"url" ascending:YES]];
        return fetchRequest;
    }
    return nil;
}

@end