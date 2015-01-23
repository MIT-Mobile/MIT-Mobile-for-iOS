#import "MITDiningRetailVenueDataManager.h"
#import "MITMapModelController.h"
#import "MITDiningRetailVenue.h"
#import "MITDiningLocation.h"

static NSString *const kMITFavoriteVenueKey = @"Favorites";

@interface MITDiningBuilding : NSObject

@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSString *sortableName;

@end

@interface MITDiningRetailVenueDataManager ()

@property (nonatomic, strong) NSArray *fullSectionTitles;
// Getting the full section titles is asynchronous, so we'll keep the short names too.
@property (nonatomic, strong) NSArray *sectionTitles;
@property (nonatomic, strong) NSDictionary *venueArraysKeyedByBuildingName;

@end

@implementation MITDiningRetailVenueDataManager

@synthesize sectionTitles = _sectionTitles;

- (instancetype)initWithRetailVenues:(NSArray *)retailVenues
{
    self = [super init];
    if (self) {
        self.retailVenues = retailVenues;
    }
    return self;
}

- (void)updateSectionsAndVenueArrays
{
    NSMutableDictionary *venueArrays = [[NSMutableDictionary alloc] init];
    NSMutableArray *buildings = [[NSMutableArray alloc] init];
    NSMutableArray *sectionTitles = [[NSMutableArray alloc] init];
    
    for (MITDiningRetailVenue *venue in self.retailVenues)
    {
        if ([venue.favorite boolValue] == YES) {
            if (venueArrays[kMITFavoriteVenueKey]) {
                [venueArrays[kMITFavoriteVenueKey] addObject:venue];
            }
            else {
                NSMutableArray *favoritesArray = [[NSMutableArray alloc] initWithObjects:venue, nil];
                venueArrays[kMITFavoriteVenueKey] = favoritesArray;
            }
        }
        
        MITDiningBuilding *building = [self buildingForVenue:venue];
        if (venueArrays[building.name]) {
            [venueArrays[building.name] addObject:venue];
        }
        else {
            NSMutableArray *venuesInBuilding = [[NSMutableArray alloc] init];
            [venuesInBuilding addObject:venue];
            venueArrays[building.name] = venuesInBuilding;
            
            [buildings addObject:building];
        }
    }
    self.venueArraysKeyedByBuildingName = venueArrays;
    
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"sortableName" ascending:YES];
    [buildings sortUsingDescriptors:@[sortDescriptor]];
    
    if (venueArrays[kMITFavoriteVenueKey]){
        [sectionTitles addObject:kMITFavoriteVenueKey];
    }
    
    for (MITDiningBuilding *building in buildings)
    {
        [sectionTitles addObject:building.name];
    }
    self.sectionTitles = sectionTitles;
    if (self.sectionTitles.count != self.fullSectionTitles.count) {
        self.fullSectionTitles = nil;
    }
    [self generateFullSectionTitles];

    
    [self rebuildMasterVenuesArray];
}

- (void)generateFullSectionTitles
{
    [[MITMapModelController sharedController] buildingNamesForBuildingNumbers:self.sectionTitles completion:^(NSArray *buildingNames, NSError *error) {
        if (!error){
            self.fullSectionTitles = buildingNames;
            [self.delegate dataManagerDidUpdateSectionTitles:self];
        }
    }];
}

// This re-sorts the master list of venues, so that we can easily pull down the
// absolute row number, regardless of indexPath
- (void)rebuildMasterVenuesArray
{
    NSMutableArray *sortedVenues = [[NSMutableArray alloc] init];
    for (NSString *key in self.sectionTitles) {
        if (![key isEqualToString:kMITFavoriteVenueKey]) {
            [sortedVenues addObjectsFromArray:self.venueArraysKeyedByBuildingName[key]];
        }
    }
    _retailVenues = sortedVenues;
}

- (NSString *)absoluteIndexStringForVenue:(MITDiningRetailVenue *)venue
{
    NSInteger absoluteIndex = [self.retailVenues indexOfObject:venue];
    return absoluteIndex != NSNotFound ? [NSString stringWithFormat:@"%ld", (long)absoluteIndex + 1] : @"";
}

#pragma mark - Building Name Parsing, used for sorting buildings into sections

- (MITDiningBuilding *)buildingForVenue:(MITDiningRetailVenue *)venue
{
    MITDiningBuilding *building = [[MITDiningBuilding alloc] init];
    if (venue.location.mitRoomNumber) {
        NSString *roomNumber = venue.location.mitRoomNumber;
        NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"(N|NW|NE|W|WW|E)?(\\d+)" options:NSRegularExpressionCaseInsensitive error:nil];
        NSTextCheckingResult *result = [regex firstMatchInString:roomNumber options:0 range:NSMakeRange(0, [roomNumber length])];
        if (result) {
            building.name = [roomNumber substringWithRange:result.range];
            
            // Due to the way NSFetchRequest works, we can only sort by a simple string comparator.
            // In order to get building numbers to sort in natural order, we pad them with spaces and store that into sortableBuilding.
            // e.g. "7", "NE49", "W4", "W20" turn into
            //      "0    7"
            //      "NE   49"
            //      "W    4"
            //      "W   20"
            
            NSRange letterRange = [result rangeAtIndex:1];
            NSString *letters;
            if (letterRange.location != NSNotFound) {
                letters = [roomNumber substringWithRange:letterRange];
            } else {
                letters = @"0";
            }
            
            NSRange numberRange = [result rangeAtIndex:2];
            NSString *numbers;
            if (numberRange.location == NSNotFound) {
                numbers = @"0";
            } else {
                numbers = [roomNumber substringWithRange:numberRange];
            }
            
            building.sortableName = [NSString stringWithFormat:@"%s%5s", [letters UTF8String], [numbers UTF8String]];
        }
    }
    if (!building.name) {
        building.name = @"Other";
        building.sortableName = [NSString stringWithFormat:@"%5s%5s", [@"ZZZZZ" UTF8String], [@"99999" UTF8String]];
    }
    return building;
}

#pragma mark - Setters

- (void)setRetailVenues:(NSArray *)retailVenues
{
    _retailVenues = retailVenues;
    [self updateSectionsAndVenueArrays];
}

#pragma mark - "DataSource" Methods

- (NSInteger)numberOfSections
{
    return self.sectionTitles.count;
}

- (NSInteger)numberOfRowsInSection:(NSInteger)section
{
    NSString *sectionName = self.sectionTitles[section];
    
    NSArray *sectionArray = self.venueArraysKeyedByBuildingName[sectionName];
    
    return sectionArray.count;
}

- (NSString *)titleForSection:(NSInteger)section
{
    if (self.fullSectionTitles) {
        return self.fullSectionTitles[section];
    } else {
        return self.sectionTitles[section];
    }
}

- (MITDiningRetailVenue *)venueForIndexPath:(NSIndexPath *)indexPath
{
    NSString *buildingNameKey = self.sectionTitles[indexPath.section];
    
    return self.venueArraysKeyedByBuildingName[buildingNameKey][indexPath.row];
}

@end

@implementation MITDiningBuilding

@end
