#import <UIKit/UIKit.h>

@class PlaceholderTextView;

@interface FacilitiesSummaryViewController : UIViewController <UITextViewDelegate,UITextFieldDelegate,UIActionSheetDelegate,UINavigationControllerDelegate,UIImagePickerControllerDelegate>
{
    UIActivityIndicatorView *_imageActivityView;
    UIBarButtonItem *_submitButton;
    NSDictionary *_reportData;
    NSData *_imageData;

	BOOL _keyboardIsVisible;
}

@property (nonatomic,retain) IBOutlet UIScrollView* scrollView;
@property (nonatomic,retain) UIBarButtonItem* submitButton;
@property (nonatomic,retain) IBOutlet UILabel* problemLabel;
@property (nonatomic,retain) IBOutlet UIView* shiftingContainingView;
@property (nonatomic,retain) IBOutlet UIView* descriptionContainingView;
@property (nonatomic,retain) IBOutlet UIButton* imageView;
@property (nonatomic,retain) IBOutlet PlaceholderTextView* descriptionTextView;
@property (nonatomic,retain) IBOutlet UIButton* imageButton;
@property (nonatomic,retain) IBOutlet UITextField* emailField;
@property (nonatomic,copy) NSDictionary* reportData;


- (IBAction)selectPicture:(id)sender;
- (IBAction)submitReport:(id)sender;
- (IBAction)dismissKeyboard:(id)sender;
@end
