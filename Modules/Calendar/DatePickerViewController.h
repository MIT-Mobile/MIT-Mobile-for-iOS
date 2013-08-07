#import <UIKit/UIKit.h>

@protocol DatePickerViewControllerDelegate;

@interface DatePickerViewController : UIViewController
@property (nonatomic, strong) NSDate *date;
@property (nonatomic, weak) id<DatePickerViewControllerDelegate> delegate;

- (void)navBarButtonPressed:(id)sender;
@end

@protocol DatePickerViewControllerDelegate <NSObject>

- (void)datePickerViewControllerDidCancel:(DatePickerViewController *)controller;
- (void)datePickerViewController:(DatePickerViewController *)controller didSelectDate:(NSDate *)date;
- (void)datePickerValueChanged:(id)sender;

@end