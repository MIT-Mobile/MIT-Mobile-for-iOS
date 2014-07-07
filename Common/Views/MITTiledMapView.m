#import "MITTiledMapView.h"

const MKCoordinateRegion kMITShuttleDefaultMapRegion = {{42.357353, -71.095098}, {0.015, 0.015}};

static CGFloat const kBottomButtonSize = 46;
static CGFloat const kBottomButtonPadding = 20;

@interface MITTiledMapView()

@property (nonatomic, strong) UIButton *leftButton;
@property (nonatomic, strong) UIButton *rightButton;

@end

@implementation MITTiledMapView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setup];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self setup];
    }
    return self;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

#pragma mark - Private Methods

- (void)setup
{
    [self setupMapView];
    [self setupTileOverlays];
    [self setupButtons];
}

- (void)setupMapView
{
    self.mapView = [[MKMapView alloc] initWithFrame:self.frame];
    self.mapView.translatesAutoresizingMaskIntoConstraints = NO;
    [self addSubview:self.mapView];
    
    NSDictionary *viewDictionary = @{@"mapView": self.mapView};
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[mapView]|" options:0 metrics:nil views:viewDictionary]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[mapView]|" options:0 metrics:nil views:viewDictionary]];
}

- (void)centerMapOnUserLocation
{
    if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorized) {
        [self.mapView setCenterCoordinate:self.mapView.userLocation.location.coordinate animated:YES];
    } else {
        [[[UIAlertView alloc] initWithTitle:nil message:@"Turn on Location Services to Allow Shuttles to Determine Your Location." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
    }
}

#pragma mark - Public Methods

- (void)setButtonsHidden:(BOOL)hidden animated:(BOOL)animated
{
    void (^hideButtonsBlock)(void) = ^{
        self.leftButton.alpha = hidden ? 0 : 1;
        self.rightButton.alpha = hidden ? 0 : 1;
    };
    
    [self bringSubviewToFront:self.leftButton];
    [self bringSubviewToFront:self.rightButton];
    
    if (animated) {
        [UIView animateWithDuration:0.5 animations:hideButtonsBlock];
    } else {
        hideButtonsBlock();
    }
}

- (void)setLeftButtonHidden:(BOOL)hidden animated:(BOOL)animated
{
    void (^hideButtonBlock)(void) = ^{
        self.leftButton.alpha = hidden ? 0 : 1;
    };
    
    if (animated) {
        [UIView animateWithDuration:0.5 animations:hideButtonBlock];
    } else {
        hideButtonBlock();
    }
}

- (void)setRightButtonHidden:(BOOL)hidden animated:(BOOL)animated
{
    void (^hideButtonBlock)(void) = ^{
        self.rightButton.alpha = hidden ? 0 : 1;
    };
    
    if (animated) {
        [UIView animateWithDuration:0.5 animations:hideButtonBlock];
    } else {
        hideButtonBlock();
    }
}

#pragma mark - Buttons

- (void)setupButtons
{
    [self setupLeftButton];
    [self setupRightButton];
}

- (void)setupLeftButton
{
    self.leftButton = [[UIButton alloc] initWithFrame:CGRectMake(kBottomButtonPadding, self.frame.size.height - kBottomButtonSize - kBottomButtonPadding, kBottomButtonSize, kBottomButtonSize)];
    [self.leftButton addTarget:self action:@selector(leftButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    self.leftButton.layer.borderWidth = 1;
    self.leftButton.layer.borderColor = [UIColor lightGrayColor].CGColor;
    self.leftButton.layer.cornerRadius = 4;
    self.leftButton.backgroundColor = [UIColor colorWithWhite:0.88 alpha:1];
    self.leftButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self addSubview:self.leftButton];
    
    NSDictionary *viewsDictionary = @{@"leftButton": self.leftButton};
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:[NSString stringWithFormat:@"H:|-%f-[leftButton(==%f)]", kBottomButtonPadding, kBottomButtonSize] options:0 metrics:nil views:viewsDictionary]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:[NSString stringWithFormat:@"V:[leftButton(==%f)]-%f-|", kBottomButtonSize, kBottomButtonPadding] options:0 metrics:nil views:viewsDictionary]];
}

- (void)setupRightButton
{
    self.rightButton = [[UIButton alloc] initWithFrame:CGRectMake(self.frame.size.width - kBottomButtonSize - kBottomButtonPadding, self.frame.size.height - kBottomButtonSize - kBottomButtonPadding, kBottomButtonSize, kBottomButtonSize)];
    [self.rightButton addTarget:self action:@selector(rightButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    self.rightButton.layer.borderWidth = 1;
    self.rightButton.layer.borderColor = [UIColor lightGrayColor].CGColor;
    self.rightButton.layer.cornerRadius = 4;
    self.rightButton.backgroundColor = [UIColor colorWithWhite:0.88 alpha:1];
    self.rightButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self addSubview:self.rightButton];
    
    NSDictionary *viewsDictionary = @{@"rightButton": self.rightButton};
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:[NSString stringWithFormat:@"H:[rightButton(==%f)]-%f-|", kBottomButtonSize, kBottomButtonPadding] options:0 metrics:nil views:viewsDictionary]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:[NSString stringWithFormat:@"V:[rightButton(==%f)]-%f-|", kBottomButtonSize, kBottomButtonPadding] options:0 metrics:nil views:viewsDictionary]];
}

- (void)leftButtonTapped:(id)sender
{
    [self centerMapOnUserLocation];
}

- (void)rightButtonTapped:(id)sender
{
    if ([self.buttonDelegate respondsToSelector:@selector(mitTiledMapViewRightButtonPressed:)]) {
        [self.buttonDelegate mitTiledMapViewRightButtonPressed:self];
    }
}

#pragma mark - Tile Overlays

- (void)setupTileOverlays
{
    [self setupBaseTileOverlay];
    [self setupMITTileOverlay];
}

- (void)setupMITTileOverlay
{
    static NSString * const template = @"http://m.mit.edu/api/arcgis/WhereIs_Base_Topo/MapServer/tile/{z}/{y}/{x}";
    
    MKTileOverlay *MITTileOverlay = [[MKTileOverlay alloc] initWithURLTemplate:template];
    MITTileOverlay.canReplaceMapContent = YES;
    
    [self.mapView addOverlay:MITTileOverlay level:MKOverlayLevelAboveLabels];
}

- (void)setupBaseTileOverlay
{
    static NSString * const template = @"http://services.arcgisonline.com/ArcGIS/rest/services/World_Topo_Map/MapServer/tile/{z}/{y}/{x}";
    
    MKTileOverlay *baseTileOverlay = [[MKTileOverlay alloc] initWithURLTemplate:template];
    baseTileOverlay.canReplaceMapContent = YES;
    
    [self.mapView addOverlay:baseTileOverlay level:MKOverlayLevelAboveLabels];
}

@end
