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
@property (nonatomic, weak) id <MITNewsStoryViewControllerDelegate> delegate;
- (IBAction)unwindFromImageGallery:(UIStoryboardSegue*)sender;
- (void)setStory:(MITNewsStory*)story;
@end

@protocol MITNewsStoryViewControllerDelegate <NSObject>
- (void)storyAfterStory:(MITNewsStory*)story completion:(void(^)(MITNewsStory *nextStory, NSError *error))block;
@end