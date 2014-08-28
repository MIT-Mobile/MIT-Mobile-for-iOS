#import <Foundation/Foundation.h>

@class MITDiningRetailVenue;

@interface MITDiningRetailVenueDataManager : NSObject

@property (nonatomic, strong) NSArray *retailVenues;

- (instancetype)initWithRetailVenues:(NSArray *)retailVenues;
- (void)updateSectionsAndVenueArrays;

- (NSInteger)numberOfSections;
- (NSInteger) numberOfRowsInSection:(NSInteger)section;
- (NSString *)titleForSection:(NSInteger)section;
- (NSString *)absoluteIndexStringForVenue:(MITDiningRetailVenue *)venue;
- (MITDiningRetailVenue *)venueForIndexPath:(NSIndexPath *)indexPath;

@end
