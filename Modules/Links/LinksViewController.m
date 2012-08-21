
#import "LinksViewController.h"

@interface LinksViewController ()

@end

@implementation LinksViewController
@synthesize linkResults;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    
}

- (void) viewDidAppear:(BOOL)animated
{
    [self queryForLinks];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void) showLoadingView {
    _loadingView = [[MITLoadingActivityView alloc] initWithFrame:CGRectInset(self.view.frame, 0, 0)];
    [self.view addSubview:_loadingView];
}

- (void) queryForLinks
{
    api = [MITMobileWebAPI jsonLoadedDelegate:self];
    requestWasDispatched = [api requestObject:[NSDictionary dictionaryWithObject:@"links" forKey:@"module"]];
    
    if (requestWasDispatched) {
        [self showLoadingView];
    }
    
}

#pragma mark - JSONLoadedDelegate

- (void)cleanUpConnection {
	requestWasDispatched = NO;
	[_loadingView removeFromSuperview];
}

- (void)request:(MITMobileWebAPI *)request jsonLoaded:(id)result
{
    [self cleanUpConnection];
    
    if (result && [result isKindOfClass:[NSArray class]]) {
		self.linkResults = result;
	} else {
		self.linkResults = nil;
	}
}

- (BOOL)request:(MITMobileWebAPI *)request shouldDisplayStandardAlertForError: (NSError *)error
{
    return false;
}


@end
