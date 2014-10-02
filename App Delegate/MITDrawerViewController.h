#import <UIKit/UIKit.h>

@class MITModuleItem;
@protocol MITDrawerViewControllerDelegate;

@interface MITDrawerViewController : UIViewController
@property (nonatomic,weak) id<MITDrawerViewControllerDelegate> delegate;

@property (nonatomic,copy) NSArray *moduleItems;
@property (nonatomic,weak) MITModuleItem *selectedModuleItem;

- (void)setModuleItems:(NSArray *)moduleItems animated:(BOOL)animated;
- (void)setSelectedModuleItem:(MITModuleItem*)selectedModuleItem animated:(BOOL)animated;
@end

@protocol MITDrawerViewControllerDelegate <NSObject>
- (void)drawerViewController:(MITDrawerViewController*)drawerViewController didSelectModuleItem:(MITModuleItem*)moduleItem;
@end