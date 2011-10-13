#import "NewsModule.h"
#import "StoryListViewController.h"

#import "MITModule+Protected.h"

@implementation NewsModule

@synthesize storyListChannelController;

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
    StoryListViewController *controller = [[[StoryListViewController alloc] init] autorelease];
    
    self.moduleHomeController = controller;
}

- (void)dealloc {
    [storyListChannelController release];
    [super dealloc];
}

@end
