#import "AnniversaryModule.h"
#import "MIT150ViewController.h"
#import "CoreDataManager.h"

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
		[self becomeActiveTab];
		return YES;
	}
    else if ([localPath isEqualToString:@"about"]) {
        [self.homeController showWelcome];
		[self becomeActiveTab];
        return YES;
    }
    if ([localPath isEqualToString:@"corridor"]) {
        [self.homeController showCorridor];
        return YES;
    }
    return NO;
}

- (UIViewController *)moduleHomeController {
    if (!self.homeController) {
        self.homeController = [[[MIT150ViewController alloc] initWithStyle:UITableViewStylePlain] autorelease];
    }
    return self.homeController;
}

@end
