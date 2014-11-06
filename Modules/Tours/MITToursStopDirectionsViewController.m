#import "MITToursStopDirectionsViewController.h"
#import "MITTiledMapView.h"
#import "MITToursStop.h"
#import "MITToursDirectionsToStop.h"
#import "MITToursTour.h"
#import "MITToursHTMLTemplateInjector.h"

@interface MITToursStopDirectionsViewController () <UIWebViewDelegate>

@property (weak, nonatomic) IBOutlet UIScrollView *containerScrollView;
@property (weak, nonatomic) IBOutlet MITTiledMapView *tiledMapView;
@property (weak, nonatomic) IBOutlet UIWebView *webView;

@end

@implementation MITToursStopDirectionsViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title = self.stop.title;
    
    self.edgesForExtendedLayout = UIRectEdgeNone;
    
    [self setupMapView];
    [self setupWebView];
}

- (void)viewWillAppear:(BOOL)animated
{
    [self.navigationController setToolbarHidden:YES];
}

- (void)setupMapView
{
    [self.tiledMapView setButtonsHidden:YES animated:NO];
    [self.tiledMapView.mapView setRegion:kMITToursDefaultMapRegion animated:NO];
    self.tiledMapView.mapView.showsUserLocation = YES;
    [self.tiledMapView showRouteForStops:[self.stop.tour.stops array]];
    self.tiledMapView.userInteractionEnabled = NO;
}

- (void)setupWebView
{
    self.webView.delegate = self;
    self.webView.scrollView.scrollEnabled = NO;
    self.webView.scrollView.scrollsToTop = NO;
    
    [self.webView setBackgroundColor:[UIColor redColor]];
    
    NSString *directionsHTMLString = self.stop.directionsToNextStop ? [MITToursHTMLTemplateInjector templatedHTMLForDirectionsToStop:self.stop.directionsToNextStop viewWidth:self.view.frame.size.width] : [self noDirectionsHTMLString];
    NSURL *baseURL = [NSURL fileURLWithPath:[[NSBundle mainBundle] resourcePath] isDirectory:YES];
    
    [self.webView loadHTMLString:directionsHTMLString baseURL:baseURL];
}

- (NSString *)noDirectionsHTMLString
{
    return @"";
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    CGFloat webViewContentHeight = self.webView.scrollView.contentSize.height;
    CGFloat totalHeight = self.tiledMapView.frame.size.height + webViewContentHeight;
    self.webView.frame = CGRectMake(0, self.webView.frame.origin.y, self.view.frame.size.width, webViewContentHeight);
    [self.containerScrollView setContentSize:CGSizeMake(self.view.frame.size.width, totalHeight)];
}

@end
