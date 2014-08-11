#import "MITEventsMapViewController.h"
#import "MITTiledMapView.h"
#import "MITMapPlaceAnnotationView.h"
#import "MITMapPlaceDetailViewController.h"
#import "MITMapTypeAheadTableViewController.h"
#import "MITEventPlace.h"
#import "MITEventDetailViewController.h"
#import "MITCalendarsEvent.h"

static NSString * const kMITMapPlaceAnnotationViewIdentifier = @"MITMapPlaceAnnotationView";

@interface MITEventsMapViewController () <MKMapViewDelegate>


@property (nonatomic, strong) UIPopoverController *currentEventPopoverController;
@property (weak, nonatomic) IBOutlet MITTiledMapView *tiledMapView;
@property (nonatomic, readonly) MKMapView *mapView;

@property (nonatomic, copy) NSArray *places;

@property (nonatomic) BOOL shouldRefreshAnnotationsOnNextMapRegionChange;

@end

@implementation MITEventsMapViewController

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
    // Do any additional setup after loading the view from its nib.
    [self setupMapView];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - External API

- (void)showCurrentLocation
{
    [self.tiledMapView centerMapOnUserLocation];
}

- (BOOL)canSelectEvent:(MITCalendarsEvent *)event
{
    for (MITEventPlace *place in self.places) {
        if ([place.calendarsEvent.identifier isEqualToString:event.identifier]) {
            return YES;
        }
    }
    
    return NO;
}

- (void)selectEvent:(MITCalendarsEvent *)event
{
    for (MITEventPlace *place in self.places) {
        if ([place.calendarsEvent.identifier isEqualToString:event.identifier]) {
            if ([[self.mapView selectedAnnotations] containsObject:place]) {
                [self.mapView deselectAnnotation:place animated:NO];
            }
            [self.mapView selectAnnotation:place animated:YES];
        }
    }
}

#pragma mark Setup

- (void)setupMapView
{
    [self.tiledMapView setButtonsHidden:YES animated:NO];
    self.mapView.delegate = self;
    self.mapView.showsUserLocation = YES;
    
    // This sets the color of the current location pin, which is otherwise inherited from the main window's MIT tint color...
    self.mapView.tintColor = [UIColor colorWithRed:0.0 green:122.0/255.0 blue:1.0 alpha:1.0];
    [self setupMapBoundingBoxAnimated:NO];
}

#pragma mark - Map View

- (void)setupMapBoundingBoxAnimated:(BOOL)animated
{
    [self.view layoutIfNeeded]; // ensure that map has autoresized before setting region
    
    if ([self.places count] > 0) {
        MKMapRect zoomRect = MKMapRectNull;
        for (id <MKAnnotation> annotation in self.places)
        {
            MKMapPoint annotationPoint = MKMapPointForCoordinate(annotation.coordinate);
            MKMapRect pointRect = MKMapRectMake(annotationPoint.x, annotationPoint.y, 0.1, 0.1);
            zoomRect = MKMapRectUnion(zoomRect, pointRect);
        }
        double inset = -zoomRect.size.width * 0.1;
        [self.mapView setVisibleMapRect:MKMapRectInset(zoomRect, inset, inset) animated:YES];
    } else {
        [self.mapView setRegion:kMITShuttleDefaultMapRegion animated:animated];
    }
}

#pragma mark - Places

- (void)setPlaces:(NSArray *)places
{
    [self setPlaces:places animated:NO];
}

- (void)setPlaces:(NSArray *)places animated:(BOOL)animated
{
    _places = places;
    [self refreshPlaceAnnotations];
    [self setupMapBoundingBoxAnimated:animated];
}

- (void)clearPlacesAnimated:(BOOL)animated
{
    [self setPlaces:nil animated:animated];
}

- (void)refreshPlaceAnnotations
{
    [self removeAllPlaceAnnotations];
    [self.mapView addAnnotations:self.places];
}

- (void)removeAllPlaceAnnotations
{
    NSMutableArray *annotationsToRemove = [NSMutableArray array];
    for (id <MKAnnotation> annotation in self.mapView.annotations) {
        if ([annotation isKindOfClass:[MITEventPlace class]]) {
            [annotationsToRemove addObject:annotation];
        }
    }
    [self.mapView removeAnnotations:annotationsToRemove];
}

#pragma mark - MKMapViewDelegate

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation
{
    if ([annotation isKindOfClass:[MITEventPlace class]]) {
        MITMapPlaceAnnotationView *annotationView = (MITMapPlaceAnnotationView *)[mapView dequeueReusableAnnotationViewWithIdentifier:kMITMapPlaceAnnotationViewIdentifier];
        if (!annotationView) {
            annotationView = [[MITMapPlaceAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:kMITMapPlaceAnnotationViewIdentifier];
        }
        [annotationView setNumber:[(MITEventPlace *)annotation displayNumber]];
        return annotationView;
    }
    return nil;
}

- (MKOverlayRenderer *)mapView:(MKMapView *)mapView rendererForOverlay:(id<MKOverlay>)overlay
{
    if ([overlay isKindOfClass:[MKTileOverlay class]]) {
        return [[MKTileOverlayRenderer alloc] initWithTileOverlay:overlay];
    }
    return nil;
}

- (void)mapView:(MKMapView *)mapView didSelectAnnotationView:(MKAnnotationView *)view
{
    if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad && [view isKindOfClass:[MITMapPlaceAnnotationView class]]) {
        MITEventPlace *place = view.annotation;
        MITEventDetailViewController *detailVC = [[MITEventDetailViewController alloc] initWithNibName:nil bundle:nil];
        detailVC.event = place.calendarsEvent;
        self.currentEventPopoverController = [[UIPopoverController alloc] initWithContentViewController:detailVC];
        UIView *annotationView = [self.mapView viewForAnnotation:place];
        
        CGFloat minTableHeight = 360;
        CGFloat tableHeight = 0;
        for (NSInteger section = 0; section < [detailVC numberOfSectionsInTableView:detailVC.tableView]; section++) {
            for (NSInteger row = 0; row < [detailVC tableView:detailVC.tableView numberOfRowsInSection:section]; row++) {
                tableHeight += [detailVC tableView:detailVC.tableView heightForRowAtIndexPath:[NSIndexPath indexPathForRow:row inSection:section]];
            }
        }
        
        CGFloat navbarHeight = 44;
        CGFloat statusBarHeight = 20;
        CGFloat toolbarHeight = 44;
        CGFloat padding = 30;
        CGFloat maxPopoverHeight = self.view.bounds.size.height - navbarHeight - statusBarHeight - toolbarHeight - (2 * padding);
        
        if (tableHeight > maxPopoverHeight) {
            tableHeight = maxPopoverHeight;
        } if (tableHeight < minTableHeight) {
            tableHeight = minTableHeight;
        }
        
        self.currentEventPopoverController.passthroughViews = @[self.navigationController.toolbar];
        [self.currentEventPopoverController setPopoverContentSize:CGSizeMake(320, tableHeight) animated:NO];
        [self.currentEventPopoverController presentPopoverFromRect:annotationView.bounds inView:annotationView permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
    }
}

- (void)mapView:(MKMapView *)mapView didDeselectAnnotationView:(MKAnnotationView *)view
{
    
}

- (void)mapView:(MKMapView *)mapView regionDidChangeAnimated:(BOOL)animated
{
    if (self.shouldRefreshAnnotationsOnNextMapRegionChange) {
        [self refreshPlaceAnnotations];
        self.shouldRefreshAnnotationsOnNextMapRegionChange = NO;
    }
    
}

#pragma mark - Map View

- (MKMapView *)mapView
{
    return self.tiledMapView.mapView;
}

#pragma mark - Loading Events Into Map

- (void)updateMapWithEvents:(NSArray *)eventsArray
{
    [self removeAllPlaceAnnotations];
    NSMutableArray *annotationsToAdd = [NSMutableArray array];
    int totalNumberOfVisibleHolidays = 0;
    for (int i = 0; i < eventsArray.count; i++) {
        MITCalendarsEvent *event = eventsArray[i];
        if (!event.isHoliday) {
            MITEventPlace *eventPlace = [[MITEventPlace alloc] initWithCalendarsEvent:event];
            if (eventPlace) {
                eventPlace.displayNumber = (i + 1) - totalNumberOfVisibleHolidays;
                [annotationsToAdd addObject:eventPlace];
            }
        }
        else {
            totalNumberOfVisibleHolidays++;
        }
    }
    
    self.places = annotationsToAdd;
}

@end
