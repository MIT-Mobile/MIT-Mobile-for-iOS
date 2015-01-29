#import <UIKit/UIKit.h>
#import <CoreText/CoreText.h>

extern const NSString* MITFontAttributeName;
extern const NSString* MITForegroundColorAttributeName;
extern const NSString* MITBackgroundColorAttributeName;
extern const NSString* MITStrokeColorAttributeName;

@interface HighlightLabel : UILabel
@property (nonatomic,retain) UIColor *matchedTextColor;
@property (nonatomic,copy) NSString* searchString;
@property (nonatomic) BOOL highlightAllMatches;

@end
