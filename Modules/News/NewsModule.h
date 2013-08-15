#import <Foundation/Foundation.h>
#import "MITModule.h"

@class StoryListViewController;

@interface NewsModule : MITModule
@property (nonatomic, readonly) StoryListViewController *storyListChannelController;
@end
