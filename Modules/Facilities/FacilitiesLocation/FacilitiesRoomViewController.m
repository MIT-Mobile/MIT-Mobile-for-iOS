//
//  FacilitiesCategoryViewController.m
//  MIT Mobile
//
//  Created by Blake Skinner on 5/12/11.
//  Copyright 2011 MIT. All rights reserved.
//

#import "FacilitiesRoomViewController.h"
#import "FacilitiesSummaryViewController.h"
#import "FacilitiesCategory.h"
#import "FacilitiesLocation.h"
#import "FacilitiesRoom.h"
#import "HighlightTableViewCell.h"
#import "FacilitiesTypeViewController.h"
#import "FacilitiesConstants.h"


@implementation FacilitiesRoomViewController
@synthesize location = _location;

- (id)init
{
    self = [super init];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)dealloc
{
    [super dealloc];
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self.locationData addObserver:self
                         withBlock:^(NSString *notification, BOOL updated, id userData) {
                             if ([userData isEqualToString:FacilitiesRoomsKey]) {
                                 [self.loadingView removeFromSuperview];
                                 self.loadingView = nil;
                                 self.tableView.hidden = NO;
                                 
                                 if ((self.cachedData == nil) || updated) {
                                     self.cachedData = nil;
                                     [self.tableView reloadData];
                                 }
                             }
                         }];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.locationData removeObserver:self];
}

#pragma mark -
#pragma mark Public Methods
- (NSArray*)dataForMainTableView {
    NSPredicate *searchPredicate = [NSPredicate predicateWithFormat:@"building.number == %@",self.location.number];
    NSArray *data = [self.locationData roomsMatchingPredicate:searchPredicate];
    data = [data sortedArrayUsingComparator: ^(id obj1, id obj2) {
        FacilitiesRoom *r1 = (FacilitiesRoom*)obj1;
        FacilitiesRoom *r2 = (FacilitiesRoom*)obj2;
        NSString *s1 = [NSString stringWithFormat:@"%@-%@",r1.floor,r1.number];
        NSString *s2 = [NSString stringWithFormat:@"%@-%@",r2.floor,r2.number];
        
        return [s1 caseInsensitiveCompare:s2];
    }];
    
    return data;
}

- (NSArray*)resultsForSearchString:(NSString *)searchText {
    NSArray *results = [self.cachedData filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary *bindings) {
        NSRange range = [[evaluatedObject description] rangeOfString:searchText
                                                             options:NSCaseInsensitiveSearch];
        return (range.location != NSNotFound);
    }]];
    
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:[NSString stringWithFormat:@"\\b[\\S]*%@[\\S]*\\b",searchText]
                                                                           options:NSRegularExpressionCaseInsensitive
                                                                             error:NULL];
    results = [results sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        NSString *key1 = [(FacilitiesRoom*)obj1 displayString];
        NSString *key2 = [(FacilitiesRoom*)obj2 displayString];
        
        NSRange matchRange1 = [regex rangeOfFirstMatchInString:key1
                                                       options:0
                                                         range:NSMakeRange(0, [key1 length])];
        NSRange matchRange2 = [regex rangeOfFirstMatchInString:key2
                                                       options:0
                                                         range:NSMakeRange(0, [key2 length])];
        
        if (matchRange1.location > matchRange2.location) {
            return NSOrderedDescending;
        } else if (matchRange1.location < matchRange2.location) {
            return NSOrderedAscending;
        } else {
            return [key1 caseInsensitiveCompare:key2];
        }
    }];
    
    return results;
}

- (void)configureMainTableCell:(UITableViewCell *)cell
                  forIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0) {
        cell.textLabel.text = @"Outside";
    } else {
        if ([self.cachedData count] == 0) {
            cell.textLabel.text = @"Inside";
        } else {
            FacilitiesRoom *room = [self.cachedData objectAtIndex:indexPath.row];
            cell.textLabel.text = [room displayString];
        }
    }
}

- (void)configureSearchCell:(HighlightTableViewCell *)cell
               forIndexPath:(NSIndexPath *)indexPath
{
    FacilitiesRoom *room = [self.filteredData objectAtIndex:indexPath.row];
    if (room) {
        cell.highlightLabel.text = [room displayString];
        cell.highlightLabel.searchString = self.searchString;
    }
}

#pragma mark -
#pragma mark UITableViewDelegate Methods
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    FacilitiesRoom *room = nil;
    NSString *altName = nil;
    
    if (tableView == self.tableView) {
        if (indexPath.section == 0) {
            altName = @"Outside";
        } else if ([self.cachedData count] == 0) {
            altName = @"Inside";
        } else {
            room = [self.cachedData objectAtIndex:indexPath.row];
        }
    } else if (tableView == self.searchDisplayController.searchResultsTableView) {
        room = [self.filteredData objectAtIndex:indexPath.row];
    }
    
    FacilitiesTypeViewController *vc = [[[FacilitiesTypeViewController alloc] init] autorelease];
    
    if (room) {
        [dict setObject: room
                 forKey: FacilitiesRequestLocationRoomKey];
    } else {
        [dict setObject: altName
                 forKey: FacilitiesRequestLocationCustomKey];
    }
    
    [dict setObject: self.location
             forKey: FacilitiesRequestLocationBuildingKey];
    
    vc.userData = dict;
    
    [self.navigationController pushViewController:vc
                                         animated:YES];
    
    [tableView deselectRowAtIndexPath:indexPath
                             animated:YES];
}

#pragma mark -
#pragma mark UITableViewDataSource Methods
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (tableView == self.tableView) {
        if ((self.cachedData == nil) || ([self.cachedData count] == 0)) {
            return 1;
        } else {
            return (section == 0) ? 1 : [self.cachedData count];
        } 
    } else {
        return [self.filteredData count];
    }
}
@end
