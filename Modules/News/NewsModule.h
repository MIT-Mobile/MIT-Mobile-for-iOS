#import <Foundation/Foundation.h>
#import "MITModule.h"

@class StoryListViewController;
@class MITNewsViewController;

@interface NewsModule : MITModule
@property (nonatomic, readonly) StoryListViewController *storyListChannelController;

- (instancetype)init;
- (BOOL)supportsUserInterfaceIdiom:(UIUserInterfaceIdiom)idiom;
- (UIViewController*)createHomeViewControllerForPadIdiom;
- (UIViewController*)createHomeViewControllerForPhoneIdiom;
@end
