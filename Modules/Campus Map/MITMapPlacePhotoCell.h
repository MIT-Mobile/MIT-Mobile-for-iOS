#import <UIKit/UIKit.h>

@class MITMapPlace;

@interface MITMapPlacePhotoCell : UITableViewCell

@property (nonatomic, weak) IBOutlet UIImageView *photoImageView;
@property (nonatomic, weak) IBOutlet UILabel *captionLabel;

- (void)setPlace:(MITMapPlace *)place;

@end
