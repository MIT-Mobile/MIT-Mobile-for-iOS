#import <UIKit/UIKit.h>

@class MITMartyResource;

typedef NS_ENUM(NSInteger, MITMartyResourceStatus) {
    MITMartyResourceStatusOnline,
    MITMartyResourceStatusOffline,
    MITMartyResourceStatusUnknown
};

@interface MITMartyResourceTableViewCell : UITableViewCell
@property(nonatomic) NSUInteger index;
@property(nonatomic,copy) NSString *machineName;
@property(nonatomic,copy) NSString *location;

- (void)setStatus:(MITMartyResourceStatus)status withText:(NSString*)statusText;

@end
