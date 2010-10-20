#import <Foundation/Foundation.h>
#import "MITModule.h"

@class StoryListViewController;

@interface NewsModule : MITModule {
	StoryListViewController *storyListChannelController;
}

@property (nonatomic, retain) StoryListViewController *storyListChannelController;

@end
