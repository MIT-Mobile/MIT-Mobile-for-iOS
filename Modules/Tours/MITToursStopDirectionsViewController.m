#import "MITToursStopDirectionsViewController.h"
#import "MITTiledMapView.h"
#import "MITToursStop.h"
#import "MITToursDirectionsToStop.h"
#import "MITToursTour.h"
#import "MITToursHTMLTemplateInjector.h"
#import "MITToursStopDirectionAnnotation.h"
#import "MITToursStopDirectionsAnnotationView.h"

@interface MITToursStopDirectionsViewController () <UIWebViewDelegate, MKMapViewDelegate>

@property (weak, nonatomic) IBOutlet UIScrollView *containerScrollView;
@property (weak, nonatomic) IBOutlet MITTiledMapView *tiledMapView;
@property (weak, nonatomic) IBOutlet UIWebView *webView;

@end

@implementation MITToursStopDirectionsViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title = @"Walking Directions";
    
    self.edgesForExtendedLayout = UIRectEdgeNone;
    
    [self setupMapView];
    [self setupWebView];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.navigationController setToolbarHidden:YES];
}

- (void)setupMapView
{
    [self.tiledMapView setMapDelegate:self];
    [self.tiledMapView setButtonsHidden:YES animated:NO];
    [self.tiledMapView.mapView setRegion:kMITToursDefaultMapRegion animated:NO];
    self.tiledMapView.mapView.showsUserLocation = YES;
    [self.tiledMapView showRouteForStops:[self.currentStop.tour.stops array]];
    self.tiledMapView.userInteractionEnabled = NO;
    
    [self setupAnnotations];
}

- (void)setupAnnotations
{
    CLLocationCoordinate2D currentStopAnnotationCoordinate;
    CLLocationCoordinate2D nextStopAnnotationCoordinate;
    
    if (self.nextStop.isMainLoopStop && [self.currentStop.directionsToNextStop.path count] > 1) {
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
    return [MITToursHTMLTemplateInjector templatedHTMLForDirectionsToStop:self.currentStop.directionsToNextStop viewWidth:self.view.frame.size.width];
}

- (NSString *)HTMLDirectionToSideTripStop
{
    return [MITToursHTMLTemplateInjector templatedHTMLForSideTripStop:self.nextStop viewWidth:self.view.frame.size.width];
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    CGFloat webViewContentHeight = self.webView.scrollView.contentSize.height;
    CGFloat totalHeight = self.tiledMapView.frame.size.height + webViewContentHeight;
    self.webView.frame = CGRectMake(0, self.webView.frame.origin.y, self.view.frame.size.width, webViewContentHeight);
    [self.containerScrollView setContentSize:CGSizeMake(self.view.frame.size.width, totalHeight)];
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
