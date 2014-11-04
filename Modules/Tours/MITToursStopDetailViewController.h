#import <UIKit/UIKit.h>
#import "MITToursTour.h"
#import "MITToursStop.h"

@protocol MITToursStopDetailViewControllerDelegate;

@interface MITToursStopDetailViewController : UIViewController

@property (nonatomic, strong) MITToursTour *tour;
@property (nonatomic, strong) MITToursStop *stop;
@property (nonatomic, weak) id<MITToursStopDetailViewControllerDelegate> delegate;

- (instancetype)initWithTour:(MITToursTour *)tour stop:(MITToursStop *)stop nibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil;

@end

@protocol MITToursStopDetailViewControllerDelegate <NSObject>

@optional
- (void)stopDetailViewControllerTitleDidScrollBelowTitle:(MITToursStopDetailViewController *)detailViewController;
- (void)stopDetailViewControllerTitleDidScrollAboveTitle:(MITToursStopDetailViewController *)detailViewController;

@end
