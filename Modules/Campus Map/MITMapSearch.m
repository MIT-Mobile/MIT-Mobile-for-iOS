#import "MITMapSearch.h"
#import "MITAdditions.h"

@interface MITMapSearch ()
@property (nonatomic, copy) NSString* token;
@end

@implementation MITMapSearch
@dynamic searchTerm;
@dynamic date;
@dynamic token;

- (void)awakeFromFetch {
    [super awakeFromFetch];

    self.token = [self.searchTerm stringBySearchNormalization];
}

- (void)didChangeValueForKey:(NSString*)key
{
    [super didChangeValueForKey:key];

    if ([key isEqualToString:@"searchTerm"]) {
        self.token = [self.searchTerm stringBySearchNormalization];
    }
}

- (void)didTurnIntoFault
{
    [super didTurnIntoFault];
    self.token = nil;
}

@end
