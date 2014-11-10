#import "MITToursStopDetailViewController.h"
#import "MITToursImage.h"
#import "MITToursImageRepresentation.h"
#import "UIImageView+WebCache.h"
#import "MITToursStopCollectionViewManager.h"
#import "MITToursStopInfiniteScrollCollectionViewManager.h"
#import "MITInfiniteScrollCollectionView.h"

@interface MITToursStopDetailViewController () <UIScrollViewDelegate>

@property (strong, nonatomic) NSArray *mainLoopStops;
@property (nonatomic) NSUInteger mainLoopIndex;

@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;

@property (weak, nonatomic) IBOutlet MITInfiniteScrollCollectionView *mainLoopCollectionView;
@property (strong, nonatomic) IBOutlet MITToursStopInfiniteScrollCollectionViewManager *mainLoopCollectionViewManager;

@property (weak, nonatomic) IBOutlet UICollectionView *nearHereCollectionView;
@property (strong, nonatomic) IBOutlet MITToursStopCollectionViewManager *nearHereCollectionViewManager;

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
    
    self.bodyTextLabel.preferredMaxLayoutWidth = self.bodyTextLabel.bounds.size.width;
    [self.mainLoopCollectionViewManager setup];
    [self.nearHereCollectionViewManager setup];
    [self configureForStop:self.stop];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
    // Scroll to top
    [self.scrollView setContentOffset:CGPointMake(0, 0) animated:NO];
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
    
    NSInteger index = [self.mainLoopStops indexOfObject:stop];
    if (index == NSNotFound) {
        index = 0;
    }
    // We want the current stop to be the "center" of the array of stops.
    NSMutableArray *sortedMainLoopStops = [[NSMutableArray alloc] init];
    NSInteger offset = index - self.mainLoopStops.count / 2;
    for (NSInteger i = 0; i < self.mainLoopStops.count; i++) {
        NSInteger nextIndex = (i + offset + self.mainLoopStops.count) % self.mainLoopStops.count;
        [sortedMainLoopStops addObject:[self.mainLoopStops objectAtIndex:nextIndex]];
    }
    self.mainLoopCollectionViewManager.stops = self.mainLoopStops;
    self.mainLoopCollectionViewManager.stopsInDisplayOrder = sortedMainLoopStops;
    self.mainLoopCollectionViewManager.selectedStop = stop;
    [self.mainLoopCollectionView reloadData];
    [self.mainLoopCollectionView scrollToCenterItemAnimated:NO];
    
    // Order the stops by distance from the current stop
    CLLocation *currentStopLocation = [stop locationForStop];
    NSArray *sortedStops = [self.tour.stops sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
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
    [bodyString addAttribute:NSParagraphStyleAttributeName value:paragraphStyle range:NSMakeRange(0, bodyString.length)];
    
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

@end
