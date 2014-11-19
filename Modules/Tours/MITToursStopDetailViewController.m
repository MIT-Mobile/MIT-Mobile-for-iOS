#import "MITToursStopDetailViewController.h"
#import "MITToursImage.h"
#import "MITToursImageRepresentation.h"
#import "UIImageView+WebCache.h"
#import "MITToursStopCollectionViewManager.h"
#import "MITToursStopInfiniteScrollCollectionViewManager.h"
#import "MITInfiniteScrollCollectionView.h"
#import "UIFont+MITTours.h"

@interface MITToursStopDetailViewController () <UIScrollViewDelegate, MITToursCollectionViewManagerDelegate>

@property (strong, nonatomic) NSArray *mainLoopStops;
@property (nonatomic) NSUInteger mainLoopIndex;

@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;

@property (weak, nonatomic) IBOutlet MITInfiniteScrollCollectionView *mainLoopCollectionView;
@property (strong, nonatomic) MITToursStopInfiniteScrollCollectionViewManager *mainLoopCollectionViewManager;

@property (weak, nonatomic) IBOutlet UICollectionView *nearHereCollectionView;
@property (strong, nonatomic) MITToursStopCollectionViewManager *nearHereCollectionViewManager;

@property (weak, nonatomic) IBOutlet UIImageView *stopImageView;
@property (weak, nonatomic) IBOutlet UILabel *stopTitleLabel;
@property (weak, nonatomic) IBOutlet UILabel *bodyTextLabel;

@property (strong, nonatomic) NSArray *mainLoopCycleButtons;

@property (nonatomic) BOOL isTitleVisible;
@property (nonatomic) CGFloat titleBottom;
@property (nonatomic) CGFloat lastScrollOffset;

@end

@implementation MITToursStopDetailViewController

- (instancetype)initWithTour:(MITToursTour *)tour stop:(MITToursStop *)stop nibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.tour = tour;
        self.stop = stop;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.scrollView.delegate = self;
    
    [self setupLabels];
    [self setupCollectionViews];
    [self configureForStop:self.stop];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
    // Scroll to top
    [self.scrollView setContentOffset:CGPointMake(0, 0) animated:NO];
}

- (void)setupLabels
{
    self.stopTitleLabel.preferredMaxLayoutWidth = self.stopTitleLabel.bounds.size.width;
    self.bodyTextLabel.preferredMaxLayoutWidth = self.bodyTextLabel.bounds.size.width;
}

- (void)setupCollectionViews
{
    self.mainLoopCollectionViewManager = [[MITToursStopInfiniteScrollCollectionViewManager alloc] init];
    self.nearHereCollectionViewManager = [[MITToursStopCollectionViewManager alloc] init];
    
    self.mainLoopCollectionViewManager.collectionView = self.mainLoopCollectionView;
    self.nearHereCollectionViewManager.collectionView = self.nearHereCollectionView;
    
    [self.mainLoopCollectionViewManager setup];
    [self.nearHereCollectionViewManager setup];
    
    self.mainLoopCollectionViewManager.delegate = self;
    self.nearHereCollectionViewManager.delegate = self;
    
    self.mainLoopCollectionView.dataSource = self.mainLoopCollectionViewManager;
    self.mainLoopCollectionView.delegate = self.mainLoopCollectionViewManager;
    
    self.nearHereCollectionView.dataSource = self.nearHereCollectionViewManager;
    self.nearHereCollectionView.delegate = self.nearHereCollectionViewManager;
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    self.titleBottom = CGRectGetMaxY(self.stopTitleLabel.frame);
    [self updateTitleVisibility];
}

- (void)setTour:(MITToursTour *)tour
{
    _tour = tour;
    self.mainLoopStops = [[tour mainLoopStops] copy];
}

- (void)setStop:(MITToursStop *)stop
{
    if (_stop != stop) {
        _stop = stop;
        self.mainLoopIndex = [self.mainLoopStops indexOfObject:stop];
        [self configureForStop:stop];
    }
}

- (void)configureForStop:(MITToursStop *)stop
{
    self.stopTitleLabel.text = stop.title;
    [self configureBodyTextForStop:stop];
    [self configureImageForStop:stop];
    
    // Set up "Main Loop" stops
    NSInteger index = [self.mainLoopStops indexOfObject:stop];
    if (index == NSNotFound) {
        index = 0;
    }
    // We want the current stop to be the first stop in display order
    NSMutableArray *sortedMainLoopStops = [[NSMutableArray alloc] init];
    for (NSInteger i = index; i < self.mainLoopStops.count; i++) {
        [sortedMainLoopStops addObject:[self.mainLoopStops objectAtIndex:i]];
    }
    for (NSInteger i = 0; i < index; i++) {
        [sortedMainLoopStops addObject:[self.mainLoopStops objectAtIndex:i]];
    }
    self.mainLoopCollectionViewManager.stops = self.mainLoopStops;
    self.mainLoopCollectionViewManager.stopsInDisplayOrder = sortedMainLoopStops;
    self.mainLoopCollectionViewManager.selectedStop = stop;
    [self.mainLoopCollectionView reloadData];
    
    // Set up "Near Here" stops
    // Exclude the current stop from the "near here" list
    NSMutableArray *otherStops = [self.tour.stops mutableCopy];
    [otherStops removeObject:stop];
    
    // Order the stops by distance from the current stop
    CLLocation *currentStopLocation = [stop locationForStop];
    NSArray *sortedStops = [otherStops sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        CLLocationDistance distance1 = [[((MITToursStop *)obj1) locationForStop] distanceFromLocation:currentStopLocation];
        CLLocationDistance distance2 = [[((MITToursStop *)obj2) locationForStop] distanceFromLocation:currentStopLocation];
        if (distance1 < distance2) {
            return NSOrderedAscending;
        } else if (distance1 > distance2) {
            return NSOrderedDescending;
        }
        return NSOrderedSame;
    }];
    self.nearHereCollectionViewManager.stops = [self.tour.stops copy];
    self.nearHereCollectionViewManager.stopsInDisplayOrder = [sortedStops copy];
    self.nearHereCollectionViewManager.selectedStop = stop;
    [self.nearHereCollectionView reloadData];
    
    [self.view setNeedsLayout];
}

- (void)configureBodyTextForStop:(MITToursStop *)stop
{
    NSData *bodyTextData = [NSData dataWithBytes:[stop.bodyHTML cStringUsingEncoding:NSUTF8StringEncoding] length:stop.bodyHTML.length];
    NSMutableAttributedString *bodyString = [[NSMutableAttributedString alloc] initWithData:bodyTextData options:@{NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType} documentAttributes:NULL error:nil];
    
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.lineHeightMultiple = 1.0;

    NSDictionary *attributes = @{ NSParagraphStyleAttributeName: paragraphStyle,
                                  NSFontAttributeName: [UIFont toursTitle] };
    [bodyString addAttributes:attributes range:NSMakeRange(0, bodyString.length)];
    
    [self.bodyTextLabel setAttributedText:bodyString];
}

- (void)configureImageForStop:(MITToursStop *)stop
{
    if (stop.images.count) {
        NSString *stopImageURLString = [self.stop fullImageURL];
        if (stopImageURLString) {
            [self.stopImageView sd_setImageWithURL:[NSURL URLWithString:stopImageURLString] completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
                [self.view setNeedsLayout];
            }];
        }
    }
}

#pragma mark - Title Visibility

- (void)updateTitleVisibility
{
    BOOL wasAboveTitle = self.lastScrollOffset < self.titleBottom;
    BOOL isAboveTitle = self.scrollView.contentOffset.y < self.titleBottom;
    
    self.lastScrollOffset = self.scrollView.contentOffset.y;
    
    if (wasAboveTitle && !isAboveTitle && [self.delegate respondsToSelector:@selector(stopDetailViewControllerTitleDidScrollBelowTitle:)]) {
        [self.delegate stopDetailViewControllerTitleDidScrollBelowTitle:self];
    } else if (!wasAboveTitle && isAboveTitle && [self.delegate respondsToSelector:@selector(stopDetailViewControllerTitleDidScrollAboveTitle:)]) {
        [self.delegate stopDetailViewControllerTitleDidScrollAboveTitle:self];
    }
}

#pragma mark - UIScrollViewDelegate Methods

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    [self updateTitleVisibility];
}

#pragma mark - MITToursCollectionViewManagerDelegate Methods

- (void)collectionView:(UICollectionView *)collectionView didSelectItemForStop:(MITToursStop *)stop
{
    if ([self.delegate respondsToSelector:@selector(stopDetailViewController:didSelectStop:)]) {
        [self.delegate stopDetailViewController:self didSelectStop:stop];
    }
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    self.mainLoopCollectionView.contentOffset = [self.mainLoopCollectionView.collectionViewLayout targetContentOffsetForProposedContentOffset:self.mainLoopCollectionView.contentOffset];
    self.nearHereCollectionView.contentOffset = [self.nearHereCollectionView.collectionViewLayout targetContentOffsetForProposedContentOffset:self.nearHereCollectionView.contentOffset];
}

@end
