#import "MITScannerModule.h"
#import "MITScannerViewController.h"

@implementation MITScannerModule

- (instancetype)init
{
    self = [super initWithName:MITModuleTagQRReader title:@"Scanner"];
    if (self) {
        self.longTitle = @"Scanner";
        self.imageName = MITImageScannerModuleIcon;
    }
    
    return self;
}

- (BOOL)supportsCurrentUserInterfaceIdiom
{
    return YES;
}

- (void)loadRootViewController
{
    UIViewController *rootViewController = [[MITScannerViewController alloc] initWithNibName:nil bundle:nil];
    
    self.rootViewController = rootViewController;
}

@end