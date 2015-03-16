#import "MITMobiusModule.h"

@implementation MITMobiusModule
- (instancetype)init {
    self = [super initWithName:MITModuleTagMarty title:@"Marty"];
    if (self) {
        self.longTitle = @"Marty";
        self.imageName = MITImageMartyModuleIcon;
    }
    return self;
}

- (BOOL)supportsCurrentUserInterfaceIdiom
{
    return YES;
}

- (void)loadViewController
{
    UIUserInterfaceIdiom userInterfaceIdiom = [[UIDevice currentDevice] userInterfaceIdiom];

    UIStoryboard *storyboard = nil;
    if (userInterfaceIdiom == UIUserInterfaceIdiomPad) {
        storyboard = [UIStoryboard storyboardWithName:@"Marty_pad" bundle:nil];
    } else if (userInterfaceIdiom == UIUserInterfaceIdiomPhone) {
        storyboard = [UIStoryboard storyboardWithName:@"Marty_phone" bundle:nil];
    } else {
        @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"unknown user interface idiom" userInfo:nil];
    }

    self.viewController = [storyboard instantiateInitialViewController];
}
	
@end
