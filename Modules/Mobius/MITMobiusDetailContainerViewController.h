#import <UIKit/UIKit.h>
#import "MITMobiusResource.h"

@protocol MITMobiusDetailPagingDelegate;

@interface MITMobiusDetailContainerViewController : UIViewController
@property (nonatomic,weak) id<MITMobiusDetailPagingDelegate> delegate;
@property (nonatomic,weak) MITMobiusResource *currentResource;
@property (nonatomic,copy) NSArray *resources;

- (instancetype)initWithResource:(MITMobiusResource *)resource;

@end

@protocol MITMobiusDetailPagingDelegate <NSObject>
@required
- (NSUInteger)numberOfResourcesInDetailViewController:(MITMobiusDetailContainerViewController*)viewController;
- (MITMobiusResource*)detailViewController:(MITMobiusDetailContainerViewController*)viewController resourceAtIndex:(NSUInteger)index;
- (NSUInteger)detailViewController:(MITMobiusDetailContainerViewController*)viewController indexForResourceWithIdentifier:(NSString*)resource;
- (NSUInteger)detailViewController:(MITMobiusDetailContainerViewController*)viewController indexAfterIndex:(NSUInteger)index;
- (NSUInteger)detailViewController:(MITMobiusDetailContainerViewController*)viewController indexBeforeIndex:(NSUInteger)index;
@end