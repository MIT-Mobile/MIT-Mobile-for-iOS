//
//  FacilitiesCategoryViewController.m
//  MIT Mobile
//
//  Created by Blake Skinner on 5/12/11.
//  Copyright 2011 MIT. All rights reserved.
//

#import "FacilitiesCategoryViewController.h"
#import "FacilitiesLocationViewController.h"
#import "FacilitiesUserLocationViewController.h"
#import "FacilitiesRoomViewController.h"

#import "FacilitiesCategory.h"
#import "FacilitiesLocation.h"
#import "HighlightTableViewCell.h"
#import "HighlightLabel.h"


@implementation FacilitiesCategoryViewController

- (id)init
{
    self = [super init];
    if (self) {
        self.filterPredicate = [NSPredicate predicateWithFormat:@"locations.@count > 0"];
    }
    return self;
}

- (void)dealloc
{
    [super dealloc];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self.locationData addObserver:self
                         withBlock:^(NSString *notification, BOOL updated, id userData) {
                             if ([userData isEqualToString:FacilitiesCategoriesKey]) {
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
#pragma mark Private Methods
- (BOOL)shouldShowLocationSection {
    if ((self.cachedData == nil) || ([self.cachedData count] == 0)) {
        return NO;
    } else {
        return [CLLocationManager locationServicesEnabled];
    }
}


#pragma mark -
#pragma mark Public Methods
- (NSArray*)dataForMainTableView {
    NSPredicate *searchPred = [NSPredicate predicateWithValue:YES];
    NSArray *data = [self.locationData categoriesMatchingPredicate:searchPred];
    data = [data sortedArrayUsingComparator: ^(id obj1, id obj2) {
        FacilitiesCategory *c1 = (FacilitiesCategory*)obj1;
        FacilitiesCategory *c2 = (FacilitiesCategory*)obj2;
        
        return [c1.name compare:c2.name];
    }];
    
    return data;
}

- (NSArray*)resultsForSearchString:(NSString *)searchText {
    /*NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:[NSString stringWithFormat:@"\\b[\\S]*%@[\\S]*\\b",searchText]
                                                                           options:NSRegularExpressionCaseInsensitive
                                                                             error:NULL];*/
    NSPredicate *searchPredicate = [NSPredicate predicateWithFormat:@"name CONTAINS [c] %@",searchText];
    NSArray *results = [self.locationData locationsMatchingPredicate:searchPredicate];
    
    results = [results sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        NSString *key1 = [obj1 valueForKey:@"name"];
        NSString *key2 = [obj2 valueForKey:@"name"];
        /*
        NSRange matchRange1 = [regex rangeOfFirstMatchInString:key1
                                                       options:0
                                                         range:NSMakeRange(0, [key1 length])];
        NSRange matchRange2 = [regex rangeOfFirstMatchInString:key2
                                                       options:0
                                                         range:NSMakeRange(0, [key2 length])];*/
        NSRange matchRange1 = [key1 rangeOfString:searchText
                                          options:NSCaseInsensitiveSearch];
        NSRange matchRange2 = [key2 rangeOfString:searchText
                                          options:NSCaseInsensitiveSearch];
        
        if (matchRange1.location > matchRange2.location) {
            return NSOrderedDescending;
        } else if (matchRange1.location < matchRange2.location) {
            return NSOrderedAscending;
        }
        
        
        matchRange1 = [key1 rangeOfString:searchText
                                  options:NSCaseInsensitiveSearch];
        matchRange2 = [key2 rangeOfString:searchText
                                  options:NSCaseInsensitiveSearch];
        if (matchRange1.location > matchRange2.location) {
            return NSOrderedDescending;
        } else if (matchRange1.location < matchRange2.location) {
            return NSOrderedAscending;
        }
        
        return [key1 caseInsensitiveCompare:key2];
    }];
    
    return results;
}

- (void)configureMainTableCell:(UITableViewCell *)cell
                  forIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0) {
        cell.textLabel.text = @"Use my location";
    } else {
        FacilitiesCategory *cat = (FacilitiesCategory*)[self.cachedData objectAtIndex:indexPath.row];
        cell.textLabel.text = cat.name;
    }
}

- (void)configureSearchCell:(HighlightTableViewCell *)cell
                forIndexPath:(NSIndexPath *)indexPath
{
    FacilitiesLocation *loc = (FacilitiesLocation*)[self.filteredData objectAtIndex:indexPath.row];
    
    cell.highlightLabel.searchString = self.searchString;
    cell.highlightLabel.text = loc.name;
}


#pragma mark -
#pragma mark UITableViewDelegate Methods
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    UIViewController *nextViewController = nil;
    
    if (tableView == self.tableView) {
        if ((indexPath.section == 0) && [self shouldShowLocationSection]) {
            nextViewController = [[[FacilitiesUserLocationViewController alloc] init] autorelease];
        } else {
            FacilitiesCategory *category = (FacilitiesCategory*)[self.cachedData objectAtIndex:indexPath.row];
            FacilitiesLocationViewController *controller = [[[FacilitiesLocationViewController alloc] init] autorelease];
            controller.category = category;
            nextViewController = controller;
        }
    } else {
        FacilitiesLocation *location = (FacilitiesLocation*)[self.filteredData objectAtIndex:indexPath.row];
        FacilitiesRoomViewController *controller = [[[FacilitiesRoomViewController alloc] init] autorelease];
        controller.location = location;
        nextViewController = controller;
    }
    
    [self.navigationController pushViewController:nextViewController
                                         animated:YES];
    
    [tableView deselectRowAtIndexPath:indexPath
                             animated:YES];
}

#pragma mark -
#pragma mark UITableViewDataSource Methods
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if (tableView == self.tableView) {
        return ([self shouldShowLocationSection] ? 2 : 1);
    } else {
        return 1;
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (tableView == self.tableView) {
        return ((section == 0) && [self shouldShowLocationSection]) ? 1 : [self.cachedData count];
    } else {
        return [self.filteredData count];
    }
}
@end
