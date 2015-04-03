#import "MITMobiusDetailHeader.h"
#import "UIKit+MITAdditions.h"
#import <SDWebImage/UIImageView+WebCache.h>

@interface MITMobiusDetailHeader ()
@property (weak, nonatomic) IBOutlet UILabel *resourceName;
@property (weak, nonatomic) IBOutlet UILabel *resourceStatus;
@property (weak, nonatomic) IBOutlet UIImageView *resourceImage;

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
            idealImageSize = self.resourceImage.frame.size;
#warning setup image when data model is ready
            /*
            MITNewsImageRepresentation *representation = [story.coverImage bestRepresentationForSize:idealImageSize];
            if (representation) {
                imageURL = representation.url;
            }
            */
        }];
        
        self.resourceName.text = name;

        if ([status caseInsensitiveCompare:@"online"] == NSOrderedSame) {
            self.resourceStatus.textColor = [UIColor mit_openGreenColor];
        } else if ([status caseInsensitiveCompare:@"offline"] == NSOrderedSame) {
            self.resourceStatus.textColor = [UIColor mit_closedRedColor];
        }
        self.resourceStatus.text = status;
#warning setup image when data model is ready
/*
        if (imageURL) {
            MITNewsStory *currentStory = self.story;
            __weak MITNewsStoryCell *weakSelf = self;
            [self.storyImageView sd_setImageWithURL:imageURL completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
                MITNewsStoryCell *blockSelf = weakSelf;
                if (blockSelf && (blockSelf->_story == currentStory)) {
                    if (error) {
                        blockSelf.storyImageView.image = nil;
                    }
                }
            }];
        } else {
            self.storyImageView.image = nil;
        }
 */
    } else {
        [self.resourceImage sd_cancelCurrentImageLoad];
        self.resourceImage.image = nil;
        self.resourceName.text = nil;
        self.resourceStatus.text = nil;
    }
    
    [self setNeedsUpdateConstraints];
    [self setNeedsLayout];
}

- (IBAction)detailSegmentControlAction:(UISegmentedControl *)segmentedControl
{
    
}

@end
