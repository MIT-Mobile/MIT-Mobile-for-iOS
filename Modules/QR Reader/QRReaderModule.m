#import "QRReaderModule.h"
#import "QRReaderHistoryViewController.h"
#import "MITModule+Protected.h"
#import "MITScannerViewController.h"


@implementation QRReaderModule

- (id) init {
    self = [super init];
    if (self != nil) {
        self.tag = QRReaderTag;
        self.shortName = @"Scanner";
        self.longName = @"Scanner";
        self.iconName = @"scanner";
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

@end