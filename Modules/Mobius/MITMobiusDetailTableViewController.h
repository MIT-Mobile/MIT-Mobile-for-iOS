#import <UIKit/UIKit.h>
#import "MITMobiusResource.h"

@interface MITMobiusDetailTableViewController : UITableViewController

@property (nonatomic, weak) MITMobiusResource *resource;

- (instancetype)initWithResource:(MITMobiusResource *)resource;

@end
