#import "MITMapPlaceAnnotationView.h"

@interface MITMapPlaceAnnotationView()

@property (nonatomic, strong) UILabel *numberLabel;

@end

@implementation MITMapPlaceAnnotationView

- (instancetype)initWithAnnotation:(id<MKAnnotation>)annotation reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithAnnotation:annotation reuseIdentifier:reuseIdentifier];
    if (self) {
        self.image = [UIImage imageNamed:MITImageMapAnnotationPlacePin];
        self.centerOffset = CGPointMake(0, -self.image.size.height / 2);
        
        if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone) {
            self.canShowCallout = YES;
        } else {
            self.canShowCallout = NO;
        }
        
        [self setupDisclosureButton];
        [self setupNumberLabel];
    }
    return self;
}

- (void)setupNumberLabel
{
    UILabel *numberLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, self.frame.size.width)];
    numberLabel.font = [UIFont systemFontOfSize:11.0];
    numberLabel.textColor = [UIColor whiteColor];
    numberLabel.backgroundColor = [UIColor clearColor];
    numberLabel.textAlignment = NSTextAlignmentCenter;
    [self addSubview:numberLabel];
    self.numberLabel = numberLabel;
}

- (void)setupDisclosureButton
{
    UIButton *disclosureButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 30, 44)];
    [disclosureButton setImage:[UIImage imageNamed:MITImageDisclosureRight] forState:UIControlStateNormal];
    self.rightCalloutAccessoryView = disclosureButton;
}

- (void)setNumber:(NSInteger)number
{
    self.numberLabel.text = [@(number) stringValue];
}

@end
