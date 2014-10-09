#import "LinksModule.h"
#import "LinksViewController.h"

@implementation LinksModule
- (instancetype)init {
    self = [super initWithName:MITModuleTagLinks title:@"Links"];
    if (self) {
        self.imageName = @"webmitedu";
    }
    
    return self;
}

- (void)loadRootViewController
{
    LinksViewController *rootViewController = [[LinksViewController alloc] init];
    self.rootViewController = rootViewController;
}

#pragma mark URL Request handling
- (void)didReceiveRequestWithURL:(NSURL *)url
{
    [super didReceiveRequestWithURL:url];
    [self.navigationController popToViewController:self.rootViewController animated:NO];
}

@end
