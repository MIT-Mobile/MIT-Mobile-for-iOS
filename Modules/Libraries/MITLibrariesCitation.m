#import "MITLibrariesCitation.h"

@implementation MITLibrariesCitation

- (instancetype)initWithName:(NSString *)name citation:(NSString *)citation
{
    self = [super init];
    if (self) {
        self.name = name;
        self.citation = citation;
    }
    return self;
}

@end
