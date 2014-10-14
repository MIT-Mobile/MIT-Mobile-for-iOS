#import <UIKit/UIKit.h>

@protocol MITTapGestureRecognizerDelegate;

@interface MITTapGestureRecognizer : UITapGestureRecognizer
@property (nonatomic, weak) id<MITTapGestureRecognizerDelegate> delegate;
@end

@protocol MITTapGestureRecognizerDelegate <NSObject>

- (void)highlightCell:(UITapGestureRecognizer *)gestureRecognizer;
- (void)unHighlightCell:(UITapGestureRecognizer *)gestureRecognizer;;
- (void)cellSelected:(UITapGestureRecognizer *)gestureRecognizer;;

@end