#import <UIKit/UIKit.h>
#import <CoreText/CoreText.h>

@interface LibrariesDetailLabel : UILabel
{
    CTFramesetterRef _framesetter;
}

- (id)initWithBook:(NSDictionary*)details;

@end
