#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, MITNewsPresentationStyle) {
    MITNewsPadStyleGrid = 0,
    MITNewsPadStyleList
};

@interface MITNewsiPadViewController : UIViewController
@property (nonatomic) MITNewsPresentationStyle presentationStyle;

- (IBAction)searchButtonWasTriggered:(UIBarButtonItem*)sender;
- (IBAction)showStoriesAsGrid:(UIBarButtonItem*)sender;
- (IBAction)showStoriesAsList:(UIBarButtonItem*)sender;
@end
