#import "LibrariesHoldsTableViewCell.h"
#import "Foundation+MITAdditions.h"
#import "UIKit+MITAdditions.h"

@implementation LibrariesHoldsTableViewCell
- (id)initWithReuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithReuseIdentifier:reuseIdentifier];
    
    if (self)
    {
        self.statusIcon.image = [UIImage imageNamed:MITImageLibrariesStatusReady];
        self.statusIcon.hidden = YES;
    }
    
    return self;
}

- (void)setItemDetails:(NSDictionary *)itemDetails
{
    [super setItemDetails:itemDetails];
    
    if (itemDetails) {
        NSMutableString *status = [NSMutableString string];
        [status appendString:itemDetails[@"status"]];
        if ([itemDetails[@"ready"] boolValue]) {
            self.statusLabel.textColor = [UIColor colorWithRed:0
                                                         green:0.5
                                                          blue:0
                                                         alpha:1.0];
            [status appendFormat:@"\nPick up at %@", itemDetails[@"pickup-location"]];
            self.statusIcon.hidden = NO;
        } else {
            self.statusLabel.textColor = [UIColor colorWithHexString:@"#404649"];
            self.statusIcon.hidden = YES;
        }
        
        self.statusLabel.text = [[status stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] stringByDecodingXMLEntities];
    }
}

@end
