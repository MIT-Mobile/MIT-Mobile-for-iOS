#import "MITMobiusCalloutContentView.h"

@interface MITMobiusCalloutContentView ()
@property (weak, nonatomic) IBOutlet UILabel *roomNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *machineListLabel;

@end

@implementation MITMobiusCalloutContentView

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
/*
- (void)setup
{
    UIView *view = nil;
    NSArray *objects = [[NSBundle mainBundle] loadNibNamed:@"MITMobiusCalloutContentView" owner:self options:nil];
    for (id object in objects) {
        if ([object isKindOfClass:[UIView class]]) {
            view = object;
            break;
        }
    }
    if (view) {
        [self addSubview:view];
        
        self.userInteractionEnabled = NO;
        self.exclusiveTouch = NO;
    }
}*/


- (void)setup
{
  /*  NSString *nibName = NSStringFromClass([self class]);
    UINib *nib = [UINib nibWithNibName:nibName bundle:nil];
    NSAssert(nib, @"failed to load nib %@",nibName);
    [nib instantiateWithOwner:self options:nil];
    
    */
    
    UIView *calloutContentView = nil;
    NSArray *objects = [[NSBundle mainBundle] loadNibNamed:@"MITMobiusCalloutContentView" owner:self options:nil];
    for (id object in objects) {
        if ([object isKindOfClass:[UIView class]]) {
            calloutContentView = object;
            break;
        }
    }
    if (calloutContentView) {
        
        //NSAssert([view isKindOfClass:[MITMobiusCalloutContentView class]], @"root view in nib %@ is kind of %@, expected %@",nibName,NSStringFromClass([view class]),NSStringFromClass([MITMobiusCalloutContentView class]));
        
        calloutContentView.autoresizingMask = (UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth);
        calloutContentView.translatesAutoresizingMaskIntoConstraints = YES;
        
        // Do a bit of messing with the frame here to ensure that when
        // the calloutContentView is loaded and then added as a subview, its constraints
        // are not violated. Assumes that the constraints (as set in IB) have no
        // warnings or errors.
        // (bskinner - 2015.03.03)
        CGRect updatedFrame = self.frame;
        updatedFrame.size.width = MAX(CGRectGetWidth(self.frame), CGRectGetWidth(calloutContentView.frame));
        updatedFrame.size.height = MAX(CGRectGetHeight(self.frame), CGRectGetHeight(calloutContentView.frame));
        self.frame = updatedFrame;
        calloutContentView.frame = self.bounds;
        
        [self addSubview:calloutContentView];
        
        self.userInteractionEnabled = NO;
        self.exclusiveTouch = NO;
    }
}

- (void)setRoomName:(NSString *)roomName
{
    if (![_roomName isEqualToString:roomName]) {
        _roomName = [roomName copy];
        _roomNameLabel.text = roomName;
    }
    [self setNeedsUpdateConstraints];
    [self setNeedsLayout];
}

- (void)setMachineList:(NSString *)machineList
{
    if (![_roomName isEqualToString:machineList]) {
        _machineList = [machineList copy];
        _machineListLabel.text = machineList;
    }
    [self setNeedsUpdateConstraints];
    [self setNeedsLayout];
}

@end
