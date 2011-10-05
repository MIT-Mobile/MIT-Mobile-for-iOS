#import "AnniversaryModule.h"
#import "MIT150ViewController.h"
#import "CoreDataManager.h"
#import "MITModule+Protected.h"

@implementation AnniversaryModule
@synthesize homeController;

- (id) init {
    self = [super init];
    if (self != nil) {
        self.tag = AnniversaryTag;
        self.shortName = @"MIT150";
        self.longName = @"MIT150";
        self.iconName = @"mit150";
    }
    return self;
}

- (BOOL)handleLocalPath:(NSString *)localPath query:(NSString *)query {
	if ([localPath isEqualToString:@""]) {
        [[MITAppDelegate() springboardController] pushModuleWithTag:self.tag];
		return YES;
	}
    else if ([localPath isEqualToString:@"about"]) {
        [self.homeController showWelcome];
        return YES;
    }
    if ([localPath isEqualToString:@"corridor"]) {
        [self.homeController showCorridor];
        return YES;
    }
    return NO;
}

- (void)loadModuleHomeController
{
    MIT150ViewController *controller = [[[MIT150ViewController alloc] initWithStyle:UITableViewStylePlain] autorelease];
    self.homeController = controller;
    self.moduleHomeController = controller;
}

@end
