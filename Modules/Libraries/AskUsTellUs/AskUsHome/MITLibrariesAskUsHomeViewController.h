#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, MITLibrariesAskUsOption) {
    MITLibrariesAskUsOptionAskUs,
    MITLibrariesAskUsOptionConsultation,
    MITLibrariesAskUsOptionTellUs,
    MITLibrariesAskUsOptionGeneral,
};

@class MITLibrariesAskUsHomeViewController;
@protocol MITLibrariesAskUsHomeViewControllerDelegate <NSObject>
- (void)librariesAskUsHomeViewController:(MITLibrariesAskUsHomeViewController *)askUsHomeViewController didSelectAskUsOption:(MITLibrariesAskUsOption)selectedOption;
@end

@interface MITLibrariesAskUsHomeViewController : UIViewController
@property (nonatomic, strong) NSArray *availableAskUsOptions; // [[MITLibrariesAskUsOption]]
@property (weak, nonatomic) id<MITLibrariesAskUsHomeViewControllerDelegate> delegate;
@end
