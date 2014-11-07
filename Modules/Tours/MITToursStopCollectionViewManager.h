#import <UIKit/UIKit.h>
#import "MITToursStop.h"

@protocol MITToursCollectionViewManagerDelegate;

@interface MITToursStopCollectionViewManager : NSObject <UICollectionViewDelegate, UICollectionViewDataSource>

@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
@property (strong, nonatomic) NSArray *stops;
@property (strong, nonatomic) NSArray *stopsInDisplayOrder;
@property (strong, nonatomic) MITToursStop *selectedStop;

@property (weak, nonatomic) id<MITToursCollectionViewManagerDelegate> delegate;

- (void)setup;

// Protected
- (MITToursStop *)stopForIndexPath:(NSIndexPath *)path;

@end

@protocol MITToursCollectionViewManagerDelegate <NSObject>

@optional
- (void)collectionView:(UICollectionView *)collectionView didSelectItemForStop:(MITToursStop *)stop;

@end
