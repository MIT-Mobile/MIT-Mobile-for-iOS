#import <UIKit/UIKit.h>

@class MITCalendarsCalendar;
@protocol MITEventSearchTypeAheadViewControllerDelegate;

@interface MITEventSearchTypeAheadViewController : UIViewController

@property (nonatomic, weak) id<MITEventSearchTypeAheadViewControllerDelegate> delegate;
@property (nonatomic, strong) MITCalendarsCalendar *currentCalendar;

- (void)updateWithTypeAheadText:(NSString *)typeAheadText;

@end

@protocol MITEventSearchTypeAheadViewControllerDelegate <NSObject>

- (void)eventSearchTypeAheadController:(MITEventSearchTypeAheadViewController *)typeAheadController didSelectSuggestion:(NSString *)suggestion;
- (void)eventSearchTypeAheadControllerDidClearFilters:(MITEventSearchTypeAheadViewController *)typeAheadController;

@end