#import "MITMartyCalloutContentView.h"
#import "UIFont+MITTours.h"
#import "UIKit+MITAdditions.h"
#import "MITMartyResourceView.h"

@interface MITMartyCalloutContentView ()
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
    NSString *nibName = NSStringFromClass([self class]);
    UINib *nib = [UINib nibWithNibName:nibName bundle:nil];
    NSAssert(nib, @"failed to load nib %@",nibName);
    [nib instantiateWithOwner:self options:nil];
    
    NSAssert([self.resourceView isKindOfClass:[MITMartyResourceView class]], @"root view in nib %@ is kind of %@, expected %@",nibName,NSStringFromClass([self.resourceView class]),NSStringFromClass([MITMartyResourceView class]));

    self.resourceView.autoresizingMask = (UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth);
    self.resourceView.translatesAutoresizingMaskIntoConstraints = YES;
    
    // Do a bit of messing with the frame here to ensure that when
    // the resourceView is loaded and then added as a subview, its constraints
    // are not violated. Assumes that the constraints (as set in IB) have no
    // warnings or errors.
    // (bskinner - 2015.03.03)
    CGRect updatedFrame = self.frame;
    updatedFrame.size = self.resourceView.frame.size;
    self.frame = updatedFrame;
    self.resourceView.frame = self.bounds;
    
    [self addSubview:self.resourceView];
    
    self.userInteractionEnabled = NO;
    self.exclusiveTouch = NO;
}

@end
