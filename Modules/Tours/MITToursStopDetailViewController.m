#import "MITToursStopDetailViewController.h"
#import "MITToursImage.h"
#import "MITToursImageRepresentation.h"
#import "UIImageView+WebCache.h"

@interface MITToursStopDetailViewController () <UIScrollViewDelegate>

@property (strong, nonatomic) NSArray *mainLoopStops;
@property (strong, nonatomic) NSArray *sideTripStops;
@property (nonatomic) NSUInteger mainLoopIndex;

@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;

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
    self.sideTripStops = [[tour sideTripsStops] copy];
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
