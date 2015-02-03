#import <UIKit/UIKit.h>
#import "MITMartyResource.h"

@interface MITMartyCalloutContentView : UIControl

@property (strong, nonatomic) MITMartyResource *resource;

- (void)configureForResource:(MITMartyResource *)resource;

typedef NS_ENUM(NSInteger, MITMartyResourceStatus) {
    MITMartyResourceStatusOnline,
    MITMartyResourceStatusOffline,
    MITMartyResourceStatusUnknown
};

- (void)setStatus:(MITMartyResourceStatus)status withText:(NSString*)statusText;

@end
