#import <AVFoundation/AVFoundation.h>
#import <MessageUI/MessageUI.h>

#import "SiteDetailViewController.h"
#import "MITMapView.h"
#import "CoreDataManager.h"
#import "CampusTour.h"
#import "TourSiteOrRoute.h"
#import "CampusTourSideTrip.h"
#import "TourOverviewViewController.h"
#import "MIT_MobileAppDelegate.h"
#import "MITMapRoute.h"
#import "ToursDataManager.h"
#import "SuperThinProgressBar.h"
#import "TourSiteMapAnnotation.h"
#import "CampusTourHomeController.h"
#import "UIKit+MITAdditions.h"
#import "Foundation+MITAdditions.h"
#import "TourLink.h"
#import "MITTouchstoneRequestOperation+MITMobileV2.h"
#import "MITMapAnnotationView.h"

#define WEB_VIEW_TAG 646
#define END_TOUR_ALERT_TAG 878
#define CONNECTION_FAILED_TAG 451

@interface SiteDetailViewController () <MFMailComposeViewControllerDelegate>
@property(nonatomic,strong) MITMapView *routeMapView;
@property(nonatomic,strong) UIImageView *siteImageView;
@property(nonatomic,strong) NSString *siteTemplate;
@property(nonatomic,strong) MITGenericMapRoute *directionsRoute;

@property(nonatomic,strong) IBOutlet UIButton *backArrow;
@property(nonatomic,strong) IBOutlet UIButton *nextArrow;
@property(nonatomic,strong) IBOutlet UIButton *overviewButton;
@property(nonatomic,strong) IBOutlet SuperThinProgressBar *progressbar;
@property(nonatomic,strong) IBOutlet UIView *fakeToolbar;

@property(nonatomic) CGFloat fakeToolbarHeightFromNIB;

@property(nonatomic,strong) UIScrollView *oldSlidingView;
@property(nonatomic,strong) UIScrollView *incomingSlidingView;

@property(nonatomic,strong) TourSiteOrRoute *lastSite;
@property(nonatomic,strong) AVAudioPlayer *audioPlayer;
@property(nonatomic,strong) UIProgressView *progressView;

@property(nonatomic,weak) MITTouchstoneRequestOperation *audioRequestOperation;

//- (void)setupIntroScreenForward:(BOOL)forward;
- (void)setupBottomToolBar;
- (void)setupContentAreaForward:(BOOL)forward;
- (void)setupConclusionScreen;
- (void)setupPrevNextArrows;
- (void)animateViews:(BOOL)forward;
- (void)cleanupOldViews;
- (CampusTourSideTrip *)tripForRequest:(NSURLRequest *)request;

- (void)enablePlayButton;
- (void)disablePlayButton;
- (void)hidePlayButton;
- (void)prepAudio;
- (void)playAudio;
- (void)pauseAudio;
- (void)stopAudio;

- (void)hideProgressView;


- (CLLocationDegrees)euclideanHeadingFromCoordinate:(CLLocationCoordinate2D)start toCoordinate:(CLLocationCoordinate2D)end;
@end

@implementation SiteDetailViewController
#pragma mark Actions

- (void)feedbackButtonPressed:(id)sender {
    NSString *email = [[NSBundle mainBundle] infoDictionary][@"MITFeedbackAddress"];
    NSString *subject = [[ToursDataManager sharedManager] activeTour].feedbackSubject;
    
    MFMailComposeViewController *composeViewController = [[MFMailComposeViewController alloc] init];
    [composeViewController setToRecipients:@[email]];
    [composeViewController setSubject:subject];
    [self presentViewController:composeViewController animated:YES completion:nil];
}

- (IBAction)previousButtonPressed:(id)sender {
    
    TourSiteOrRoute *previous = self.siteOrRoute.previousComponent;
    if (!self.isShowingConclusionScreen)
        self.siteOrRoute = previous;
    
    [self setupContentAreaForward:NO];
}

- (IBAction)nextButtonPressed:(id)sender {
    
    if ((self.siteOrRoute == self.lastSite.nextComponent) && !self.isShowingConclusionScreen) {
        [self setupConclusionScreen];
    } else {
        TourSiteOrRoute *next = self.siteOrRoute.nextComponent;
        self.siteOrRoute = next;
        
        [self setupBottomToolBar];
        [self setupContentAreaForward:YES];
    }
}

- (IBAction)overviewButtonPressed:(id)sender {
    TourOverviewViewController *vc = [[TourOverviewViewController alloc] init];
    
    NSInteger indexOfTopVC = [self.navigationController.viewControllers indexOfObject:self];
    UIViewController *callingVC = self.navigationController.viewControllers[indexOfTopVC-1];
    if([callingVC isKindOfClass:[SiteDetailViewController class]]) {
        vc.callingViewController = callingVC;
    } else {
        vc.callingViewController = self;
    }
    vc.sideTrip = self.sideTrip;
    
    [self presentViewController:vc animated:YES completion:nil];
}

#pragma mark Audio

- (void)prepAudio {
    if (!self.siteOrRoute.audioURL && !self.sideTrip.audioURL) {
        [self hidePlayButton];
        return;
    }
    
    [self enablePlayButton];
    
    TourComponent *component = (self.sideTrip == nil) ? (TourComponent *)self.siteOrRoute : (TourComponent *)self.sideTrip;
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:component.audioFile]) {
        NSURL *fileURL = [NSURL fileURLWithPath:component.audioFile isDirectory:NO];
        
        NSError *error;
        self.audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:fileURL error:&error];
        [self.audioPlayer prepareToPlay];
    }
}

- (void)enablePlayButton {
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:MITImageToursButtonAudio]
                                                                              style:UIBarButtonItemStyleBordered
                                                                             target:self action:@selector(playAudio)];
    self.navigationItem.rightBarButtonItem.enabled = YES;
}

- (void)disablePlayButton {
    self.navigationItem.rightBarButtonItem.enabled = NO;
}

- (void)hidePlayButton {
    self.navigationItem.rightBarButtonItem = nil;
}

- (void)hideProgressView {
    if (self.progressView) {
        [self.progressView removeFromSuperview];
        self.progressView = nil;
    }
}

- (void)playAudio {
    
    if (self.audioPlayer) {
        [self.audioPlayer play];
        
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:MITImageToursButtonAudioPause]
                                                                                  style:UIBarButtonItemStyleBordered
                                                                                 target:self action:@selector(pauseAudio)];
    } else {
        [self disablePlayButton];
        
        TourComponent *component = (self.sideTrip == nil) ? (TourComponent *)self.siteOrRoute : (TourComponent *)self.sideTrip;
        
        NSURL *audioURL = [NSURL URLWithString:component.audioURL];
        NSURLRequest *request = [NSURLRequest requestWithURL:audioURL];
        MITTouchstoneRequestOperation *requestOperation = [[MITTouchstoneRequestOperation alloc] initWithRequest:request];

        __weak SiteDetailViewController *weakSelf = self;
        requestOperation.completeBlock = ^(MITTouchstoneRequestOperation *operation, NSData *data, NSString *contentType, NSError *error) {
            SiteDetailViewController *blockSelf = weakSelf;

            if (!blockSelf) {
                return;
            } else if (blockSelf.audioRequestOperation != operation) {
                return;
            } else if (error) {
                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Connection Failed"
                                                                    message:@"Audio could not be loaded"
                                                                   delegate:blockSelf
                                                          cancelButtonTitle:@"OK" otherButtonTitles:nil];
                alertView.tag = CONNECTION_FAILED_TAG;
                [alertView show];
            } else {
                TourComponent *component = nil;
                if (blockSelf.sideTrip) {
                    component = blockSelf.siteOrRoute;
                } else {
                    component = blockSelf.sideTrip;
                }

                if ([[audioURL absoluteString] isEqualToString:component.audioURL]) {
                    [data writeToFile:component.audioFile atomically:YES];

                    NSURL *fileURL = [NSURL fileURLWithPath:component.audioFile isDirectory:NO];

                    NSError *error;
                    blockSelf.audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:fileURL
                                                                              error:&error];
                    [blockSelf.audioPlayer prepareToPlay];
                    if (!blockSelf.audioPlayer) {
                        DDLogError(@"%@", [error description]);
                    }

                    blockSelf.progressView.progress = 1.0;
                    [UIView beginAnimations:@"fadeProgressView" context:nil];
                    [UIView setAnimationDelegate:self];
                    [UIView setAnimationDelay:0.3];
                    [UIView setAnimationDuration:0.5];

                    if (blockSelf.audioPlayer) {
                        [UIView setAnimationDidStopSelector:@selector(playAudio)];
                    }

                    blockSelf.progressView.alpha = 0.0;
                    [UIView commitAnimations];
                }
            }
        };
        
        [requestOperation setUploadProgressBlock:^(NSUInteger bytesWritten, long long totalBytesWritten, long long totalBytesExpectedToWrite) {
            if (weakSelf.progressView) {
                weakSelf.progressView.progress = 0.1 + 0.9 * totalBytesWritten / totalBytesWritten;
            }
        }];
        
        self.progressView = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault];
        self.progressView.frame = CGRectMake(200, 0, 120, 20);
        [self.view addSubview:self.progressView];
        
        [[NSOperationQueue mainQueue] addOperation:requestOperation];
    }
}

- (void)pauseAudio {
    [self.audioPlayer pause];
    [self enablePlayButton];
}

- (void)stopAudio {
    [self.audioPlayer stop];
    self.audioPlayer = nil;
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:MITImageToursButtonAudio]
                                                                               style:UIBarButtonItemStyleBordered
                                                                              target:self
                                                                              action:@selector(prepAudio)];
}

#pragma mark UIViewController
// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return MITCanAutorotateForOrientation(interfaceOrientation, [self supportedInterfaceOrientations]);
}

- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    [self.overviewButton setImage:[UIImage imageNamed:MITImageToursButtonMap] forState:UIControlStateNormal];
    [self.overviewButton setTitle:nil forState:UIControlStateNormal];
    
    [self.backArrow setImage:[UIImage imageNamed:MITImageToursToolbarArrowLeft] forState:UIControlStateNormal];
    [self.backArrow setTitle:nil forState:UIControlStateNormal];
    [self.nextArrow setImage:[UIImage imageNamed:MITImageToursToolbarArrowRight] forState:UIControlStateNormal];
    [self.nextArrow setTitle:nil forState:UIControlStateNormal];
    
    self.fakeToolbarHeightFromNIB = self.fakeToolbar.frame.size.height;
    [self setupBottomToolBar];
    [self setupContentAreaForward:YES];
}


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.routeMapView.showsUserLocation = YES;
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    self.routeMapView.showsUserLocation = NO;
}

#pragma mark View setup

- (void)setupBottomToolBar {
    if (self.sideTrip == nil) {
        
        self.fakeToolbar.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:MITImageToursProgressBarBackground]];
        
        CGRect frame = self.fakeToolbar.frame;
        frame.origin.y += frame.size.height - self.fakeToolbarHeightFromNIB;
        frame.size.height = self.fakeToolbarHeightFromNIB;
        self.fakeToolbar.frame = frame;
        
        self.progressbar.numberOfSegments = [self.sites count];
        [self.progressbar setNeedsDisplay];
        
        self.progressbar.hidden = NO;
        self.backArrow.hidden = NO;
        self.nextArrow.hidden = NO;
        
    } else {
        self.navigationItem.title = @"Side Trip";
        
        // resize the fake toolbar since there's no progress bar
        UIImage *toolbarImage = [UIImage imageNamed:MITImageToursToolbarBackground];
        CGRect frame = self.fakeToolbar.frame;
        frame.origin.y += (frame.size.height - toolbarImage.size.height);
        frame.size.height = toolbarImage.size.height;
        self.fakeToolbar.frame = frame;
        self.fakeToolbar.backgroundColor = [UIColor colorWithPatternImage:toolbarImage];
        
        self.progressbar.hidden = YES;
        self.backArrow.hidden = YES;
        self.nextArrow.hidden = YES;
    }
}

- (void)setupPrevNextArrows {
    self.backArrow.enabled = self.siteOrRoute != self.firstSite;
    self.nextArrow.enabled = !self.isShowingConclusionScreen;
}

- (void)prepSlidingViewsForward:(BOOL)forward {
    CGFloat viewWidth = self.view.bounds.size.width;
    CGFloat slideWidth = viewWidth  * (forward ? 1 : -1);
    CGFloat xOrigin = (self.oldSlidingView == nil) ? 0 : slideWidth;
    CGFloat height = self.view.bounds.size.height - self.fakeToolbar.bounds.size.height;
    
    CGRect newFrame = CGRectMake(xOrigin, 0, self.view.bounds.size.width, height);
    if (NSFoundationVersionNumber > NSFoundationVersionNumber_iOS_6_1) {
        newFrame = CGRectMake(xOrigin, 64., self.view.bounds.size.width, height - 64.);
    }
    self.incomingSlidingView = [[UIScrollView alloc] initWithFrame:newFrame];
    self.incomingSlidingView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    [self.view addSubview:self.incomingSlidingView];
}

- (void)setupConclusionScreen {
    self.showingConclusionScreen = YES;
    
    self.navigationItem.title = @"Thank You";
    [self hidePlayButton];
    
    [self prepSlidingViewsForward:YES];
    
    CGRect tableFrame = CGRectZero;
    tableFrame.size = self.incomingSlidingView.frame.size;
    
    UITableView *tableView = [[UITableView alloc] initWithFrame:tableFrame style:UITableViewStyleGrouped];
    tableView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    tableView.dataSource = self;
    tableView.delegate = self;
    tableView.backgroundColor = [UIColor whiteColor];
    tableView.backgroundView = nil;
    tableView.separatorColor = [UIColor colorWithHexString:@"#BBBBBB"];
    
    // table footer
    {
        NSString *buttonTitle = @"Return to MIT Home Screen";
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        UIImage *buttonBackground = [UIImage imageNamed:MITImageToursButtonReturn];
        button.frame = CGRectMake(10, 0, buttonBackground.size.width, buttonBackground.size.height);
        [button setBackgroundImage:buttonBackground
                          forState:UIControlStateNormal];
        
        button.titleLabel.font = [UIFont boldSystemFontOfSize:17.0];
        button.titleLabel.textAlignment = NSTextAlignmentCenter;
        [button setTitle:buttonTitle
                forState:UIControlStateNormal];
        [button addTarget:self
                   action:@selector(returnToHomeScreen:)
         forControlEvents:UIControlEventTouchUpInside];
        
        UIView *footerWrapperView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, tableFrame.size.width, buttonBackground.size.height + 10)];
        footerWrapperView.backgroundColor = [UIColor whiteColor];
        [footerWrapperView addSubview:button];
        
        tableView.tableFooterView = footerWrapperView;
    }
    
    // table header
    {
        NSSet *tourLinks = [[ToursDataManager sharedManager] activeTour].links;
        NSInteger numRows = [tourLinks count] + 1;
        CGFloat currentTableHeight = tableView.rowHeight * numRows + CGRectGetHeight(tableView.tableFooterView.frame) + 10;
        CGFloat headerHeight = tableFrame.size.height - currentTableHeight - 10;
        
        UIFont *font = [UIFont systemFontOfSize:15];
        NSString *text = NSLocalizedString(@"End of tour text", nil);
        CGSize size = [text sizeWithFont:font
                       constrainedToSize:CGSizeMake(tableFrame.size.width - 20, headerHeight - 20)
                           lineBreakMode:NSLineBreakByWordWrapping];
        
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(10, 10, tableFrame.size.width - 20, size.height)];
        label.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin;
        label.lineBreakMode = NSLineBreakByWordWrapping;
        label.numberOfLines = 0;
        label.text = text;
        label.textColor = [UIColor colorWithHexString:@"#202020"];
        [label sizeToFit];
        
        
        UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, tableFrame.size.width, headerHeight)];
        headerView.backgroundColor = [UIColor whiteColor];
        [headerView addSubview:label];
        tableView.tableHeaderView = headerView;
    }
    
    [self.incomingSlidingView addSubview:tableView];
    
    [self.progressbar markAsDone];
    [self.progressbar setNeedsDisplay];
    [self animateViews:YES];
    
    self.routeMapView.showsUserLocation = NO;
    [self.routeMapView removeFromSuperview];
    self.routeMapView = nil;
}

- (void)setupContentAreaForward:(BOOL)forward {
    
    if (self.audioPlayer) {
        [self stopAudio];
    }
    [self prepAudio];
    
    self.showingConclusionScreen = NO;
    
    // prep views
    [self prepSlidingViewsForward:forward];
    
    UIView *newGraphic = nil;
    CGRect newFrame;
    
    TourComponent *component = (self.sideTrip == nil) ? (TourComponent *)self.siteOrRoute : (TourComponent *)self.sideTrip;
    
    // prep strings
    if (!self.siteTemplate) {
        NSString *templatePath = [[NSBundle mainBundle] pathForResource:@"site_template" ofType:@"html" inDirectory:@"tours"];
        NSAssert(templatePath,@"failed to load resource 'tours/site_template.html'");
        
        NSURL *fileURL = [NSURL fileURLWithPath:templatePath isDirectory:NO];
        
        NSError *error = nil;
        self.siteTemplate = [[NSString alloc] initWithContentsOfURL:fileURL encoding:NSUTF8StringEncoding error:&error];
    }
    
    NSString *nextStopPhoto = [NSString string];
    NSMutableString *body = [NSMutableString stringWithString:component.body];
    
    // populate views and strings
    if (self.sideTrip == nil) {
        if ([self.siteOrRoute.type isEqualToString:@"route"]) {
            
            self.navigationItem.title = @"Walking Directions";
            
            newFrame = CGRectMake(10, 10, self.incomingSlidingView.bounds.size.width - 20, floor(self.incomingSlidingView.bounds.size.height * 0.5));
            if (!self.routeMapView) {
                MITMapView *routeMapView = [[MITMapView alloc] initWithFrame:newFrame];
                routeMapView.delegate = self;
                routeMapView.userInteractionEnabled = NO;
                routeMapView.showsUserLocation = YES;
                routeMapView.stayCenteredOnUserLocation = NO;
                routeMapView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
                routeMapView.layer.borderWidth = 1.0;
                routeMapView.layer.borderColor = [UIColor colorWithHexString:@"#C0C0C0"].CGColor;
                self.routeMapView = routeMapView;
            } else {
                self.routeMapView.frame = newFrame;
            }
            
            [self.routeMapView addRoute:[[ToursDataManager sharedManager] mapRouteForTour]];
            
            TourSiteMapAnnotation *startAnnotation = [[TourSiteMapAnnotation alloc] init];
            startAnnotation.site = self.siteOrRoute.previousComponent;
            
            TourSiteMapAnnotation *endAnnotation = [[TourSiteMapAnnotation alloc] init];
            endAnnotation.site = self.siteOrRoute.nextComponent;
            
            NSArray *pathLocations = [self.siteOrRoute pathAsArray];
            if ([pathLocations count] > 1) {
                // This code calculates the heading we'll need to make sure the arrows
                // are pointing the correct way
                CLLocationCoordinate2D startCoordinate = startAnnotation.coordinate;
                CLLocationCoordinate2D firstPathCoordinate = [(CLLocation*)pathLocations[1] coordinate];
                CLLocationDegrees startHeading = [self euclideanHeadingFromCoordinate:startCoordinate
                                                                         toCoordinate:firstPathCoordinate];
                startAnnotation.transform = CGAffineTransformMakeRotation(startHeading * (M_PI / 180.0));
                
                CLLocationCoordinate2D endCoordinate = endAnnotation.coordinate;
                
                // This should be the index of the last path coordinate
                // that is *not* the annotation (the paths extend all the
                // way through the visible annotations)
                NSUInteger lastPathIndex = [pathLocations count] - 2;
                CLLocationCoordinate2D lastPathCoordinate = [(CLLocation*)pathLocations[lastPathIndex] coordinate];
                CLLocationDegrees endHeading = [self euclideanHeadingFromCoordinate:lastPathCoordinate
                                                                       toCoordinate:endCoordinate];
                endAnnotation.transform = CGAffineTransformMakeRotation(endHeading * (M_PI / 180.0));
                
                self.directionsRoute = [[MITGenericMapRoute alloc] init];
                self.directionsRoute.lineWidth = 6;
                
                UIColor *color = [UIColor colorWithRed:0.8 green:0 blue:0 alpha:1];
                self.directionsRoute.fillColor = color;
                self.directionsRoute.strokeColor = color;
                self.directionsRoute.pathLocations = pathLocations;
                [self.routeMapView addRoute:self.directionsRoute];
            }
            
            [self.routeMapView addAnnotation:startAnnotation];
            [self.routeMapView addAnnotation:endAnnotation];
            
            CLLocationCoordinate2D center = CLLocationCoordinate2DMake((startAnnotation.coordinate.latitude + endAnnotation.coordinate.latitude) / 2.0,
                                                                       (startAnnotation.coordinate.longitude + endAnnotation.coordinate.longitude) / 2.0);
            self.routeMapView.zoomLevel = [self.siteOrRoute.zoom floatValue];
            self.routeMapView.centerCoordinate = center;
            
            newGraphic = self.routeMapView;
            
            if (component.photoURL) {
                NSString *photoFile = component.photoFile;
                NSInteger imageWidth = 160;
                NSInteger imageHeight = 100;
                
                if (![[NSFileManager defaultManager] fileExistsAtPath:photoFile]) {
                    photoFile = @"tours/tour_photo_loading_animation.gif";
                    
                    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:component.photoURL]];
                    MITTouchstoneRequestOperation *requestOperation = [[MITTouchstoneRequestOperation alloc] initWithRequest:request];

                    __weak SiteDetailViewController *weakSelf = self;
                    requestOperation.completeBlock = ^(MITTouchstoneRequestOperation *operation, NSData *data, NSString *contentType, NSError *error) {
                        SiteDetailViewController *blockSelf = weakSelf;

                        if (!blockSelf) {
                            return;
                        } else if (error) {
                            DDLogWarn(@"site detail image request failed with error %@",error);
                        } else if (![data isKindOfClass:[NSData class]]) {
                            return;
                        } else {
                            [data writeToFile:component.photoFile atomically:YES];
                            NSString *js = [NSString stringWithFormat:@"var img = document.getElementById(\"directionsphoto\");\n"
                                            "img.src = \"%@\";\n", component.photoFile];
                            UIWebView *webView = (UIWebView *)[blockSelf.incomingSlidingView viewWithTag:WEB_VIEW_TAG];
                            [webView stringByEvaluatingJavaScriptFromString:js];
                        }
                    };

                    [[NSOperationQueue mainQueue] addOperation:requestOperation];
                }
                
                TourSiteOrRoute *nextComponent = self.siteOrRoute.nextComponent;
                nextStopPhoto = [NSString stringWithFormat:@"<div class=\"photo\"><img id=\"directionsphoto\" src=\"%@\" width=\"%d\" height=\"%d\">%@</div>",
                                 photoFile, imageWidth, imageHeight,
                                 nextComponent.title];
            }
        } else {
            self.navigationItem.title = @"Detail";
        }
        
        if (self.siteOrRoute != self.firstSite) {
            UIBarButtonItem *endTourButton = [[UIBarButtonItem alloc] initWithTitle:@"End Tour"
                                                                               style:UIBarButtonItemStyleBordered
                                                                              target:self
                                                                              action:@selector(endTour:)];
            self.navigationItem.leftBarButtonItem = endTourButton;
        } else {
            self.navigationItem.leftBarButtonItem = nil; // default back button
        }
        
        NSString *sideTripTemplate = @"<p class=\"sidetrip\"><a href=\"%@\">Side Trip: %@</a></p>";
        for (CampusTourSideTrip *aTrip in self.siteOrRoute.sideTrips) {
            NSString *tripHTML = [NSString stringWithFormat:sideTripTemplate, aTrip.componentID, aTrip.title];
            NSString *stringToReplace = [NSString stringWithFormat:@"__SIDE_TRIP_%@__", aTrip.componentID];
            [body replaceOccurrencesOfString:stringToReplace withString:tripHTML options:NSLiteralSearch range:NSMakeRange(0, [body length])];
        }
    }
    
    if (!newGraphic) { // site or side trip detail
        
        NSInteger progress = [self.sites indexOfObject:self.siteOrRoute];
        if (progress != NSNotFound) {
            self.progressbar.currentPosition = progress;
            [self.progressbar setNeedsDisplay];
        }
        
        newFrame = CGRectMake(0, 0, self.incomingSlidingView.bounds.size.width, floor(self.incomingSlidingView.bounds.size.height * 0.5));
        MITThumbnailView *thumb = [[MITThumbnailView alloc] initWithFrame:newFrame];
        NSData *imageData = component.photo;
        NSString *imageURL = component.photoURL;
        
        if (imageData != nil) {
            thumb.imageData = imageData;
        } else {
            thumb.imageURL = imageURL;
        }
        
        thumb.delegate = self;
        [thumb loadImage];
        newGraphic = thumb;
    }
    
    [self.incomingSlidingView addSubview:newGraphic];
    
    newFrame = CGRectMake(0, newFrame.origin.y + newFrame.size.height, self.view.frame.size.width,
                          self.view.frame.size.height - newFrame.size.height - self.fakeToolbar.frame.size.height);
    
    UIWebView *webView = [[UIWebView alloc] initWithFrame:newFrame];
    webView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    webView.delegate = self;
    webView.tag = WEB_VIEW_TAG;
    webView.scrollView.scrollsToTop = NO;
	webView.scrollView.scrollEnabled = NO;
    
    NSMutableString *html = [NSMutableString stringWithString:self.siteTemplate];
    NSString *maxWidth = [NSString stringWithFormat:@"%.0f", webView.frame.size.width];
    [html replaceOccurrencesOfString:@"__WIDTH__" withString:maxWidth options:NSLiteralSearch range:NSMakeRange(0, [html length])];
    [html replaceOccurrencesOfString:@"__TITLE__" withString:component.title options:NSLiteralSearch range:NSMakeRange(0, [html length])];
    [html replaceOccurrencesOfString:@"__PHOTO__" withString:nextStopPhoto options:NSLiteralSearch range:NSMakeRange(0, [html length])];
    [html replaceOccurrencesOfString:@"__BODY__" withString:body options:NSLiteralSearch range:NSMakeRange(0, [html length])];
    
	NSURL *baseURL = [NSURL fileURLWithPath:[[NSBundle mainBundle] resourcePath] isDirectory:YES];
    
    [webView loadHTMLString:html baseURL:baseURL];
    
    [self.incomingSlidingView addSubview:webView];
    
    [self animateViews:forward];
}

- (void)animateViews:(BOOL)forward {
    self.nextArrow.enabled = NO;
    self.backArrow.enabled = NO;
    
    if (self.oldSlidingView) {
        
        CGFloat viewWidth = self.view.frame.size.width;
        CGFloat transitionWidth = viewWidth  * (forward ? 1 : -1);
        
        [UIView beginAnimations:@"tourAnimation" context:nil];
        [UIView setAnimationDuration:0.4];
        [UIView setAnimationDelegate:self];
        [UIView setAnimationDidStopSelector:@selector(cleanupOldViews)];
        self.oldSlidingView.center = CGPointMake(self.oldSlidingView.center.x - transitionWidth,
                                                 self.oldSlidingView.center.y);
        self.incomingSlidingView.center = CGPointMake(self.incomingSlidingView.center.x - transitionWidth,
                                                      self.incomingSlidingView.center.y);
        [UIView commitAnimations];
        
    }
    else {
        self.oldSlidingView = self.incomingSlidingView;
        [self setupPrevNextArrows];
    }
    
}

- (void)cleanupOldViews {
    if (!self.sideTrip && [self.siteOrRoute.type isEqualToString:@"site"] && self.directionsRoute) {
        [self.routeMapView removeRoute:self.directionsRoute];
        self.directionsRoute = nil;
        [self.routeMapView removeAllAnnotations:NO];
    }
    
    [self.oldSlidingView removeFromSuperview];
    self.oldSlidingView = self.incomingSlidingView;
    
    [self setupPrevNextArrows];
}

#pragma mark Navigation

- (void)endTour:(id)sender {
	UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"End Tour?"
														 message:@"Are you sure you want to end the tour?"
														delegate:self
											   cancelButtonTitle:@"Cancel"
											   otherButtonTitles:@"OK", nil];
	alertView.tag = END_TOUR_ALERT_TAG;
	[alertView show];
}

- (void)returnToHomeScreen:(id)sender {
    [self.navigationController popToRootViewControllerAnimated:YES];
}

- (void)jumpToSite:(NSInteger)siteIndex {
    TourSiteOrRoute *site = self.sites[siteIndex];
    
    // TODO: clean up so we're not doing the same thing here and in TourOverviewViewController
    NSInteger currentSiteIndex;
    if ([self.siteOrRoute.type isEqualToString:@"site"]) {
        currentSiteIndex = [self.sites indexOfObject:self.siteOrRoute];
    } else {
        currentSiteIndex = [self.sites indexOfObject:self.siteOrRoute.nextComponent];
    }
    
    self.siteOrRoute = site;
    
    BOOL forward = currentSiteIndex < siteIndex;
    
    [self setupBottomToolBar];
    [self setupContentAreaForward:forward];
}

- (void)setFirstSite:(TourSiteOrRoute *)aSite {
    if (self.firstSite != aSite) {
        _firstSite = aSite;
        self.lastSite = nil;
        
        if(_firstSite != nil) {
            self.sites = [[ToursDataManager sharedManager] allSitesStartingFrom:self.firstSite];
            self.lastSite = self.firstSite.previousComponent.previousComponent;
        } else {
            self.sites = nil;
            self.lastSite = nil;
        }
    }
}

#pragma mark Memory

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    if (self.audioPlayer) { // don't use stopAudio as it accesses the nav bar
        [self.audioPlayer stop];
        self.audioPlayer = nil;
    }
    [self hideProgressView]; // also releases progress view
}

- (void)viewDidUnload {
    [super viewDidUnload];
    self.oldSlidingView = nil;
}


- (void)dealloc {
    self.routeMapView.delegate = nil;
    
    if (self.audioPlayer) {
        self.audioPlayer.delegate = nil;
        [self.audioPlayer stop];
    }
    
    [self hideProgressView]; // also releases progress view
}

#pragma mark -
#pragma mark MITThumbnailDelegate

- (void)thumbnail:(MITThumbnailView *)thumbnail didLoadData:(NSData *)data {
    TourComponent *component = (self.sideTrip == nil) ? (TourComponent *)self.siteOrRoute : (TourComponent *)self.sideTrip;
    if ([thumbnail.imageURL isEqualToString:component.photoURL]) {
        component.photo = data;
    }
}

#pragma mark UIWebViewDelegate

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    if ([[request.URL absoluteString] rangeOfString:@"http"].location == 0) {
        if ([[UIApplication sharedApplication] canOpenURL:request.URL]) {
            [[UIApplication sharedApplication] openURL:request.URL];
        }
        return NO;
    }
    
    if (self.sideTrip == nil) {
        CampusTourSideTrip *trip = [self tripForRequest:request];
        if (trip) {
            SiteDetailViewController *sideTripVC = [[SiteDetailViewController alloc] init];
            sideTripVC.sideTrip = trip;
            sideTripVC.sites = self.sites;
            sideTripVC.siteOrRoute = self.siteOrRoute;
            [self.navigationController pushViewController:sideTripVC animated:YES];
            return NO;
        }
    }
    return YES;
}

- (TourComponent *)tripForRequest:(NSURLRequest *)request {
    NSArray *pathComponents = [[request.URL path] pathComponents];
    if ([pathComponents count]) {
        NSString *maybeTripID = [pathComponents lastObject];
        for (CampusTourSideTrip *aTrip in self.siteOrRoute.sideTrips) {
            if ([maybeTripID isEqualToString:aTrip.componentID]) {
                return aTrip;
            }
        }
    }
    return nil;
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
    CGSize size = [webView sizeThatFits:CGSizeZero];
    CGRect frame = webView.frame;
    CGFloat addedHeight = size.height - frame.size.height;
    frame.size.height = size.height;
    webView.frame = frame;

    if (NSFoundationVersionNumber > NSFoundationVersionNumber_iOS_6_1) {
        addedHeight += 64.;
    }

    if (addedHeight > 0) {
        // increase scrollview height by how much the webview height grows
        CGSize contentSize = self.incomingSlidingView.contentSize;
        contentSize.height = self.incomingSlidingView.frame.size.height + addedHeight;
        self.incomingSlidingView.contentSize = contentSize;
    }
}

#pragma mark MITMapViewDelegate

- (MITMapAnnotationView *)mapView:(MITMapView *)mapView viewForAnnotation:(id <MKAnnotation>)annotation {
    TourSiteMapAnnotation *tourAnnotation = (TourSiteMapAnnotation *)annotation;
    MITMapAnnotationView *annotationView = [[MITMapAnnotationView alloc] initWithAnnotation:tourAnnotation reuseIdentifier:@"toursite"];
    
    TourSiteOrRoute *site = tourAnnotation.site;
    TourSiteOrRoute *upcomingSite = self.siteOrRoute.nextComponent;
    UIImageView *markerView;
    if (upcomingSite == site) {
        markerView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:MITImageToursAnnotationArrowEnd]];
    } else {
        markerView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:MITImageToursAnnotationArrowStart]];
    }
    
    
    // Create and apply a rotation to the marker view in order to
    // have it appear properly (the start should be coming from the current annotation
    // and end should be pointing at the next stop). Since all rotations
    // start from (0,0), not the center of the image, we need to
    // translate the view so that the image is centered around (0,0),
    // then do the rotation, then translate the result back
    CGFloat deltaX = -CGRectGetMidX(markerView.frame);
    CGFloat deltaY = -CGRectGetMidY(markerView.frame);
    
    if (CGAffineTransformEqualToTransform(CGAffineTransformIdentity,tourAnnotation.transform) == NO) {
        CGAffineTransform transform = CGAffineTransformMakeTranslation(deltaX, deltaY);
        transform = CGAffineTransformConcat(transform, tourAnnotation.transform);
        transform = CGAffineTransformTranslate(transform, -deltaX, -deltaY);
        markerView.transform = transform;
    }
    
    [annotationView addSubview:markerView];
    annotationView.frame = CGRectOffset(markerView.bounds, deltaX, deltaY);
    annotationView.canShowCallout = NO;
    annotationView.showsCustomCallout = NO;
    
    
    return annotationView;
}

#pragma mark tableview

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)table numberOfRowsInSection:(NSInteger)section {
    NSSet *tourLinks = [[ToursDataManager sharedManager] activeTour].links;
    return [tourLinks count] + 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        cell.backgroundColor = [UIColor colorWithHexString:@"#E0E0E0"];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    
    if (indexPath.row == 0) {
        cell.textLabel.text = @"Send feedback";
        cell.accessoryView = [UIImageView accessoryViewWithMITType:MITAccessoryViewEmail];
        
    } else {
        NSSet *tourLinks = [[ToursDataManager sharedManager] activeTour].links;
        NSArray *sortedLinks = [tourLinks sortedArrayUsingDescriptors:[NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"sortOrder" ascending:YES]]];
        TourLink *link = sortedLinks[indexPath.row - 1];
        cell.textLabel.text = link.title;
        if ([link.url rangeOfString:@"http"].location == 0) {
            cell.accessoryView = [UIImageView accessoryViewWithMITType:MITAccessoryViewExternal];
        } else {
            cell.accessoryView = [UIImageView accessoryViewForInternalURL:link.url];
        }
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (indexPath.row == 0) {
        [self feedbackButtonPressed:nil];
        
    } else {
        NSSet *tourLinks = [[ToursDataManager sharedManager] activeTour].links;
        NSArray *sortedLinks = [tourLinks sortedArrayUsingDescriptors:[NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"sortOrder" ascending:YES]]];
        TourLink *link = sortedLinks[indexPath.row - 1];
        NSURL *url = [NSURL URLWithString:link.url];
        
        if (url && [[UIApplication sharedApplication] canOpenURL:url]) {
            [[UIApplication sharedApplication] openURL:url];
        }
    }
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}


#pragma mark UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (alertView.tag == CONNECTION_FAILED_TAG) {
        [UIView beginAnimations:@"fadeProgressView" context:nil];
        [UIView setAnimationDelegate:self];
        [UIView setAnimationDelay:0.3];
        [UIView setAnimationDuration:0.5];
        if (self.audioPlayer) {
            [UIView setAnimationDidStopSelector:@selector(hideProgressView)];
        }
        self.progressView.alpha = 0.0;
        [UIView commitAnimations];
    }
    
	else if (alertView.tag == END_TOUR_ALERT_TAG && buttonIndex != [alertView cancelButtonIndex]) {
		CampusTourHomeController *theController = nil;
		for (UIViewController *aController in self.navigationController.viewControllers) {
			if ([aController isKindOfClass:[CampusTourHomeController class]]) {
				theController = (CampusTourHomeController *)aController;
                break;
			}
		}
		if (theController) {
			[self.navigationController popToViewController:theController animated:YES];
		}
	}
}

- (CLLocationDegrees)euclideanHeadingFromCoordinate:(CLLocationCoordinate2D)start toCoordinate:(CLLocationCoordinate2D)end {
    MKMapPoint startPoint = MKMapPointForCoordinate(start);
    MKMapPoint endPoint = MKMapPointForCoordinate(end);
    
    double deltaX = endPoint.x - startPoint.x;
    double deltaY = endPoint.y - startPoint.y;
    
    return atan2(deltaY,deltaX) * 180 / M_PI;
}

#pragma mark MFMailComposeViewControllerDelegate
- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error
{
    if ([self.presentedViewController isEqual:controller]) {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

@end
