#import <UIKit/UIKit.h>

@interface MITNewsMediaGalleryViewController : UIViewController

// Should be an array of MITNewsImageRepresentation objects
@property (nonatomic,strong) NSArray *galleryImages;
@property (nonatomic, strong) NSURL *storyLink;
@property (nonatomic, strong) NSString *storyTitle;
@property (nonatomic,strong) NSManagedObjectContext *managedObjectContext;

@property (nonatomic,weak) IBOutlet UIPageViewController *pageViewController;
@property (nonatomic,weak) IBOutlet UINavigationBar *navigationBar;
@property (nonatomic,weak) IBOutlet UIView *captionView;
@property (nonatomic,weak) IBOutlet UILabel *creditLabel;
@property (nonatomic,weak) IBOutlet UILabel *descriptionLabel;

- (IBAction)shareImage:(id)sender;
- (IBAction)toggleUI:(id)sender;
- (IBAction)resetZoom:(UIGestureRecognizer*)sender;
@end
