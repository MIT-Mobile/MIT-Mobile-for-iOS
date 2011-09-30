#import "QRReaderModule.h"

#import "QRReaderHistoryViewController.h"


@implementation QRReaderModule

- (id) init {
    self = [super init];
    if (self != nil) {
        self.tag = QRReaderTag;
        self.shortName = @"QR Reader";
        self.longName = @"QR Reader";
        self.iconName = @"qrreader";
        _viewController = nil;
    }
    return self;
}

- (void)dealloc {
    [_viewController release];
    [super dealloc];
}

- (UIViewController *)moduleHomeController {
    if (_viewController == nil) {
        _viewController = [[QRReaderHistoryViewController alloc] init];
    }
    
    return _viewController;
}

@end