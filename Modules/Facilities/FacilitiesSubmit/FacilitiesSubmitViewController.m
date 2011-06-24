#import "FacilitiesSubmitViewController.h"
#import "FacilitiesRootViewController.h"
#import "FacilitiesConstants.h"

#import "FacilitiesLocation.h"
#import "FacilitiesRoom.h"
#import "FacilitiesRepairType.h"
#import "NSData+MGTwitterBase64.h"

@interface FacilitiesSubmitViewController ()
@property (retain) MITMobileWebAPI *request;
@property BOOL abortRequest;
@end

@implementation FacilitiesSubmitViewController
@synthesize statusLabel = _statusLabel;
@synthesize progressView = _progressView;
@synthesize completeButton = _completeButton;
@synthesize abortRequest = _abortRequest;
@synthesize reportDictionary = _reportDictionary;
@synthesize request = _request;

- (id)init
{
    self = [self initWithNibName:nil
                          bundle:nil];
    if (self) {
        self.title = @"Submit Report";
        self.reportDictionary = nil;
    }
    return self;
}

- (id)initWithReportData:(NSDictionary*)reportData
{
    self = [self initWithNibName:nil
                           bundle:nil];
    if (self) {
        self.title = @"Submit Report";
        self.reportDictionary = reportData;
    }
    return self;
}

- (void)dealloc
{
    self.statusLabel = nil;
    self.progressView = nil;
    self.completeButton = nil;
    self.reportDictionary = nil;
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
    self.navigationItem.hidesBackButton = NO;
    self.navigationItem.backBarButtonItem.title = @"Cancel";
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    self.request = [[[MITMobileWebAPI alloc] initWithModule:@"facilities"
                                                    command:@"upload"
                                                 parameters:nil] autorelease];
    self.request.jsonDelegate = self;
    self.request.usePOSTMethod = YES;
    [self.request setValue:@""
              forParameter:@"name"];
    [self.request setValue:[self.reportDictionary objectForKey:FacilitiesRequestUserEmailKey]
              forParameter:@"email"];
    
    FacilitiesLocation *location = [self.reportDictionary objectForKey:FacilitiesRequestLocationBuildingKey];
    FacilitiesRoom *room = [self.reportDictionary objectForKey:FacilitiesRequestLocationRoomKey];
    FacilitiesRepairType *type = [self.reportDictionary objectForKey:FacilitiesRequestRepairTypeKey];
    NSString *customLocation = [self.reportDictionary objectForKey:FacilitiesRequestLocationUserBuildingKey];
    NSString *customRoom = [self.reportDictionary objectForKey:FacilitiesRequestLocationUserRoomKey];
    
    if (location) {
        [self.request setValue:location.name
                  forParameter:@"locationName"];
        [self.request setValue:location.number
                  forParameter:@"locationNumber"];
        [self.request setValue:location.number
                  forParameter:@"location"];
    } else {
        [self.request setValue:customLocation
                  forParameter:@"locationNameByUser"];
    }
    
    if (room) {
        [self.request setValue:room.number
                  forParameter:@"roomName"];
    } else {
        [self.request setValue:customRoom
                  forParameter:@"roomNameByUser"];
    }
    
    [self.request setValue:type.name
              forParameter:@"problemType"];
    
    [self.request setValue:[self.reportDictionary objectForKey:FacilitiesRequestUserDescriptionKey]
              forParameter:@"message"];
    
    UIImage *picture = [self.reportDictionary objectForKey:FacilitiesRequestImageKey];
    if (picture) {
        NSData *pictureData = UIImageJPEGRepresentation(picture,0.75);
        [self.request setValue:[pictureData base64EncodingWithLineLength:64]
                  forParameter:@"image"];
        [self.request setValue:@"image/jpeg"
                  forParameter:@"imageFormat"];
    }
    
    dispatch_async(dispatch_get_main_queue(), ^(void) {
        [self.progressView setProgress:0.0];
        self.progressView.hidden = NO;
        self.completeButton.hidden = YES;
        [self.statusLabel setText:@"Uploading report to the server"];
        [self.request start];
    });
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.request cancel];
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

#pragma mark - JSONDelegate Methods
- (void)request:(MITMobileWebAPI *)request jsonLoaded:(id)JSONObject
{
    self.progressView.hidden = YES;
    self.completeButton.hidden = NO;
    self.statusLabel.text = @"Report successfully submitted";
    self.request = nil;
    return;
}

- (void)request:(MITMobileWebAPI *)request totalBytesWritten:(NSInteger)bytesWritten totalBytesExpected:(NSInteger)bytesExpected
{
    NSLog(@"%d/%d",bytesWritten,bytesExpected);
    [self.progressView setProgress:(double)bytesWritten/(double)bytesExpected];
}

- (BOOL)request:(MITMobileWebAPI *)request shouldDisplayStandardAlertForError:(NSError *)error
{
    self.request = nil;
    return NO;
}

@end
