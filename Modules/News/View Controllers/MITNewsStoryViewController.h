#import <UIKit/UIKit.h>
#import "MITNewsStory.h"

@protocol MITNewsStoryViewControllerDelegate;

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

@property (nonatomic, weak) id <MITNewsStoryViewControllerDelegate> delegate;

@end

@protocol MITNewsStoryViewControllerDelegate <NSObject>

- (MITNewsStory*)newsDetailController:(MITNewsStoryViewController*)storyDetailController storyAfterStory:(MITNewsStory*)story;

- (MITNewsStory*)newsDetailController:(MITNewsStoryViewController*)storyDetailController storyBeforeStory:(MITNewsStory*)story;

- (BOOL)newsDetailController:(MITNewsStoryViewController*)storyDetailController canPageToStory:(MITNewsStory*)story;

- (void)newsDetailController:(MITNewsStoryViewController*)storyDetailController didPageToStory:(MITNewsStory*)story;

@end