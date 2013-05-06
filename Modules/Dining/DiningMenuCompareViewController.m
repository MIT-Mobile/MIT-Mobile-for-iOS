#import "DiningMenuCompareViewController.h"
#import "DiningHallMenuCompareView.h"

#define SECONDS_IN_DAY 86400
#define DAY_VIEW_PADDING 5      // padding on each side of day view. doubled when two views are adjacent

@interface DiningMenuCompareViewController () <UIScrollViewDelegate>

@property (nonatomic, strong) UIScrollView *scrollView;

@property (nonatomic, strong) NSDate *datePointer;

@property (nonatomic, strong) DiningHallMenuCompareView * previous;     // on left
@property (nonatomic, strong) DiningHallMenuCompareView * current;      // center
@property (nonatomic, strong) DiningHallMenuCompareView * next;         // on right

@end

@implementation DiningMenuCompareViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
    self.view.autoresizesSubviews = YES;
    
    // The scrollview has a frame that is just larger than the viewcontrollers view bounds so that padding can be seen between scrollable pages.
    // Frames are also inverted (height => width, width => height) because when the view loads the rotation has not yet occurred.
    CGRect frame = CGRectMake(-DAY_VIEW_PADDING, 0, CGRectGetHeight(self.view.bounds) + (DAY_VIEW_PADDING * 2), CGRectGetWidth(self.view.bounds));
    
    self.scrollView = [[UIScrollView alloc] initWithFrame:frame];
    self.scrollView.delegate = self;
    self.scrollView.contentSize = CGSizeMake((DAY_VIEW_PADDING * 6) + (CGRectGetHeight(self.view.bounds) * 3), CGRectGetWidth(self.view.bounds));
    self.scrollView.pagingEnabled = YES;
    
    [self.view addSubview:self.scrollView];
    
    self.datePointer = [NSDate dateWithTimeIntervalSinceNow:0];
    
	self.previous = [[DiningHallMenuCompareView alloc] initWithFrame:CGRectMake(DAY_VIEW_PADDING, 0, CGRectGetHeight(self.view.bounds), CGRectGetWidth(self.view.bounds))];
    self.current = [[DiningHallMenuCompareView alloc] initWithFrame:CGRectMake(CGRectGetMaxX(self.previous.frame) + (DAY_VIEW_PADDING * 2), 0, CGRectGetHeight(self.view.bounds), CGRectGetWidth(self.view.bounds))];
    self.next = [[DiningHallMenuCompareView alloc] initWithFrame:CGRectMake(CGRectGetMaxX(self.current.frame) + (DAY_VIEW_PADDING * 2), 0, CGRectGetHeight(self.view.bounds), CGRectGetWidth(self.view.bounds))];
                                                                        // (viewPadding * 2) is used because each view has own padding, so there are 2 padded spaces to account for
    [self updateDateHeaders];
    
    [self.scrollView setContentOffset:CGPointMake(self.current.frame.origin.x - DAY_VIEW_PADDING, 0) animated:NO];  // have to subtract DAY_VIEW_PADDING because scrollview sits offscreen at offset.
    
    [self.scrollView addSubview:self.previous];
    [self.scrollView addSubview:self.current];
    [self.scrollView addSubview:self.next];
}

- (void) updateDateHeaders
{
    self.previous.date = [NSDate dateWithTimeInterval:-SECONDS_IN_DAY sinceDate:self.datePointer];
    self.current.date = self.datePointer;
    self.next.date = [NSDate dateWithTimeInterval:SECONDS_IN_DAY sinceDate:self.datePointer];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}


- (void) willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)orientation duration:(NSTimeInterval)duration
{
    if (UIInterfaceOrientationIsPortrait(orientation)) {
        self.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
        [self dismissModalViewControllerAnimated:YES];
    }
}

- (void) scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    // Handle infinite scroll between 3 views. Returns to center view so there is always a view on the left and right
    if (scrollView.contentOffset.x > scrollView.frame.size.width) {
        // scroll to the right
        self.datePointer = [NSDate dateWithTimeInterval:SECONDS_IN_DAY sinceDate:self.datePointer];
        [self.current resetScrollOffset]; // need to reset scroll offset so user always starts at (0,0) in collectionView
    } else if (scrollView.contentOffset.x < scrollView.frame.size.width) {
        // scroll to the left
        self.datePointer = [NSDate dateWithTimeInterval:-SECONDS_IN_DAY sinceDate:self.datePointer];
        [self.current resetScrollOffset];
    }
    [self updateDateHeaders];
    // TODO: need to refresh comparison views with date's data
    
    [scrollView setContentOffset:CGPointMake(self.current.frame.origin.x - DAY_VIEW_PADDING, 0) animated:NO]; // always return to center view
    
}



@end
