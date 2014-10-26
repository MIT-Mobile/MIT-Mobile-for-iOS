#import <Foundation/Foundation.h>

@class MITDiningRetailVenue, MITDiningRetailVenueDataManager;

@protocol MITDiningRetailVenueDataManagerDelegate <NSObject>

- (void)dataManagerDidUpdateSectionTitles:(MITDiningRetailVenueDataManager *)dataManager;

@end

@interface MITDiningRetailVenueDataManager : NSObject

@property (nonatomic, strong) NSArray *retailVenues;
@property (nonatomic, weak) id<MITDiningRetailVenueDataManagerDelegate> delegate;

- (instancetype)initWithRetailVenues:(NSArray *)retailVenues;
- (void)updateSectionsAndVenueArrays;

- (NSInteger)numberOfSections;
- (NSInteger)numberOfRowsInSection:(NSInteger)section;
- (NSString *)titleForSection:(NSInteger)section;
- (NSString *)absoluteIndexStringForVenue:(MITDiningRetailVenue *)venue;
- (MITDiningRetailVenue *)venueForIndexPath:(NSIndexPath *)indexPath;

@end
