#import "FacilitiesSubmitViewController.h"

#import "FacilitiesRootViewController.h"

@implementation FacilitiesSubmitViewController
@synthesize statusLabel = _statusLabel;
@synthesize progressView = _progressView;
@synthesize completeButton = _completeButton;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)dealloc
{
    self.statusLabel = nil;
    self.progressView = nil;
    self.completeButton = nil;
    [super dealloc];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    
}

#pragma mark - View lifecycle
- (void)loadView {
    CGRect frame = [[UIScreen mainScreen] applicationFrame];
    
    if (self.navigationController.navigationBarHidden == NO) {
        frame.size.height -= self.navigationController.navigationBar.frame.size.height;
    }
    
    UIView *mainView = [[[UIView alloc] initWithFrame:frame] autorelease];
    
    {
        self.progressView = [[[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault] autorelease];
        CGRect progressFrame = CGRectMake(15,
                                          (frame.size.height - self.progressView.frame.size.height) / 2.0,
                                          frame.size.width - 30,
                                          self.progressView.frame.size.height);
        
        self.progressView.frame = progressFrame;
        [mainView addSubview:self.progressView];
    }
    
    {
        CGFloat height = 32;
        CGRect labelFrame = CGRectMake(15,
                                       self.progressView.frame.origin.y - height,
                                       frame.size.width - 30,
                                       height);

        self.statusLabel = [[[UILabel alloc] initWithFrame:labelFrame] autorelease];
        self.statusLabel.textAlignment = UITextAlignmentCenter;
        self.statusLabel.backgroundColor = [UIColor clearColor];
        [mainView addSubview:self.statusLabel];
    }
    
    {
        CGRect buttonFrame = CGRectZero;
        buttonFrame.size = CGSizeMake(128, 32);
        buttonFrame.origin = CGPointMake((frame.size.width - buttonFrame.size.width) / 2.0,
                                         self.progressView.frame.origin.y);
        self.completeButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        self.completeButton.frame = buttonFrame;
        self.completeButton.hidden = YES;
        [self.completeButton setTitle:@"Return to start"
                             forState:UIControlStateNormal];
        [self.completeButton addTarget:self
                                action:@selector(reportCompleted:)
                      forControlEvents:UIControlEventTouchUpInside];
        [mainView addSubview:self.completeButton];
    }
    
    
    [self setView:mainView];
}

- (void)viewWillAppear:(BOOL)animated {
    self.navigationItem.hidesBackButton = YES;
}

- (void)viewDidAppear:(BOOL)animated {
    dispatch_queue_t demoQueue = dispatch_queue_create("edu.mit.mobile.ProgressDemo", 0);
    NSUInteger imageSize = 768000; // Bytes
    NSUInteger uploadSpeed = 50000; // Bps
    
    [self.progressView setProgress:0.0];
    self.progressView.hidden = NO;
    self.completeButton.hidden = YES;
    [self.statusLabel setText:@"Uploading report to the server"];
    
    int blkCount = 0;
    for (NSUInteger chunk = 0; chunk < imageSize; chunk += uploadSpeed) {
        dispatch_async(demoQueue, ^(void) {
            dispatch_async(dispatch_get_main_queue(), ^(void) {
                NSMutableString *string = [NSMutableString string];
                for (int i = 0; i < ((blkCount % 3) + 1); i++) {
                    [string appendString:@"."];
                }
                
                [self.statusLabel setText:[NSString stringWithFormat:@"Uploading picture%@",string]];
                [self.progressView setProgress:((float)chunk / (float)imageSize)];
            });
            
            [NSThread sleepForTimeInterval:1.0f];
        });
        blkCount++;
    }

    dispatch_async(demoQueue, ^(void) {
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            [self.statusLabel setText:@"Successfully submitted your report"];
            self.progressView.hidden = YES;
            self.completeButton.hidden = NO;
        });
    });
    
    dispatch_release(demoQueue);
}

- (void)viewDidUnload
{
    self.statusLabel = nil;
    self.progressView = nil;
    self.completeButton = nil;
    [super viewDidUnload];    
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (IBAction)reportCompleted:(id)sender {
    for (UIViewController *controller in self.navigationController.viewControllers) {
        if ([controller isKindOfClass:[FacilitiesRootViewController class]]) {
            [self.navigationController popToViewController:controller
                                                  animated:YES];
            break;
        }
    }
}

@end
