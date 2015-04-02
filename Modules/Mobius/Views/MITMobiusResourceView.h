#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, MITMobiusResourceStatus) {
    MITMobiusResourceStatusOnline,
    MITMobiusResourceStatusOffline,
    MITMobiusResourceStatusUnknown
};

@interface MITMobiusResourceView : UIView

@property(nonatomic) NSUInteger index;
@property(nonatomic,copy) NSString *machineName;

- (void)setStatus:(MITMobiusResourceStatus)status withText:(NSString*)statusText;

@end
