#import "NewsModule.h"
#import "StoryListViewController.h"

#import "MITModule+Protected.h"

@implementation NewsModule
- (id) init {
    self = [super init];
    if (self != nil) {
        self.tag = NewsOfficeTag;
        self.shortName = @"News";
        self.longName = @"News Office";
        self.iconName = @"news";
    }
    return self;
}

- (void)loadModuleHomeController
{
    self.moduleHomeController = [[StoryListViewController alloc] init];
}

- (StoryListViewController*)storyListChannelController
{
    if ([self.moduleHomeController isKindOfClass:[StoryListViewController class]]) {
        return (StoryListViewController*)self.moduleHomeController;
    }
    
    return nil;
}
@end
