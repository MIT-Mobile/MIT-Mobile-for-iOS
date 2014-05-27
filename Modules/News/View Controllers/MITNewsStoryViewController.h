#import <UIKit/UIKit.h>
#import "MITNewsStory.h"

@interface MITNewsStoryViewController : UIViewController <UIGestureRecognizerDelegate>
@property (nonatomic,strong) NSManagedObjectContext *managedObjectContext;

@property (nonatomic,weak) IBOutlet UIGestureRecognizer *coverImageGestureRecognizer;

@property (nonatomic,weak) IBOutlet UIScrollView *scrollView;
@property (nonatomic,weak) IBOutlet UIImageView *coverImageView;
@property (nonatomic,weak) IBOutlet UIWebView *bodyView;

@property (nonatomic,weak) IBOutlet NSLayoutConstraint *coverImageViewHeightConstraint;
@property (nonatomic,weak) IBOutlet NSLayoutConstraint *bodyViewHeightConstraint;

- (IBAction)unwindFromImageGallery:(UIStoryboardSegue*)sender;
- (void)setStory:(MITNewsStory*)story;

@end

@interface MITNewsStoryActivityItemProvider : UIActivityItemProvider

- (id) initWithEmailBodyText:(NSString *)emailBodyText;

@end
