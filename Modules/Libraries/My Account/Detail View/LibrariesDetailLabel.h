#import <UIKit/UIKit.h>
#import <CoreText/CoreText.h>

@interface LibrariesDetailLabel : UILabel
{
    CTFramesetterRef _framesetter;
}
@property (nonatomic) UIEdgeInsets textInsets;

- (id)initWithBook:(NSDictionary*)details;

@end
