#import <UIKit/UIKit.h>


@interface FacilitiesSummaryViewController : UIViewController <UITextViewDelegate,UIActionSheetDelegate> {
    UIImageView *_imageView;
    UIButton *_pictureButton;
    UILabel *_problemLabel;
    UILabel *_characterCount;
    UITextView  *_descriptionView;
    UITextField *_emailField;
    NSDictionary *_reportData;
}

@property (nonatomic,retain) IBOutlet UIImageView* imageView;
@property (nonatomic,retain) IBOutlet UIButton* pictureButton;
@property (nonatomic,retain) IBOutlet UILabel* problemLabel;
@property (nonatomic,retain) IBOutlet UITextView* descriptionView;
@property (nonatomic,retain) IBOutlet UITextField* emailField;
@property (nonatomic,retain) IBOutlet UILabel* characterCount;
@property (nonatomic,copy) NSDictionary* reportData;


- (IBAction)selectPicture:(id)sender;
- (IBAction)submitReport:(id)sender;
@end
