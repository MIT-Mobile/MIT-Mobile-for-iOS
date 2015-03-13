#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, MITMartyResourceStatus) {
    MITMartyResourceStatusOnline,
    MITMartyResourceStatusOffline,
    MITMartyResourceStatusUnknown
};

@interface MITMobiusResourceView : UIView
@property(nonatomic,weak) IBOutlet UILabel *machineNameLabel;
@property(nonatomic,weak) IBOutlet UILabel *locationLabel;
@property(nonatomic,weak) IBOutlet UILabel *statusLabel;

@property(nonatomic) NSUInteger index;
@property(nonatomic,copy) NSString *machineName;
@property(nonatomic,copy) NSString *location;

- (void)setStatus:(MITMartyResourceStatus)status withText:(NSString*)statusText;
@end
