#import "MITActionSheetHandler.h"
#import "UIKit+MITAdditions.h"

@implementation MITActionSheetHandler

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if( self.delegateBlock )
    {
        self.delegateBlock(actionSheet, buttonIndex);
    }
}

@end
