#import "FacilitiesSubmitViewController.h"
#import "FacilitiesRootViewController.h"
#import "FacilitiesConstants.h"
#import "FacilitiesLocation.h"
#import "FacilitiesRoom.h"
#import "FacilitiesRepairType.h"
#import "MITBuildingServicesReportForm.h"
#import "MITUIConstants.h"
#import "MITTouchstoneRequestOperation+MITMobileV2.h"
#import "UINavigationController+MITAdditions.h"

@interface FacilitiesSubmitViewController ()
- (void)setStatusText:(NSString *)string;
- (void)showSuccess;
- (void)showFailure;
@end

@implementation FacilitiesSubmitViewController
#pragma mark - View lifecycle
- (void)viewDidLoad {
    self.title = @"Submit Report";
    self.view.backgroundColor = [UIColor groupTableViewBackgroundColor];
    if (NSFoundationVersionNumber <= NSFoundationVersionNumber_iOS_6_1) {
        self.view.backgroundColor = [UIColor mit_backgroundColor];
    }
    
    CGRect frame = self.view.frame;
    CGFloat margin = 20.0;
    
    {
        self.progressView = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault];
        CGRect progressFrame = CGRectMake(margin,
                                          floor((frame.size.height - self.progressView.frame.size.height) / (1. / (1. - (1. / 1.62)))),
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
        self.completeButton.titleLabel.font = [UIFont boldSystemFontOfSize:CELL_STANDARD_FONT_SIZE];
        [self.completeButton setTitleColor:CELL_STANDARD_FONT_COLOR forState:UIControlStateNormal];

        if (NSFoundationVersionNumber > NSFoundationVersionNumber_iOS_6_1) {
            
            self.completeButton.backgroundColor = [UIColor whiteColor];
            self.completeButton.adjustsImageWhenHighlighted = NO;
            
            UIColor *color = [UIColor darkGrayColor];
            CGRect rect = CGRectMake(0.0f, 0.0f, 1.0f, 1.0f);
            UIGraphicsBeginImageContext(rect.size);
            CGContextRef context = UIGraphicsGetCurrentContext();
            
            CGContextSetFillColorWithColor(context, [color CGColor]);
            CGContextFillRect(context, rect);
            
            UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
            UIGraphicsEndImageContext();
            
            [self.completeButton setBackgroundImage:image forState:UIControlStateHighlighted];
            
            self.completeButton.titleLabel.font = [UIFont systemFontOfSize:[UIFont labelFontSize]];
            [self.completeButton setTitleColor:[UIColor mit_tintColor] forState:UIControlStateNormal];
            
            CGRect frame = self.completeButton.frame;
            frame.origin.x = CGRectGetMinX(self.view.bounds);
            frame.size.width = CGRectGetWidth(self.view.bounds);
            self.completeButton.frame = frame;
        }

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
        
        self.statusLabel = [[UILabel alloc] initWithFrame:labelFrame];
        self.statusLabel.textAlignment = NSTextAlignmentCenter;
        self.statusLabel.lineBreakMode = NSLineBreakByWordWrapping;
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

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    MITBuildingServicesReportForm *reportForm = [MITBuildingServicesReportForm sharedServiceReport];
    
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithCapacity:8];
    params[@"name"] = @"";
    
    params[@"email"] = reportForm.email;
    
    FacilitiesLocation *location = reportForm.location;
    FacilitiesRoom *room = reportForm.room;
    FacilitiesRepairType *type = reportForm.problemType;
    NSString *description = reportForm.reportDescription;
    NSString *customLocation = reportForm.customLocation;
    NSString *customRoom = reportForm.roomAltName;
    
    if (location) {
        params[@"locationName"] = location.name;
        params[@"buildingNumber"] = location.number;
        params[@"location"] = location.uid;
    } else if( customLocation ) {
        params[@"locationNameByUser"] = customLocation;
    }
    
    if (room) {
        params[@"roomName"] = room.number;
    } else if( customRoom ) {
        params[@"roomNameByUser"] = customRoom;
    }
    
    if( type.name ) {
        params[@"problemType"] = type.name;
    }
    
    if( description )
    {
        params[@"message"] = description;
    }
    
    NSData *pictureData = reportForm.reportImageData;
    if (pictureData)
    {
        params[@"image"] = pictureData;
        params[@"imageFormat"] = @"image/jpeg";
    }

    NSURLRequest *request = [NSURLRequest requestForModule:@"facilities" command:@"upload" parameters:params method:@"POST"];
    MITTouchstoneRequestOperation *requestOperation = [[MITTouchstoneRequestOperation alloc] initWithRequest:request];
    
    __weak FacilitiesSubmitViewController *weakSelf = self;
    [requestOperation setCompletionBlockWithSuccess:^(MITTouchstoneRequestOperation *operation, NSDictionary *responseObject) {
        if ([responseObject[@"success"] boolValue]) {
            [weakSelf showSuccess];
        } else {
            [weakSelf showFailure];
        }
    } failure:^(MITTouchstoneRequestOperation *operation, NSError *error) {
        [weakSelf showFailure];
    }];
    
    [requestOperation setUploadProgressBlock:^(NSUInteger bytesWritten, long long totalBytesWritten, long long totalBytesExpectedToWrite) {
        weakSelf.progressView.progress = totalBytesWritten / totalBytesExpectedToWrite;
    }];
    
    [self.progressView setProgress:0.0];
    self.progressView.hidden = NO;
    self.completeButton.hidden = YES;
    [self setStatusText:@"Uploading report..."];

    [[NSOperationQueue mainQueue] addOperation:requestOperation];
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

- (IBAction)reportCompleted:(id)sender
{
//    for (UIViewController *controller in self.navigationController.viewControllers)
//    {
//        if ([controller isKindOfClass:[FacilitiesRootViewController class]])
//        {
//            [self.navigationController popToViewController:controller animated:YES];
//            break;
//        }
//    }
    
    MITBuildingServicesReportForm *reportForm = [MITBuildingServicesReportForm sharedServiceReport];
    // persist email before clearing the form, so that email can be re-used
    [reportForm persistEmail];
    // clear the form after succesful submition
    [reportForm clearAll];
    
    [self.navigationController popToRootViewControllerAnimated:YES];
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
