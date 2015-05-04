#import <UIKit/UIKit.h>

@protocol MITMobiusSearchFilterStripDataSource;
@protocol MITMobiusSearchFilterStripDelegate;

@interface MITMobiusSearchFilterStrip : UIView

@property (nonatomic, weak) id<MITMobiusSearchFilterStripDataSource> dataSource;
@property (nonatomic, weak) id<MITMobiusSearchFilterStripDelegate> delegate;

- (void)reloadData;

@end

@protocol MITMobiusSearchFilterStripDataSource <NSObject>

- (NSInteger)numberOfFiltersForStrip:(MITMobiusSearchFilterStrip *)filterStrip;
- (NSString *)searchFilterStrip:(MITMobiusSearchFilterStrip *)filterStrip textForFilterAtIndex:(NSInteger)index;

@end

@protocol MITMobiusSearchFilterStripDelegate <NSObject>
@optional
- (void)searchFilterStrip:(MITMobiusSearchFilterStrip *)filterStrip didSelectFilterAtIndex:(NSInteger)index;

@end
