#import "MITToursCalloutContentView.h"
#import "UIFont+MITTours.h"
#import "UIKit+MITAdditions.h"

#define SMOOTS_PER_MILE 945.671642
#define MILES_PER_METER 0.000621371

@interface MITToursCalloutContentView ()

@property (strong, nonatomic) UIView *containerView;

@property (weak, nonatomic) IBOutlet UILabel *stopTypeLabel;
@property (weak, nonatomic) IBOutlet UILabel *stopNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *distanceLabel;
@property (weak, nonatomic) IBOutlet UIImageView *disclosureImage;

@property (strong, nonatomic) UIGestureRecognizer *tapRecognizer;

@end

@implementation MITToursCalloutContentView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setup];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self setup];
    }
    return self;
}

- (void)setup
{
    UIView *view = nil;
    NSArray *objects = [[NSBundle mainBundle] loadNibNamed:@"MITToursCalloutContentView" owner:self options:nil];
    for (id object in objects) {
        if ([object isKindOfClass:[UIView class]]) {
            view = object;
            break;
        }
    }
    if (view) {
        self.containerView = view;
        [self addSubview:view];
        
        self.tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(calloutWasTapped:)];
        [view addGestureRecognizer:self.tapRecognizer];
    }
}

- (void)configureForStop:(MITToursStop *)stop userLocation:(CLLocation *)userLocation
{
    self.stop = stop;
    self.stopType = stop.stopType;
    self.stopName = stop.title;
    if (userLocation) {
        // TODO: DRY this out
        NSArray *stopCoords = stop.coordinates;
        // Convert to location coordinate
        NSNumber *longitude = [stopCoords objectAtIndex:0];
        NSNumber *latitude = [stopCoords objectAtIndex:1];
        CLLocation *stopLocation = [[CLLocation alloc] initWithLatitude:[latitude doubleValue]
                                                              longitude:[longitude doubleValue]];

        self.distanceInMiles = [stopLocation distanceFromLocation:userLocation]  * MILES_PER_METER;
        self.shouldDisplayDistance = YES;
    } else {
        self.shouldDisplayDistance = NO;
    }
    
    // For now we will assume that the provided stopType is a user-facing string,
    // but to be more robust we might consider using an enum value and having the
    // view generate its own text.
    self.stopTypeLabel.text = [self.stopType uppercaseString];
    self.stopTypeLabel.font = [UIFont toursMapCalloutSubtitle];
    self.stopTypeLabel.textColor = [UIColor mit_greyTextColor];
    self.stopTypeLabel.preferredMaxLayoutWidth = [self maxLabelWidth];
    
    self.stopNameLabel.text = self.stopName;
    self.stopNameLabel.font = [UIFont toursMapCalloutTitle];
    self.stopNameLabel.preferredMaxLayoutWidth = [self maxLabelWidth];
    
    if (self.shouldDisplayDistance) {
        CGFloat smoots = self.distanceInMiles * SMOOTS_PER_MILE;
        self.distanceLabel.text = [NSString stringWithFormat:@"%.01f miles (%.f smoots)", self.distanceInMiles, smoots];
    } else {
        self.distanceLabel.text = @"";
    }
    self.distanceLabel.font = [UIFont toursMapCalloutSubtitle];
    self.distanceLabel.textColor = [UIColor mit_greyTextColor];
    self.distanceLabel.preferredMaxLayoutWidth = [self maxLabelWidth];
    
    [self.disclosureImage setImage:[UIImage imageNamed:@"map/map_disclosure_arrow"]];
    
    [self.containerView setNeedsLayout];
    [self sizeToFit];
}

- (void)calloutWasTapped:(UIGestureRecognizer *)sender
{
    if ([self.delegate respondsToSelector:@selector(calloutWasTappedForStop:)]) {
        [self.delegate calloutWasTappedForStop:self.stop];
    }
}

- (CGSize)sizeThatFits:(CGSize)size
{
    return self.intrinsicContentSize;
}

- (CGSize)intrinsicContentSize
{
    return [self.containerView systemLayoutSizeFittingSize:UILayoutFittingCompressedSize];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    self.containerView.frame = self.bounds;
}

- (CGFloat)maxLabelWidth
{
    return 200;
}

@end
