#import <UIKit/UIKit.h>

@interface MITToursStopCollectionViewManager : NSObject

@property (strong, nonatomic) NSArray *stops;

- (void)registerCells;

@end
