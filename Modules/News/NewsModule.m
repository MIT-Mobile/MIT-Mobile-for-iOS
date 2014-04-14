#import "NewsModule.h"

#import "MITNewsViewController.h"

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

- (UIViewController*)moduleHomeController
{
    return [self instantiateRootViewController];
}

- (UIViewController*)instantiateRootViewController
{
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"News" bundle:nil];
    NSAssert(storyboard, @"failed to load storyboard for %@",self);
    
    UIViewController *controller = [storyboard instantiateViewControllerWithIdentifier:@"StoryListViewController"];
    return controller;
}

@end
