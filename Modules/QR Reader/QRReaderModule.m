#import "QRReaderModule.h"
#import "QRReaderHistoryViewController.h"
#import "MITModule+Protected.h"


@implementation QRReaderModule

- (id) init {
    self = [super init];
    if (self != nil) {
        self.tag = QRReaderTag;
        self.shortName = @"QR Reader";
        self.longName = @"QR Reader";
        self.iconName = @"qrreader";
    }
    
    return self;
}

- (void)dealloc {
    [super dealloc];
}

- (void)loadModuleHomeController
{
    self.moduleHomeController = [[[QRReaderHistoryViewController alloc] init] autorelease];
}

@end