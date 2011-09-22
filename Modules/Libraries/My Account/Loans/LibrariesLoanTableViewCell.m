#import <QuartzCore/QuartzCore.h>
#import "LibrariesLoanTableViewCell.h"
#import "Foundation+MITAdditions.h"

@implementation LibrariesLoanTableViewCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.statusIcon.image = [UIImage imageNamed:@"libraries/status-alert"];
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
            NSMutableString *status = [NSMutableString string];
            if ([[item objectForKey:@"has-hold"] boolValue]) {
                [status appendString:@"Item has holds\n"];
            }
            
            if ([[item objectForKey:@"overdue"] boolValue]) {
                self.statusIcon.hidden = NO;
                self.statusLabel.textColor = [UIColor redColor];
            } else {
                self.statusIcon.hidden = YES;
                self.statusLabel.textColor = [UIColor blackColor];
            }
            
            NSString *dueText = [item objectForKey:@"dueText"];
            
            if (dueText) {
                [status appendString:dueText];
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
