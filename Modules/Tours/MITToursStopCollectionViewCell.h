#import <UIKit/UIKit.h>

@interface MITToursStopCollectionViewCell : UICollectionViewCell

- (void)configureForImageURL:(NSURL *)imageURL title:(NSString *)title selected:(BOOL)selected;

+ (CGSize)sizeForSelected:(BOOL)selected;

@end
