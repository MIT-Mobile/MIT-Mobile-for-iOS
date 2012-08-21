
#import "LinksModule.h"
#import "LinksViewController.h"

#import "MITModule+Protected.h"

@implementation LinksModule

- (id) init {
    self = [super init];
    if (self != nil) {
        self.tag = LinksTag;
        self.shortName = @"Links";
        self.longName = @"Links";
        self.iconName = @"webmitedu";
    }
    return self;
}

- (void)loadModuleHomeController
{
    self.moduleHomeController = [[[LinksViewController alloc] init] autorelease];
}

@end
