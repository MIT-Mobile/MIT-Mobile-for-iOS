#import "MITMapPlaceAnnotationView.h"
#import "MITResourceConstants.h"

#define shadowOffsetHeight 5.0
#define shadowOffsetWidth 2.0

@interface MITMapPlaceAnnotationView()

@property (nonatomic, strong) UILabel *numberLabel;

@end

@implementation MITMapPlaceAnnotationView

- (instancetype)initWithAnnotation:(id<MKAnnotation>)annotation reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithAnnotation:annotation reuseIdentifier:reuseIdentifier];
    if (self) {
        
        UIImage *redPinBall = [UIImage imageNamed:MITImageMapPinBallRed];
        
        self.image = [self drawAnnotationWithPinBallImage:redPinBall];
        self.centerOffset = CGPointMake(0, -self.image.size.height / 2);
        self.calloutOffset = CGPointMake((redPinBall.size.width - self.image.size.width)/2, 0);
        
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

- (UIImage *)drawAnnotationWithPinBallImage:(UIImage *)pinBallImage
{
    UIImage *pinNeedleImage = [UIImage imageNamed:MITImageMapPinNeedle];
    UIImage *pinShadowImage = [UIImage imageNamed:MITImageMapPinShadow];
    
    CGFloat widthOfPin = (pinBallImage.size.width/2 - (pinNeedleImage.size.width/2 + shadowOffsetWidth)) + pinShadowImage.size.width;
    
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(widthOfPin, pinBallImage.size.height + pinNeedleImage.size.height), NO, 0);
    
    [pinBallImage drawInRect:CGRectMake(0, 0, pinBallImage.size.width, pinBallImage.size.height)];
    [pinNeedleImage drawInRect:CGRectMake(pinBallImage.size.width/2 - pinNeedleImage.size.width/2,
                                          pinBallImage.size.height,
                                          pinNeedleImage.size.width,
                                          pinNeedleImage.size.height)];
    
    [pinShadowImage drawInRect:CGRectMake(pinBallImage.size.width/2 - (pinNeedleImage.size.width/2 + shadowOffsetWidth),
                                          (pinNeedleImage.size.height + pinBallImage.size.height) - (pinShadowImage.size.height - shadowOffsetHeight),
                                          pinShadowImage.size.width,
                                          pinShadowImage.size.height)];
    
    pinBallImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return pinBallImage;
}

- (void)setupNumberLabel
{
    UIImage *pinBallImage = [UIImage imageNamed:MITImageMapPinBallRed];
    
    UILabel *numberLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, pinBallImage.size.width, pinBallImage.size.height)];
    numberLabel.font = [UIFont fontWithName:@"HelveticaNeue-Medium" size:15.0];
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

- (void)setBlueColor
{
    [self.numberLabel removeFromSuperview];
    self.image = [self drawAnnotationWithPinBallImage:[UIImage imageNamed:MITImageMapPinBallBlue]];
    [self setupNumberLabel];
}

- (void)setRedColor
{
    [self.numberLabel removeFromSuperview];
    self.image = [self drawAnnotationWithPinBallImage:[UIImage imageNamed:MITImageMapPinBallRed]];
    [self setupNumberLabel];
}

@end
