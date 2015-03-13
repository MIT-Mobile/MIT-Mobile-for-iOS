
#import <UIKit/UIKit.h>

@class MITDayPickerViewController;

@protocol MITDayPickerViewControllerDelegate <NSObject>

@optional

/**
 *  Delegate method that gets called whenever the day picker controller has a 
 *  new date selected. This is called for both programmatic and user-initiated
 *  date updates.
 *
 *  @param dayPickerViewController The current picker
 *  @param newDate                 The new date that was selected
 *  @param oldDate                 The previously selected date
 */
- (void)dayPickerViewController:(MITDayPickerViewController *)dayPickerViewController dateDidUpdateToDate:(NSDate *)newDate fromOldDate:(NSDate *)oldDate;

@end

@interface MITDayPickerViewController : UIViewController

/**
 *  Delegate, implements the MITDayPickerViewControllerDelegate protocol
 */
@property (weak, nonatomic) id<MITDayPickerViewControllerDelegate>delegate;

/**
 *  The currently selected date
 */
@property (strong, nonatomic) NSDate *currentlyDisplayedDate;

/**
 *  The color of the today indicator. Defaults to MIT red.
 */
@property (strong, nonatomic) UIColor *todayColor;

/**
 *  The color of the currently selected day
 */
@property (strong, nonatomic) UIColor *selectedDayColor;

/**
 *  Reloads the day picker's collectionview
 */
- (void)reloadDayPicker;

@end
