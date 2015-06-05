#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, MITMobiusResourceStatus) {
    MITMobiusResourceStatusOnline,
    MITMobiusResourceStatusOffline,
    MITMobiusResourceStatusUnknown
};

@interface MITMobiusResourceView : UIView

@property(nonatomic) NSUInteger index;
@property(nonatomic,copy) NSString *machineName;
@property(nonatomic,copy) NSString *model;

- (void)setStatus:(MITMobiusResourceStatus)status;

@end
