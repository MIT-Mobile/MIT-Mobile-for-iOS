#import <UIKit/UIKit.h>
#import <CoreText/CoreText.h>

@interface LibrariesDetailTableViewCell : UITableViewCell
{
    CTFramesetterRef _framesetter;
}

@property (nonatomic,retain) NSDictionary *bookDetails;

- (id)initWithReuseIdentifier:(NSString*)reuseIdentifier;
@end
