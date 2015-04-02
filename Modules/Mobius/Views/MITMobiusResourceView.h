#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, MITMobiusResourceStatus) {
    MITMobiusResourceStatusOnline,
    MITMobiusResourceStatusOffline,
    MITMobiusResourceStatusUnknown
};

@interface MITMobiusResourceView : UIView
@property(nonatomic,weak) IBOutlet UILabel *machineNameLabel;

@property(nonatomic) NSUInteger index;
@property(nonatomic,copy) NSString *machineName;

@end
