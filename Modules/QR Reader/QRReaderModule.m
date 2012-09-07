#import "QRReaderModule.h"
#import "MITModule+Protected.h"
#import "MITScannerViewController.h"


@implementation QRReaderModule

- (id) init {
    self = [super init];
    if (self != nil) {
        self.tag = QRReaderTag;
        self.shortName = @"Scanner";
        self.longName = @"Scanner";
        self.iconName = @"qrreader";
    }
    
    return self;
}

- (void)dealloc {
    [super dealloc];
}

- (void)loadModuleHomeController
{
    self.moduleHomeController = [[[MITScannerViewController alloc] init] autorelease];
}

#pragma mark Handle Url
- (BOOL)handleLocalPath:(NSString *)localPath query:(NSString *)query
{
    if ([localPath isEqualToString:@""]) {
        [self loadModuleHomeController];
        [[MITAppDelegate() rootNavigationController] popToRootViewControllerAnimated:NO];
        [[MITAppDelegate() rootNavigationController] pushViewController:self.moduleHomeController animated:YES];
        return YES;
    }
    return NO;
}


@end