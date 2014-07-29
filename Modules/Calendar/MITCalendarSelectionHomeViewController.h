#import <UIKit/UIKit.h>
#import "MITEventList.h"

@class MITCalendarSelectionHomeViewController;

@protocol MITCalendarSelectionDelegate <NSObject>

- (void)calendarSelectionViewController:(MITCalendarSelectionHomeViewController *)viewController
                     didSelectEventList:(MITEventList *)eventList;

@end

@interface MITCalendarSelectionHomeViewController : UITableViewController

//@property (nonatomic, strong) NSArray *categories;

@property (nonatomic, weak) id<MITCalendarSelectionDelegate> delegate;

@end
