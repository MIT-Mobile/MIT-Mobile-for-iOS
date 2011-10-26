#import <QuartzCore/QuartzCore.h>
#import "LibrariesLoanTableViewCell.h"
#import "Foundation+MITAdditions.h"

@implementation LibrariesLoanTableViewCell

- (void)setItemDetails:(NSDictionary *)itemDetails
{
    [super setItemDetails:itemDetails];
    
    NSMutableString *status = [NSMutableString string];
    if ([[itemDetails objectForKey:@"has-hold"] boolValue]) {
        [status appendString:@"Item has holds\n"];
    }
    
    if ([[itemDetails objectForKey:@"overdue"] boolValue]) {
        self.statusLabel.textColor = [UIColor redColor];
    } else {
        self.statusLabel.textColor = [UIColor blackColor];
    }
    
    NSString *dueText = [itemDetails objectForKey:@"dueText"];
    
    if (dueText) {
        [status appendString:dueText];
    }
    
    self.statusLabel.text = [[status stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] stringByDecodingXMLEntities];
}

@end
