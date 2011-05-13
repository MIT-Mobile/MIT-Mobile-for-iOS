//
//  FacilitiesCategoryViewController.m
//  MIT Mobile
//
//  Created by Blake Skinner on 5/12/11.
//  Copyright 2011 MIT. All rights reserved.
//

#import "FacilitiesLocationViewController.h"
#import "FacilitiesCategory.h"
#import "FacilitiesLocation.h"
#import "FacilitiesRoomViewController.h"
#import "HighlightTableViewCell.h"


@implementation FacilitiesLocationViewController
@synthesize category = _category;

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
    
    // Release any cached data, images, etc that aren't in use.
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self.locationData addObserver:self
                         withBlock:^(NSString *notification, BOOL updated, id userData) {
                             if ([userData isEqualToString:FacilitiesLocationsKey]) {
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
    NSArray *data = nil;
    data = [self.locationData locationsMatchingPredicate:self.filterPredicate];
    data = [data sortedArrayUsingComparator: ^(id obj1, id obj2) {
        FacilitiesLocation *l1 = (FacilitiesLocation*)obj1;
        FacilitiesLocation *l2 = (FacilitiesLocation*)obj2;
        
        return [l1.name compare:l2.name];
    }];
    
    return data;
}

#pragma mark -
#pragma mark UITableViewDelegate Methods
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    FacilitiesLocation *location = nil;
    
    if (tableView == self.tableView) {
        location = (FacilitiesLocation*)[self.cachedData objectAtIndex:indexPath.row];
    } else {
        location = (FacilitiesLocation*)[self.filteredData objectAtIndex:indexPath.row];
    }
    
    FacilitiesRoomViewController *controller = [[[FacilitiesRoomViewController alloc] init] autorelease];
    controller.location = location;
    
    [self.navigationController pushViewController:controller
                                         animated:YES];
    
    [tableView deselectRowAtIndexPath:indexPath
                             animated:YES];
}

#pragma mark -
#pragma mark UITableViewDataSource Methods
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (tableView == self.tableView) {
        return [self.cachedData count];
    } else {
        return [self.filteredData count];
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *facilitiesIdentifier = @"facilitiesCell";
    static NSString *searchIdentifier = @"searchCell";
    UITableViewCell *cell = nil;
    
    if (tableView == self.tableView) {
        cell = [tableView dequeueReusableCellWithIdentifier:facilitiesIdentifier];
        
        if (cell == nil) {
            cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                           reuseIdentifier:facilitiesIdentifier] autorelease];
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        }

        FacilitiesLocation *location = [self.cachedData objectAtIndex:indexPath.row];
        cell.textLabel.text = location.name;
        
    } else if (tableView == self.searchDisplayController.searchResultsTableView) {
        HighlightTableViewCell *hlCell = (HighlightTableViewCell*)[tableView dequeueReusableCellWithIdentifier:searchIdentifier];
        
        if (hlCell == nil) {
             hlCell = [[[HighlightTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                                     reuseIdentifier:searchIdentifier] autorelease];
        }
        
        FacilitiesLocation *location = [self.filteredData objectAtIndex:indexPath.row];
        hlCell.highlightLabel.text = location.name;
        hlCell.highlightLabel.searchString = self.searchString;
        cell = hlCell;
    }
    
    return cell;
}

#pragma mark -
#pragma mark UISearchBarDelegate
- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    self.searchString = searchText;
    self.filteredData = [self.cachedData filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"name CONTAINS[c] %@",searchText]];
    
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:[NSString stringWithFormat:@"\\b[\\S]*%@[\\S]*\\b",searchText]
                                                                           options:NSRegularExpressionCaseInsensitive
                                                                             error:NULL];
    self.filteredData = [self.filteredData sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        NSString *key1 = [NSString stringWithString:[obj1 valueForKey:@"name"]];
        NSString *key2 = [NSString stringWithString:[obj2 valueForKey:@"name"]];
        
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
    
}
@end
