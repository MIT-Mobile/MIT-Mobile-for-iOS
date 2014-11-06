#import <UIKit/UIKit.h>
#import "MITToursStop.h"

@interface MITToursStopCollectionViewManager : NSObject <UICollectionViewDelegate, UICollectionViewDataSource>

@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
@property (strong, nonatomic) NSArray *stops;

- (void)setup;

// Protected
- (MITToursStop *)stopForIndexPath:(NSIndexPath *)path;

@end
