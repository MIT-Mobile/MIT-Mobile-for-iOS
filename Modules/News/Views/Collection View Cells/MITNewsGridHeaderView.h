#import <UIKit/UIKit.h>

@interface MITNewsGridHeaderView : UICollectionReusableView
@property (nonatomic,weak) IBOutlet UIView *separatorView;
@property (nonatomic,weak) IBOutlet UILabel *headerLabel;
@property (nonatomic,weak) IBOutlet UIView *accessoryView;

@property(nonatomic,weak) UIView *highlightedBackgroundView;
@property(nonatomic,getter=isHighlighted) BOOL highlighted;
@end
