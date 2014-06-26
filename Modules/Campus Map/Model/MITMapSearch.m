#import "MITMapSearch.h"
#import "MITAdditions.h"
#import "MITMapPlace.h"
#import "MITMapCategory.h"

@interface MITMapSearch ()
@property (nonatomic, copy) NSString* token;
@end

@implementation MITMapSearch
@dynamic searchTerm;
@dynamic date;
@dynamic token;
@dynamic place;
@dynamic category;

+ (NSString*)entityName
{
    return @"MapSearch";
}

- (void)didChangeValueForKey:(NSString*)key
{
    [super didChangeValueForKey:key];

    if ([key isEqualToString:@"searchTerm"]) {
        self.token = [self.searchTerm stringBySearchNormalization];
    }
}

@end
