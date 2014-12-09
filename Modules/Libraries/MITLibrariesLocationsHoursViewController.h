#import <UIKit/UIKit.h>

@class MITLibrariesLibrary;

@protocol MITLibrariesLocationsIPadDelegate <NSObject>

- (void)showLibraryDetailForLibrary:(MITLibrariesLibrary *)library;

@end

@interface MITLibrariesLocationsHoursViewController : UITableViewController

@property (nonatomic, strong) id<MITLibrariesLocationsIPadDelegate>delegate;

@end
