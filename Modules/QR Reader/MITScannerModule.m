#import "MITScannerModule.h"


#import "MITScannerViewController.h"


@implementation MITScannerModule

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

- (BOOL)supportsUserInterfaceIdiom:(UIUserInterfaceIdiom)idiom
{
    return YES;
}

- (UIViewController*)createHomeViewControllerForPhoneIdiom
{
    return [[MITScannerViewController alloc] init];
}

- (UIViewController*)createHomeViewControllerForPadIdiom
{
    return [[MITScannerViewController alloc] init];
}

@end