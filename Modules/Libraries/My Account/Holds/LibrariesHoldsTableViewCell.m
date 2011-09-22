#import <QuartzCore/QuartzCore.h>
#import "LibrariesHoldsTableViewCell.h"
#import "Foundation+MITAdditions.h"

@implementation LibrariesHoldsTableViewCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.statusIcon.image = [UIImage imageNamed:@"libraries/status-ready"];
    }
    
    return self;
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context
{
    if ([keyPath isEqualToString:@"itemDetails"]) {
        NSDictionary *item = self.itemDetails;
        if (item) {
            NSMutableString *status = [NSMutableString stringWithString:[item objectForKey:@"status"]];
            if ([[item objectForKey:@"ready"] boolValue]) {
                self.statusIcon.hidden = NO;
                self.statusLabel.textColor = [UIColor colorWithRed:0
                                                             green:0.5
                                                              blue:0
                                                             alpha:1.0];
                [status appendFormat:@"\nPick up at %@", [item objectForKey:@"pickup-location"]];
            } else {
                self.statusIcon.hidden = YES;
                self.statusLabel.textColor = [UIColor blackColor];
            }
            
            self.statusLabel.text = [[status stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] stringByDecodingXMLEntities];
        }
    }
    
    [super observeValueForKeyPath:keyPath
                         ofObject:object
                           change:change
                          context:context];
}

@end
