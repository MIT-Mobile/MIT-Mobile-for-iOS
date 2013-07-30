#import <UIKit/UIKit.h>
#import <CoreText/CoreText.h>

@interface LibrariesDetailLabel : UILabel
@property UIEdgeInsets textInsets;

- (id)initWithBook:(NSDictionary*)details;

@end
