#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, MITMobiusResourceStatus) {
    MITMobiusResourceStatusOnline,
    MITMobiusResourceStatusOffline,
    MITMobiusResourceStatusUnknown
};

@interface MITMobiusResourceView : UIView
@property(nonatomic,weak) IBOutlet UILabel *machineNameLabel;
@property(nonatomic,weak) IBOutlet UILabel *locationLabel;
@property(nonatomic,weak) IBOutlet UILabel *statusLabel;

@property(nonatomic) NSUInteger index;
@property(nonatomic,copy) NSString *machineName;
@property(nonatomic,copy) NSString *location;

- (void)setStatus:(MITMobiusResourceStatus)status withText:(NSString*)statusText;
@end
