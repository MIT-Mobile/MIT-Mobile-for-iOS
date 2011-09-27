#import <UIKit/UIKit.h>
#import <CoreText/CoreText.h>

extern const NSString* MITFontAttributeName;
extern const NSString* MITForegroundColorAttributeName;
extern const NSString* MITBackgroundColorAttributeName;
extern const NSString* MITStrokeColorAttributeName;

@interface HighlightLabel : UILabel {
    NSString *_searchString;
    NSAttributedString *_attributedString;
    BOOL _highlightAllMatches;
}
@property (nonatomic,copy) NSString* searchString;
@property (nonatomic) BOOL highlightsAllMatches;

@end
