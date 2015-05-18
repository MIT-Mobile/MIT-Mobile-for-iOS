#import <UIKit/UIKit.h>
#import "MITMobiusResource.h"

@interface MITMobiusDetailTableViewController : UITableViewController

@property (nonatomic, weak) MITMobiusResource *resource;
@property (nonatomic) NSInteger currentSegmentedSection;

- (instancetype)initWithResource:(MITMobiusResource *)resource;

@end
