#import "FacilitiesSubmitViewController.h"
#import "FacilitiesRootViewController.h"
#import "FacilitiesConstants.h"
#import "NSData+MGTwitterBase64.h"
#import "FacilitiesLocation.h"
#import "FacilitiesRoom.h"
#import "FacilitiesRepairType.h"
#import "MITUIConstants.h"
#import "MobileRequestOperation.h"

@interface FacilitiesSubmitViewController ()
@property BOOL abortRequest;

- (void)setStatusText:(NSString *)string;
- (void)showSuccess;
- (void)showFailure;

@end

@implementation FacilitiesSubmitViewController
@synthesize statusLabel = _statusLabel;
@synthesize progressView = _progressView;
@synthesize completeButton = _completeButton;
@synthesize abortRequest = _abortRequest;
@synthesize reportDictionary = _reportDictionary;

- (void)dealloc {
    self.statusLabel = nil;
    self.progressView = nil;
    self.completeButton = nil;
    self.reportDictionary = nil;
    [super dealloc];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    
}

#pragma mark - View lifecycle
- (void)viewDidLoad {
    self.title = @"Submit Report";

    CGRect frame = self.view.frame;
    CGFloat margin = 20.0;
    
    {
        self.progressView = [[[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault] autorelease];
        CGRect progressFrame = CGRectMake(margin,
                                          floor((frame.size.height - self.progressView.frame.size.height) / (1 / (1 - (1 / 1.62)))),
                                          frame.size.width - (2.0 * margin),
                                          self.progressView.frame.size.height);
        self.progressView.frame = progressFrame;
        [self.view addSubview:self.progressView];
    }
    
    {
        CGRect buttonFrame = CGRectZero;
        buttonFrame.size = CGSizeMake(180.0, 45.0);
        buttonFrame.origin = CGPointMake((frame.size.width - buttonFrame.size.width) / 2.0,
                                         self.progressView.frame.origin.y);
        self.completeButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        self.completeButton.frame = buttonFrame;
        self.completeButton.hidden = YES;
        self.completeButton.titleLabel.font = [UIFont fontWithName:BOLD_FONT size:CELL_STANDARD_FONT_SIZE];
        [self.completeButton setTitleColor:CELL_STANDARD_FONT_COLOR forState:UIControlStateNormal];

        [self.completeButton setTitle:@"Return to Start"
                             forState:UIControlStateNormal];
        [self.completeButton addTarget:self
                                action:@selector(reportCompleted:)
                      forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:self.completeButton];
    }
    
    {
        // note: labelFrame is mostly overridden by -setStatusText:
        CGRect labelFrame = CGRectMake(margin,
                                       self.progressView.frame.origin.y - 250.0,
                                       frame.size.width - (2.0 * margin),
                                       250.0);
        
        self.statusLabel = [[[UILabel alloc] initWithFrame:labelFrame] autorelease];
        self.statusLabel.textAlignment = UITextAlignmentCenter;
        self.statusLabel.lineBreakMode = UILineBreakModeWordWrap;
        self.statusLabel.numberOfLines = 0;
        self.statusLabel.backgroundColor = [UIColor clearColor];
        [self.view addSubview:self.statusLabel];
    }
}

- (void)viewWillAppear:(BOOL)animated {
    self.navigationItem.hidesBackButton = NO;
    self.navigationItem.backBarButtonItem.title = @"Cancel";
    [self setStatusText:@"Preparing report..."];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithCapacity:8];
    [params setObject:@"" forKey:@"name"];
    [params setObject:[self.reportDictionary objectForKey:FacilitiesRequestUserEmailKey] forKey:@"email"];
    
    FacilitiesLocation *location = [self.reportDictionary objectForKey:FacilitiesRequestLocationBuildingKey];
    FacilitiesRoom *room = [self.reportDictionary objectForKey:FacilitiesRequestLocationRoomKey];
    FacilitiesRepairType *type = [self.reportDictionary objectForKey:FacilitiesRequestRepairTypeKey];
    NSString *customLocation = [self.reportDictionary objectForKey:FacilitiesRequestLocationUserBuildingKey];
    NSString *customRoom = [self.reportDictionary objectForKey:FacilitiesRequestLocationUserRoomKey];
    
    if (location) {
        [params setObject:location.name forKey:@"locationName"];
        [params setObject:location.number forKey:@"buildingNumber"];
        [params setObject:location.uid forKey:@"location"];
    } else {
        [params setObject:customLocation forKey:@"locationNameByUser"];
    }
    
    if (room) {
        [params setObject:room.number forKey:@"roomName"];
    } else {
        [params setObject:customRoom forKey:@"roomNameByUser"];
    }
    
    [params setObject:type.name forKey:@"problemType"];
    
    [params setObject:[self.reportDictionary objectForKey:FacilitiesRequestUserDescriptionKey] 
               forKey:@"message"];
    
    NSData *pictureData = [self.reportDictionary objectForKey:FacilitiesRequestImageDataKey];
    if (pictureData) {
        [params setObject:[pictureData base64EncodingWithLineLength:64] forKey:@"image"];
        [params setObject:@"image/jpeg" forKey:@"imageFormat"];
    }
    
    MobileRequestOperation *request = [[[MobileRequestOperation alloc] initWithModule:@"facilities"
                                                                              command:@"upload"
                                                                           parameters:params] autorelease];
    request.usePOST = YES;
    request.completeBlock = ^(MobileRequestOperation *operation, id jsonResult, NSString *contentType, NSError *error) {
        if (!error && 
            [jsonResult respondsToSelector:@selector(objectForKey:)] &&
            [[jsonResult objectForKey:@"success"] boolValue] == YES)
        {
            [self showSuccess];
        } else {
            [self showFailure];
        }
    };
    
    [self.progressView setProgress:0.0];
    self.progressView.hidden = NO;
    self.completeButton.hidden = YES;
    [self setStatusText:@"Uploading report..."];

    [[NSOperationQueue mainQueue] addOperation:request];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
}

- (void)viewDidUnload {
    self.statusLabel = nil;
    self.progressView = nil;
    self.completeButton = nil;
    [super viewDidUnload];    
}

// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return MITCanAutorotateForOrientation(interfaceOrientation, [self supportedInterfaceOrientations]);
}

- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
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

- (void)setStatusText:(NSString *)string {
    self.statusLabel.text = string;
    CGFloat margin = 20.0;
    CGRect labelFrame = self.statusLabel.frame;
    CGSize fittedSize = [string sizeWithFont:self.statusLabel.font constrainedToSize:CGSizeMake(labelFrame.size.width, 2000.0) lineBreakMode:self.statusLabel.lineBreakMode];
    labelFrame.size.height = fittedSize.height;
    labelFrame.origin.y = CGRectGetMinY(self.progressView.frame) - labelFrame.size.height - margin;
    self.statusLabel.frame = labelFrame;
}

- (void)showSuccess {
    self.progressView.hidden = YES;
    self.completeButton.hidden = NO;
    [self setStatusText:@"Report submitted successfully."];
}

- (void)showFailure {
    self.progressView.hidden = YES;
    self.completeButton.hidden = NO;
    [self setStatusText:@"Unable to submit report. Please try again later."];
}

@end
