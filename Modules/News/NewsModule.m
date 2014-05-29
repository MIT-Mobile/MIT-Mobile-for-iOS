#import "NewsModule.h"

#import "MITNewsViewController.h"



@implementation NewsModule
- (id) init {
    self = [super initWithTag:MITModuleTagNewsOffice];
    if (self) {
        self.shortName = @"News";
        self.longName = @"News Office";
        self.iconName = @"news";
    }
    
    return self;
}

- (BOOL)supportsUserInterfaceIdiom:(UIUserInterfaceIdiom)idiom
{
    return YES;
}

- (UIViewController*)createHomeViewControllerForPadIdiom
{
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"News_iPad" bundle:nil];
    NSAssert(storyboard, @"failed to load storyboard for %@",self);
    
    UIViewController *controller = [storyboard instantiateInitialViewController];
    return controller;
}

- (UIViewController*)createHomeViewControllerForPhoneIdiom
{
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"News_iPhone" bundle:nil];
    NSAssert(storyboard, @"failed to load storyboard for %@",self);
    
    UIViewController *controller = [storyboard instantiateViewControllerWithIdentifier:@"StoryListViewController"];
    return controller;
}
@end
