#import <UIKit/UIKit.h>


@interface FacilitiesSummaryViewController : UIViewController <UITextViewDelegate,UIActionSheetDelegate,UINavigationControllerDelegate,UIImagePickerControllerDelegate>
{
    UIScrollView *_scrollView;
    UIImageView *_imageView;
    UIButton *_imageButton;
    UILabel *_problemLabel;
    UITextView  *_descriptionView;
    UITextField *_emailField;
    NSDictionary *_reportData;

	BOOL _keyboardIsVisible;
}

@property (nonatomic,retain) IBOutlet UIScrollView* scrollView;
@property (nonatomic,retain) IBOutlet UIImageView* imageView;
@property (nonatomic,retain) IBOutlet UIButton* imageButton;
@property (nonatomic,retain) IBOutlet UILabel* problemLabel;
@property (nonatomic,retain) IBOutlet UITextView* descriptionView;
@property (nonatomic,retain) IBOutlet UITextField* emailField;
@property (nonatomic,copy) NSDictionary* reportData;


- (IBAction)selectPicture:(id)sender;
- (IBAction)submitReport:(id)sender;
- (IBAction)dismissKeyboard:(id)sender;
@end
