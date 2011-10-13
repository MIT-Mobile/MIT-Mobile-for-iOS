#import "MITTabViewItem.h"

@implementation MITTabViewItem
@synthesize header = _header;

+ (id)tabBarItemWithTitle:(NSString*)title image:(UIImage*)image tag:(NSUInteger)tag
{
    return [[[self alloc] initWithTitle:title
                                  image:image
                                    tag:tag] autorelease];
}

+ (id)tabBarItemWithTitle:(NSString*)title image:(UIImage*)image tag:(NSUInteger)tag header:(UIView*)header
{
    return [[[self alloc] initWithTitle:title
                                  image:image
                                    tag:tag
                                 header:header] autorelease];
}

- (id)initWithTitle:(NSString*)title image:(UIImage*)image tag:(NSUInteger)tag header:(UIView*)header
{
    self = [super initWithTitle:title
                          image:image
                            tag:tag];
    
    if (self) {
        self.header = header;
    }
    
    return self;
}
@end
