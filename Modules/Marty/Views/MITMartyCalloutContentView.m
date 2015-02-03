#import "MITMartyCalloutContentView.h"
#import "UIFont+MITTours.h"
#import "UIKit+MITAdditions.h"

@interface MITMartyCalloutContentView ()

@property (strong, nonatomic) UIView *containerView;

@property(nonatomic,weak) IBOutlet UILabel *machineNameLabel;
@property(nonatomic,weak) IBOutlet UILabel *locationLabel;
@property(nonatomic,weak) IBOutlet UILabel *statusLabel;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *distanceSpacingConstraint;

@property (strong, nonatomic) UIGestureRecognizer *tapRecognizer;

@end

@implementation MITMartyCalloutContentView

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
    NSArray *objects = [[NSBundle mainBundle] loadNibNamed:@"MITMartyCalloutContentView" owner:self options:nil];
    for (id object in objects) {
        if ([object isKindOfClass:[UIView class]]) {
            view = object;
            break;
        }
    }
    if (view) {
        self.containerView = view;
        [self addSubview:view];
        
        self.userInteractionEnabled = NO;
        self.exclusiveTouch = NO;
    }
}

- (void)configureForResource:(MITMartyResource *)resource
{
    
    [self setStatus:MITMartyResourceStatusOnline withText:resource.status];
    self.machineNameLabel.text = resource.name;
    self.locationLabel.text = resource.room;
        
    [self.containerView setNeedsUpdateConstraints];
    [self.containerView setNeedsLayout];
    [self sizeToFit];
}

- (void)setStatus:(MITMartyResourceStatus)status withText:(NSString *)statusText
{
    self.statusLabel.text = [statusText copy];
    
    switch (status) {
        case MITMartyResourceStatusOffline: {
            self.statusLabel.textColor = [UIColor mit_closedRedColor];
        } break;
            
        case MITMartyResourceStatusOnline: {
            self.statusLabel.textColor = [UIColor mit_openGreenColor];
        } break;
            
        case MITMartyResourceStatusUnknown: {
            self.statusLabel.textColor = [UIColor orangeColor];
        } break;
    }
    
    [self.statusLabel sizeToFit];
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

@end
