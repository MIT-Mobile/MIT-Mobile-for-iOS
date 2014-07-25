#import <UIKit/UIKit.h>

@class MITDatePickerViewController;

@protocol MITDatePickerViewControllerDelegate <NSObject>

- (void)datePickerDidCancel:(MITDatePickerViewController *)datePicker;
- (void)datePicker:(MITDatePickerViewController *)datePicker didSelectDate:(NSDate *)date;

@end

@interface MITDatePickerViewController : UIViewController

@property (nonatomic, weak) id<MITDatePickerViewControllerDelegate> delegate;

@end
