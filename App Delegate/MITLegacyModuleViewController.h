#import "MITModuleViewController.h"

@class MITModule;

@interface MITLegacyModuleViewController : MITModuleViewController
@property(nonatomic,readonly,strong) MITModule *module;

- (instancetype)initWithModule:(MITModule*)module;
@end
