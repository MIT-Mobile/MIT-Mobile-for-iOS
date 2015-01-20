#import "MartyModule.h"

@implementation MartyModule
- (instancetype)init {
    self = [super initWithName:MITModuleTagMarty title:@"Marty"];
    if (self) {
        self.longTitle = @"Marty";
        self.imageName = MITImageMartyModuleIcon;
    }
    return self;
}

- (BOOL)supportsCurrentUserInterfaceIdiom
{
    return YES;
}

- (void)loadRootViewController
{
    
}
	
@end
