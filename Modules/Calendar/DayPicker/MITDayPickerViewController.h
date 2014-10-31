//
//  MITDayPickerViewController.h
//  MIT Mobile
//
//  Created by Logan Wright on 10/31/14.
//
//

#import <UIKit/UIKit.h>

@class MITDayPickerViewController;
@protocol MITDayPickerViewControllerDelegate <NSObject>
- (void)dayPickerViewController:(MITDayPickerViewController *)dayPickerViewController dateDidUpdate:(NSDate *)date;
@end

@interface MITDayPickerViewController : UIViewController
@property (weak, nonatomic) id<MITDayPickerViewControllerDelegate>delegate;
@property (strong, nonatomic) NSDate *currentlyDisplayedDate;
@end
