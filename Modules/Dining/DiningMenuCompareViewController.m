//
//  DiningMenuCompareViewController.m
//  MIT Mobile
//
//  Created by Austin Emmons on 3/27/13.
//
//

#import "DiningMenuCompareViewController.h"
#import "DiningHallMenuCompareView.h"

#define SECONDS_IN_DAY 86400

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
    int viewPadding = 10;
    
    [super viewDidLoad];
    self.view.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
    self.view.autoresizesSubviews = YES;
    
    CGRect frame = CGRectMake(-viewPadding, 0, CGRectGetWidth(self.view.bounds) + (viewPadding * 2), CGRectGetHeight(self.view.bounds));
    
    self.scrollView = [[UIScrollView alloc] initWithFrame:self.view.bounds];
    self.scrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
    self.scrollView.delegate = self;
    self.scrollView.contentSize = CGSizeMake((viewPadding * 2) + (CGRectGetHeight(self.view.bounds) * 3), CGRectGetWidth(self.view.bounds));
    self.scrollView.pagingEnabled = YES;
    
    [self.view addSubview:self.scrollView];
    
    self.datePointer = [NSDate dateWithTimeIntervalSinceNow:0];
    
	self.previous = [[DiningHallMenuCompareView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetHeight(self.view.bounds), CGRectGetWidth(self.view.bounds))];
    self.current = [[DiningHallMenuCompareView alloc] initWithFrame:CGRectMake(CGRectGetWidth(self.previous.bounds) + viewPadding, 0, CGRectGetHeight(self.view.bounds), CGRectGetWidth(self.view.bounds))];
    self.next = [[DiningHallMenuCompareView alloc] initWithFrame:CGRectMake(CGRectGetMaxX(self.current.frame) + viewPadding, 0, CGRectGetHeight(self.view.bounds), CGRectGetWidth(self.view.bounds))];
    [self updateDateHeaders];
    
    [self.scrollView setContentOffset:self.current.frame.origin animated:NO];
    
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
    } else if (scrollView.contentOffset.x < scrollView.frame.size.width) {
        // scroll to the left
        self.datePointer = [NSDate dateWithTimeInterval:-SECONDS_IN_DAY sinceDate:self.datePointer];
    }
    [self updateDateHeaders];
    // TODO: need to refresh comparison views with date's data
    
    [scrollView scrollRectToVisible:self.current.frame animated:NO]; // always recenter on center view
    
}



@end
