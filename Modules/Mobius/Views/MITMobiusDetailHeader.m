#import "MITMobiusDetailHeader.h"
#import "UIKit+MITAdditions.h"
#import <SDWebImage/UIImageView+WebCache.h>
#import "MITMobiusImage.h"

@interface MITMobiusDetailHeader ()
@property (weak, nonatomic) IBOutlet UILabel *resourceName;
@property (weak, nonatomic) IBOutlet UILabel *resourceStatus;
@property (weak, nonatomic) IBOutlet UIImageView *resourceImageView;

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

- (void)setResource:(MITMobiusResource *)resource
{
    _resource = resource;
    
    if (_resource) {
        __block NSString *name = nil;
        __block NSString *status = nil;
        __block NSURL *imageURL = nil;
        [_resource.managedObjectContext performBlockAndWait:^{
            name = resource.name;
            status = resource.status;
            
            CGSize idealImageSize = CGSizeZero;
            idealImageSize = self.resourceImageView.frame.size;
            MITMobiusImage *image = [self.resource.images firstObject];
            imageURL = [image URLForImageWithSize:MITMobiusImageSmall];
        }];
        
        self.resourceName.text = name;

        if ([status caseInsensitiveCompare:@"online"] == NSOrderedSame) {
            self.resourceStatus.textColor = [UIColor mit_openGreenColor];
        } else if ([status caseInsensitiveCompare:@"offline"] == NSOrderedSame) {
            self.resourceStatus.textColor = [UIColor mit_closedRedColor];
        }
        self.resourceStatus.text = status;

        if (imageURL) {
            MITMobiusResource *currentResource = self.resource;
            __weak MITMobiusDetailHeader *weakSelf = self;
            [self.resourceImageView sd_setImageWithURL:imageURL completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
                MITMobiusDetailHeader *blockSelf = weakSelf;
                if (blockSelf && (blockSelf.resource == currentResource)) {
                    if (error) {
                        blockSelf.resourceImageView.image = nil;
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
