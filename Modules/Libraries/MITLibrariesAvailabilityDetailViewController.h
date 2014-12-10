#import <UIKit/UIKit.h>

@class MITLibrariesWorldcatItem;

@interface MITLibrariesAvailabilityDetailViewController : UIViewController

@property (nonatomic, strong) MITLibrariesWorldcatItem *worldcatItem;
@property (nonatomic, strong) NSString *libraryName;
@property (nonatomic, strong) NSArray *availabilitiesInLibrary;

@end
