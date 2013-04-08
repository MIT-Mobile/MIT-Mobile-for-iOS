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
    
    self.scrollView = [[UIScrollView alloc] initWithFrame:self.view.bounds];
    self.scrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
    self.scrollView.delegate = self;
    self.scrollView.contentSize = CGSizeMake((viewPadding * 2) + (CGRectGetHeight(self.view.bounds) * 3), CGRectGetWidth(self.view.bounds));
    self.scrollView.pagingEnabled = YES;
    
    [self.view addSubview:self.scrollView];
    
	self.previous = [[DiningHallMenuCompareView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetHeight(self.view.bounds), CGRectGetWidth(self.view.bounds))];
    self.previous.date = [NSDate dateWithTimeIntervalSinceNow:-SECONDS_IN_DAY];
    
    self.current = [[DiningHallMenuCompareView alloc] initWithFrame:CGRectMake(CGRectGetWidth(self.previous.bounds) + viewPadding, 0, CGRectGetHeight(self.view.bounds), CGRectGetWidth(self.view.bounds))];
    self.current.date = [NSDate dateWithTimeIntervalSinceNow:0];
    
    self.next = [[DiningHallMenuCompareView alloc] initWithFrame:CGRectMake(CGRectGetMaxX(self.current.frame) + viewPadding, 0, CGRectGetHeight(self.view.bounds), CGRectGetWidth(self.view.bounds))];
    self.next.date = [NSDate dateWithTimeIntervalSinceNow:+SECONDS_IN_DAY];
    
    [self.scrollView setContentOffset:self.current.frame.origin animated:NO];
    
    [self.scrollView addSubview:self.previous];
    [self.scrollView addSubview:self.current];
    [self.scrollView addSubview:self.next];
    
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



@end
