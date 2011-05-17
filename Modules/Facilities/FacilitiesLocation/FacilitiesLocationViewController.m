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
    self.category = nil;
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

- (NSArray*)resultsForSearchString:(NSString *)searchText {
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:[NSString stringWithFormat:@"\\b[\\S]*%@[\\S]*\\b",searchText]
                                                                           options:NSRegularExpressionCaseInsensitive
                                                                             error:NULL];
    NSPredicate *searchPredicate = [NSPredicate predicateWithFormat:@"name CONTAINS [c] %@",searchText];
    NSArray *results = [self.cachedData filteredArrayUsingPredicate:searchPredicate];
    
    results = [results sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        NSString *key1 = [obj1 valueForKey:@"name"];
        NSString *key2 = [obj2 valueForKey:@"name"];
        
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

- (void)configureMainTableCell:(UITableViewCell*)cell
                  forIndexPath:(NSIndexPath*)indexPath {
    if ([self.cachedData count] >= indexPath.row) {
        cell.textLabel.text = [[self.cachedData objectAtIndex:indexPath.row] valueForKey:@"name"];
    }
}


- (void)configureSearchCell:(HighlightTableViewCell*)cell
               forIndexPath:(NSIndexPath*)indexPath {
    cell.highlightLabel.searchString = self.searchString;
    
    if ([self.cachedData count] >= indexPath.row) {
        cell.highlightLabel.text = [[self.filteredData objectAtIndex:indexPath.row] valueForKey:@"name"];
    }
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
@end
