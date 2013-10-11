#import "MapSearch.h"
#import "MITAdditions.h"

@interface MapSearch ()
@property (nonatomic, copy) NSString* token;
@end

@implementation MapSearch
@synthesize token = _token;
@dynamic searchTerm;
@dynamic date;

- (NSString*)token
{
    [self willAccessValueForKey:@"token"];

    NSString *token = self->_token;
    if (!token) {
        token = [self.searchTerm stringBySearchNormalization];
        self.token = token;
    }

    [self didAccessValueForKey:@"token"];

    return token;
}

- (void)didChangeValueForKey:(NSString *)key
{
    if ([key isEqualToString:@"searchTerm"]) {
        self.token = [self.searchTerm stringBySearchNormalization];
    }
}

@end
