#import "MITMobiusDetailHeader.h"
#import "UIKit+MITAdditions.h"
#import <SDWebImage/UIImageView+WebCache.h>
#import "MITMobiusImage.h"
#import "MITMobiusResourceAttributeValueSet.h"

@interface MITMobiusDetailHeader ()
@property (weak, nonatomic) IBOutlet UILabel *resourceName;
@property (weak, nonatomic) IBOutlet UILabel *resourceStatus;
@property (weak, nonatomic) IBOutlet UILabel *descriptionLabel;
@property (weak, nonatomic) IBOutlet UIImageView *resourceImageView;
@property (weak, nonatomic) IBOutlet UIImageView *statusImageView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *resourceImageViewHeightConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *statusTextFieldLeftConstraint;

@end

@implementation MITMobiusDetailHeader
- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
    }
    return self;
}

+ (UINib *)titleHeaderNib
{
    return [UINib nibWithNibName:self.titleHeaderNibName bundle:nil];
}

+ (NSString *)titleHeaderNibName
{
    return @"MITMobiusDetailHeader";
}

- (void)awakeFromNib
{
    self.resourceImageView.backgroundColor = [UIColor colorWithWhite:224.0 / 255.0 alpha:1.0];
}

- (IBAction)didTapImage:(id)sender {
    if (self.galleryHandler) {
        self.galleryHandler();
    }
}

- (void)setResource:(MITMobiusResource *)resource
{
    _resource = resource;
    
    if (_resource) {
        __block NSString *name = nil;
        __block NSString *status = nil;
        __block NSString *makeAndModel = nil;
        __block NSURL *imageURL = nil;
        [_resource.managedObjectContext performBlockAndWait:^{
            name = resource.name;
            status = resource.status;
            makeAndModel = resource.makeAndModel;
            
            CGSize idealImageSize = CGSizeZero;
            idealImageSize = self.resourceImageView.frame.size;
            MITMobiusImage *image = [self.resource.images firstObject];
            imageURL = [image URLForImageWithSize:MITMobiusImageLarge];
        }];
        
        self.resourceName.text = name;
        self.descriptionLabel.text = makeAndModel;

        if ([status caseInsensitiveCompare:@"online"] == NSOrderedSame) {
            self.resourceStatus.textColor = [UIColor mit_openGreenColor];
            self.statusTextFieldLeftConstraint.constant = 15.0;
            self.statusImageView.hidden = YES;
        } else if ([status caseInsensitiveCompare:@"offline"] == NSOrderedSame) {
            self.resourceStatus.textColor = [UIColor mit_closedRedColor];
        }
        self.resourceStatus.text = [status capitalizedString];

        self.resourceImageViewHeightConstraint.constant = MIN(CGRectGetHeight(self.bounds), CGRectGetWidth(self.bounds));

        if (imageURL) {
            MITMobiusResource *currentResource = self.resource;
            __weak MITMobiusDetailHeader *weakSelf = self;
            [self.resourceImageView sd_setImageWithURL:imageURL completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
                [self setNeedsUpdateConstraints];
                
                MITMobiusDetailHeader *blockSelf = weakSelf;
                if (blockSelf && (blockSelf.resource == currentResource)) {
                    if (error) {
                        blockSelf.resourceImageView.image = nil;
                    } else {
                        self.resourceImageView.backgroundColor = [UIColor colorWithWhite:1.0 alpha:1.0];
                    }
                }
            }];
        } else {
            self.resourceImageView.image = nil;
        }
    } else {
        [self.resourceImageView sd_cancelCurrentImageLoad];
        self.resourceImageView.image = nil;
        self.resourceName.text = nil;
        self.resourceStatus.text = nil;
    }
    
    [self setNeedsUpdateConstraints];
    [self setNeedsLayout];
}

@end
