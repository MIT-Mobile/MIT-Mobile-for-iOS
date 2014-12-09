#import "MITToursStopDirectionsViewController.h"
#import "MITTiledMapView.h"
#import "MITToursStop.h"
#import "MITToursDirectionsToStop.h"
#import "MITToursTour.h"
#import "MITToursHTMLTemplateInjector.h"
#import "MITToursStopDirectionAnnotation.h"
#import "MITToursStopDirectionsAnnotationView.h"
#import "UIKit+MITAdditions.h"
#import "MITCalloutMapView.h"

static CGFloat const kIPadMapHeight = 300;
static CGFloat const kWebViewContentMargin = 8;

@interface MITToursStopDirectionsViewController () <UIWebViewDelegate, MKMapViewDelegate>

@property (weak, nonatomic) IBOutlet UIScrollView *containerScrollView;
@property (weak, nonatomic) IBOutlet MITTiledMapView *tiledMapView;
@property (weak, nonatomic) IBOutlet UIWebView *webView;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *tiledMapViewHeightConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *webViewHeightConstraint;

@end

@implementation MITToursStopDirectionsViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title = @"Walking Directions";
    
    self.edgesForExtendedLayout = UIRectEdgeNone;
    
    [self setupMapView];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.navigationController setToolbarHidden:YES];
   
    // There is a bug with VCs presented as formsheets that prevents them from showing the right tint color unless you change it in viewDidAppear (and it has to be a change, not just re-setting it), so we're arbitrarily setting it to almost system blue, and then to the right color...
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        self.tiledMapView.mapView.tintColor = [UIColor colorWithRed:0 green:120.0/255.0 blue:1.0 alpha:1.0];
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self setupWebView];
    self.tiledMapView.mapView.tintColor = [UIColor mit_systemTintColor];
}

- (void)setupMapView
{
    [self.tiledMapView setMapDelegate:self];
    
    [self.tiledMapView.mapView setRegion:kMITToursDefaultMapRegion animated:NO];
    self.tiledMapView.mapView.showsUserLocation = YES;
    [self.tiledMapView showRouteForStops:[self.currentStop.tour.stops array]];
    self.tiledMapView.userInteractionEnabled = NO;
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        self.tiledMapViewHeightConstraint.constant = kIPadMapHeight;
        [self.view needsUpdateConstraints];
    }
    
    [self setupAnnotations];
    [self setupRegion];
}

- (void)setupAnnotations
{
    CLLocationCoordinate2D currentStopAnnotationCoordinate;
    CLLocationCoordinate2D nextStopAnnotationCoordinate;
    
    if ([self areDirectionsOnMainLoop]) {
        currentStopAnnotationCoordinate = [self coordinateFromArray:self.currentStop.directionsToNextStop.path[1]];
        
        NSInteger coordinateIndex = [self.currentStop.directionsToNextStop.path count] - 2;
        nextStopAnnotationCoordinate = [self coordinateFromArray:self.currentStop.directionsToNextStop.path[coordinateIndex]];
    }
    else {
        currentStopAnnotationCoordinate = [self coordinateFromArray:self.nextStop.coordinates];
        nextStopAnnotationCoordinate = [self coordinateFromArray:self.currentStop.coordinates];
    }
    
    MITToursStopDirectionAnnotation *currentStopAnnotation = [[MITToursStopDirectionAnnotation alloc] initWithStop:self.currentStop coordinate:currentStopAnnotationCoordinate isDestination:NO];
    
    MITToursStopDirectionAnnotation *nextStopAnnotation = [[MITToursStopDirectionAnnotation alloc] initWithStop:self.nextStop coordinate:nextStopAnnotationCoordinate isDestination:YES];
    
    [self.tiledMapView.mapView addAnnotations:@[currentStopAnnotation, nextStopAnnotation]];
}

- (void)setupRegion
{
    if ([self areDirectionsOnMainLoop]) {
        [self.tiledMapView zoomToFitCoordinates:self.currentStop.directionsToNextStop.path];
    }
    else {
        [self.tiledMapView zoomToFitCoordinates:@[self.currentStop.coordinates, self.nextStop.coordinates]];
    }
}

- (BOOL)areDirectionsOnMainLoop
{
    return (self.nextStop.isMainLoopStop && [self.currentStop.directionsToNextStop.path count] > 1);
}

- (CLLocationCoordinate2D)coordinateFromArray:(NSArray *)array
{
    CLLocationDegrees longitude = [((NSNumber *)array[0]) doubleValue];
    CLLocationDegrees latitude = [((NSNumber *)array[1]) doubleValue];
    return CLLocationCoordinate2DMake(latitude, longitude);
}

- (void)setupWebView
{
    self.webView.delegate = self;
    self.webView.scrollView.scrollEnabled = NO;
    self.webView.scrollView.scrollsToTop = NO;
    
    [self.webView setBackgroundColor:[UIColor redColor]];
    
    NSString *directionsHTMLString = self.nextStop.directionsToNextStop ? [self HTMLDirectionsToNextMainLoopStop] : [self HTMLDirectionToSideTripStop];
    NSURL *baseURL = [NSURL fileURLWithPath:[[NSBundle mainBundle] resourcePath] isDirectory:YES];
    
    [self.webView loadHTMLString:directionsHTMLString baseURL:baseURL];
}

- (NSString *)HTMLDirectionsToNextMainLoopStop
{
    return [MITToursHTMLTemplateInjector templatedHTMLForDirectionsToStop:self.currentStop.directionsToNextStop viewWidth:[self webViewContentWidth]];
}

- (NSString *)HTMLDirectionToSideTripStop
{
    return [MITToursHTMLTemplateInjector templatedHTMLForSideTripStop:self.nextStop fromMainLoopStop:self.currentStop viewWidth:[self webViewContentWidth]];
}

- (CGFloat)webViewContentWidth
{
    return CGRectGetWidth(self.view.bounds) - 2 * kWebViewContentMargin;
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    CGFloat webViewContentHeight = self.webView.scrollView.contentSize.height;
    self.webViewHeightConstraint.constant = webViewContentHeight;
    [self.view setNeedsUpdateConstraints];
}

#pragma mark - Map View Delegate

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation
{
    if (![annotation isKindOfClass:[MITToursStopAnnotation class]]) {
        return nil;
    }
    
    MITToursStopDirectionAnnotation *stopAnnotation = (MITToursStopDirectionAnnotation *)annotation;
    
    MITToursStopDirectionsAnnotationView *annotationView = [[MITToursStopDirectionsAnnotationView alloc] initWithStopDirectionAnnotation:stopAnnotation];

    return annotationView;
}

@end
