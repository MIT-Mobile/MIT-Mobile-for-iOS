#import <QuartzCore/QuartzCore.h>
#import "LibrariesLoanTableViewCell.h"
#import "Foundation+MITAdditions.h"

@implementation LibrariesLoanTableViewCell
- (id)initWithReuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithReuseIdentifier:reuseIdentifier];
    
    if (self)
    {
        self.statusIcon.image = [UIImage imageNamed:@"libraries/status-alert"];
        self.statusIcon.hidden = YES;
    }
    
    return self;
}

- (void)setItemDetails:(NSDictionary *)itemDetails
{
    [super setItemDetails:itemDetails];
    
    NSMutableString *status = [NSMutableString string];
    if ([[itemDetails objectForKey:@"has-hold"] boolValue]) {
        [status appendString:@"Item has holds\n"];
    }
    
    if ([[itemDetails objectForKey:@"overdue"] boolValue]) {
        self.statusLabel.textColor = [UIColor redColor];
        self.statusIcon.hidden = NO;
    } else {
        self.statusLabel.textColor = [UIColor blackColor];
        self.statusIcon.hidden = YES;
    }
    
    NSString *dueText = [itemDetails objectForKey:@"dueText"];
    
    if (dueText) {
        [status appendString:dueText];
    }
    
    self.statusLabel.text = [[status stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] stringByDecodingXMLEntities];
}

@end
