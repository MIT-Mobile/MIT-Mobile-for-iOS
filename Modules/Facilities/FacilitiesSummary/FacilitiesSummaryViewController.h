#import <UIKit/UIKit.h>


@interface FacilitiesSummaryViewController : UIViewController <UITextViewDelegate,UIActionSheetDelegate,UINavigationControllerDelegate,UIImagePickerControllerDelegate,UIAlertViewDelegate>
{
    UIScrollView *_scrollView;
    UIImageView *_imageView;
    UILabel *_problemLabel;
    UITextView  *_descriptionView;
    UITextField *_emailField;

    UIView *_overlayView;
    UIProgressView *_uploadProgress;
    UILabel *_uploadStatus;
    UIButton *_returnButton;
    NSDictionary *_reportData;

    BOOL _keyboardIsVisible;
}

@property (nonatomic,retain) IBOutlet UIScrollView* scrollView;
@property (nonatomic,retain) IBOutlet UIImageView* imageView;
@property (nonatomic,retain) IBOutlet UILabel* problemLabel;
@property (nonatomic,retain) IBOutlet UITextView* descriptionView;
@property (nonatomic,retain) IBOutlet UITextField* emailField;
@property (nonatomic, retain) UIView *overlayView;
@property (nonatomic,retain) UIProgressView* uploadProgress;
@property (nonatomic,retain) UILabel* uploadStatus;
@property (nonatomic,retain) UIButton* returnButton;

@property (nonatomic,copy) NSDictionary* reportData;


- (IBAction)selectPicture:(id)sender;
- (IBAction)submitReport:(id)sender;
- (IBAction)dismissKeyboard:(id)sender;
@end
