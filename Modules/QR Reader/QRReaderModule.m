#import "QRReaderModule.h"

@implementation QRReaderModule
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
    UIUserInterfaceIdiom currentUserInterfaceIdiom = [UIDevice currentDevice].userInterfaceIdiom;

    return (currentUserInterfaceIdiom == UIUserInterfaceIdiomPhone);
}

- (void)loadRootViewController
{
    MITScannerViewController *rootViewController = [[MITScannerViewController alloc] init];
    self.rootViewController = rootViewController;
}

- (void)didReceiveRequestWithURL:(NSURL*)url
{
    [super didReceiveRequestWithURL:url];
    [self.navigationController popToViewController:self.rootViewController animated:NO];
}

@end