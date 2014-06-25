#import <UIKit/UIKit.h>
#import "MITNewsStory.h"

@protocol MITNewsStoryDetailPagingDelegate;

@interface MITNewsStoryDetailController : UIViewController <UIGestureRecognizerDelegate>
@property (nonatomic,strong) NSManagedObjectContext *managedObjectContext;

//@property (nonatomic,weak) IBOutlet UIGestureRecognizer *coverImageGestureRecognizer;

@property (nonatomic,weak) IBOutlet UIScrollView *scrollView;
//@property (nonatomic,weak) IBOutlet UIImageView *coverImageView;
@property (nonatomic,weak) IBOutlet UIWebView *bodyView;

//@property (nonatomic,weak) IBOutlet NSLayoutConstraint *coverImageViewHeightConstraint;
@property (nonatomic,weak) IBOutlet NSLayoutConstraint *bodyViewHeightConstraint;

- (IBAction)unwindFromImageGallery:(UIStoryboardSegue*)sender;
- (void)setStory:(MITNewsStory*)story;

@property (nonatomic, weak) id <MITNewsStoryDetailPagingDelegate> delegate;

@end

@protocol MITNewsStoryDetailPagingDelegate <NSObject>

- (MITNewsStory*)newsDetailController:(MITNewsStoryDetailController*)storyDetailController storyAfterStory:(MITNewsStory*)story;

- (MITNewsStory*)newsDetailController:(MITNewsStoryDetailController*)storyDetailController storyBeforeStory:(MITNewsStory*)story;

- (BOOL)newsDetailController:(MITNewsStoryDetailController*)storyDetailController canPageToStory:(MITNewsStory*)story;

- (void)newsDetailController:(MITNewsStoryDetailController*)storyDetailController didPageToStory:(MITNewsStory*)story;

@end