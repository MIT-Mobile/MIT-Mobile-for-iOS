#import "LibrariesBookDetailViewController.h"
#import "MITTouchstoneRequestOperation+MITMobileV2.h"
#import "MITUIConstants.h"
#import "LibrariesModule.h"
#import "Foundation+MITAdditions.h"
#import "BookDetailTableViewCell.h"
#import "WorldCatHoldingsViewController.h"
#import "LibrariesHoldingsDetailViewController.h"

typedef enum {
    kInfoSection = 0,
    kEmailAndCiteSection = 1,
    kMITHoldingSection = 2,
    kBLCHoldingSection = 3
} BookDetailSections;

typedef enum {
    BookLoadingStatusPartial,
    BookLoadingStatusFailed,
    BookLoadingStatusCompleted
} BookLoadingStatus;

@interface LibrariesBookDetailViewController ()
@property BookLoadingStatus loadingStatus;

- (void)loadBookDetails;
- (void)configureCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath;
@end

@implementation LibrariesBookDetailViewController
- (id)init
{
    self = [super initWithStyle:UITableViewStyleGrouped];
    if (self) {
        // Custom initialization
        self.title = @"Book Detail";
    }
    return self;
}

#pragma mark - View lifecycle
// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.tableView.backgroundView = nil;
    if (NSFoundationVersionNumber <= NSFoundationVersionNumber_iOS_6_1) {
        self.tableView.backgroundColor = [UIColor mit_backgroundColor];
    }
    
    MITLoadingActivityView *activityView = [[MITLoadingActivityView alloc] initWithFrame:self.view.bounds];
    activityView.autoresizingMask = (UIViewAutoresizingFlexibleHeight |
                                     UIViewAutoresizingFlexibleWidth);
    [self.view addSubview:activityView];
    self.activityView = activityView;
    
    [self loadBookDetails];
}


- (void)viewDidUnload {
    [super viewDidUnload];
}

// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return MITCanAutorotateForOrientation(interfaceOrientation, [self supportedInterfaceOrientations]);
}

- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation
{
    return UIInterfaceOrientationPortrait;
}

- (void)loadBookDetails {
    self.loadingStatus = BookLoadingStatusPartial;

    NSURLRequest *request = [NSURLRequest requestForModule:LibrariesTag command:@"detail" parameters:@{@"id":self.book.identifier}];
    MITTouchstoneRequestOperation *requestOperation = [[MITTouchstoneRequestOperation alloc] initWithRequest:request];

    __weak LibrariesBookDetailViewController *weakSelf = self;
    requestOperation.completeBlock = ^(MITTouchstoneRequestOperation *operation, NSDictionary *content, NSString *contentType, NSError *error) {
        LibrariesBookDetailViewController *blockSelf = weakSelf;

        [blockSelf.activityView removeFromSuperview];

        if (!blockSelf) {
            return;
        } else if (error) {
            [UIAlertView alertViewForError:error withTitle:@"WorldCat Book Details" alertViewDelegate:nil];
            self.loadingStatus = BookLoadingStatusFailed;
            return;
        } else if (![content isKindOfClass:[NSDictionary class]]) {
            return;
        } else {
            [self.book updateDetailsWithDictionary:content];
            
            NSMutableArray *bookAttribs = [NSMutableArray array];
            
            // title
            // year; authors
            [bookAttribs addObject:@{@"label": self.book.title,
                                     @"subtitle":[self.book yearWithAuthors]}];
            
            // format
            if (self.book.formats.count) {
                [bookAttribs addObject:@{@"label": @"Format",
                                         @"subtitle":[self.book.formats componentsJoinedByString:@","]}];
            }

            // summary
            if (self.book.summarys.count) {
                [bookAttribs addObject:@{@"label": @"Summary",
                                         @"subtitle":[self.book.summarys componentsJoinedByString:@"; "]}];
            }

            // publisher
            NSArray *addressesWithPublishers = [self.book addressesWithPublishers];
            if ([addressesWithPublishers count] > 0) {
                [bookAttribs addObject:@{@"label": @"Publisher",
                                         @"subtitle":[addressesWithPublishers componentsJoinedByString:@"; "]}];
            }

            // edition
            if (self.book.editions.count) {
                [bookAttribs addObject:@{@"label": @"Edition",
                                         @"subtitle":[self.book.editions componentsJoinedByString:@", "]}];
            }

            // description
            if (self.book.extents.count) {
                [bookAttribs addObject:@{@"label": @"Description",
                                         @"subtitle":[self.book.extents componentsJoinedByString:@", "]}];
            }

            // isbn
            if (self.book.isbns.count) {
                [bookAttribs addObject:@{@"label": @"ISBN",
                                         @"subtitle":[self.book.isbns componentsJoinedByString:@"\n"]}];
            }
            
            self.bookInfo = [NSArray arrayWithArray:bookAttribs];

            self.loadingStatus = BookLoadingStatusCompleted;
            [self.tableView reloadData];
        }
    };
    
    LibrariesModule *librariesModule = (LibrariesModule *)[[MIT_MobileAppDelegate applicationDelegate] moduleWithTag:LibrariesTag];
    librariesModule.requestQueue.maxConcurrentOperationCount = NSOperationQueueDefaultMaxConcurrentOperationCount;
    [librariesModule.requestQueue addOperation:requestOperation];
}

#pragma mark - UITableView Data Source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    NSInteger sections = 2; // one for book info, one for email & cite
    
    if (self.loadingStatus == BookLoadingStatusCompleted) {
        NSInteger numHoldings = self.book.holdings.count;
        if (self.book.holdings[MITLibrariesOCLCCode]) {
            sections++; // one section for MIT holdings
            numHoldings--;
        }
        
        if (numHoldings > 0) {
            sections++; // one section for all other holdings
        }
    }
    
    return sections;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (self.loadingStatus == BookLoadingStatusCompleted) {
        NSInteger rows = 0;
        switch (section) {
            case kInfoSection:
                rows = self.bookInfo.count;
                if (NSFoundationVersionNumber > NSFoundationVersionNumber_iOS_6_1) {
                    rows += 1;
                }

                break;
            case kEmailAndCiteSection:
                rows = 1;
                break;
            case kMITHoldingSection: {
                WorldCatHolding *mitHoldings = self.book.holdings[MITLibrariesOCLCCode];
                rows = [[mitHoldings libraryAvailability] count] + 1;
                break;
            }
            default: // one of the holdings sections
                rows = 1;
                break;
        }
        return rows;
    }
    
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *titleIdentifier = @"title";
    static NSString *infoIdentifier = @"info";
    static NSString *availabilityIdentifier = @"availability";
    static NSString *defaultIdentifier = @"default";
    
    UITableViewCell *cell = nil; 
    
    switch (indexPath.section) {
        case kInfoSection: {
            if (indexPath.row == 0) {
                cell = [tableView dequeueReusableCellWithIdentifier:titleIdentifier];
                if (!cell) {
                    cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle
                                                  reuseIdentifier:titleIdentifier];
                    cell.detailTextLabel.textColor = [UIColor darkGrayColor];
                }
            } else {
                cell = [tableView dequeueReusableCellWithIdentifier:infoIdentifier];
                if (!cell) {
                    cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue2
                                                  reuseIdentifier:infoIdentifier];
                    cell.textLabel.textColor = [UIColor darkGrayColor];
                    if (NSFoundationVersionNumber <= NSFoundationVersionNumber_iOS_6_1) {
                        cell.textLabel.font = [UIFont systemFontOfSize:[UIFont smallSystemFontSize]];
                        cell.detailTextLabel.font = [UIFont systemFontOfSize:[UIFont smallSystemFontSize]];
                    }
                }
            }
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            cell.textLabel.numberOfLines = 0;
            cell.detailTextLabel.numberOfLines = 0;
            cell.textLabel.lineBreakMode = NSLineBreakByWordWrapping;
            cell.detailTextLabel.lineBreakMode = NSLineBreakByWordWrapping;
            if ([cell respondsToSelector:@selector(setSeparatorInset:)]) {
                cell.separatorInset = UIEdgeInsetsMake(0, 0, 0, 10000.);
            }

            if (indexPath.row >= [self.bookInfo count]) {
                cell.textLabel.text = nil;
                cell.detailTextLabel.text = nil;
            } else {
                cell.textLabel.text = self.bookInfo[indexPath.row][@"label"];
                cell.detailTextLabel.text = self.bookInfo[indexPath.row][@"subtitle"];
            }
            break;
        }
            
        case kMITHoldingSection: {
            NSString *reuseIdentifier = (indexPath.row == 0) ? defaultIdentifier : availabilityIdentifier;
            
            cell = [tableView dequeueReusableCellWithIdentifier:reuseIdentifier];
            
            if (!cell) {
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle
                                              reuseIdentifier:reuseIdentifier];
            }
            
            [self configureCell:cell forRowAtIndexPath:indexPath];
            break;
        }
            
        default: {
            cell = [tableView dequeueReusableCellWithIdentifier:defaultIdentifier];
            if (!cell) {
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                              reuseIdentifier:defaultIdentifier];
            }
            [self configureCell:cell forRowAtIndexPath:indexPath];
            break;
        }
    }
    
    return cell;
}

- (void)configureCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    switch (indexPath.section) {
        case kEmailAndCiteSection:
            cell.accessoryView = [UIImageView accessoryViewWithMITType:MITAccessoryViewEmail];
            cell.textLabel.text = @"Email & Cite Item";
            break;
        case kMITHoldingSection: {
            cell.accessoryType = UITableViewCellAccessoryNone;
            cell.accessoryView = nil;
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            switch (indexPath.row) {
                case 0:
                    cell.accessoryView = [UIImageView accessoryViewWithMITType:MITAccessoryViewExternal];
                    cell.selectionStyle = UITableViewCellSelectionStyleBlue;
                    cell.textLabel.text = @"Request Item";
                    break;
                default: {
                    WorldCatHolding *mitHoldings = self.book.holdings[MITLibrariesOCLCCode];
                    NSDictionary *libraryAvailability = [mitHoldings libraryAvailability];
                    NSArray *libraries = [[libraryAvailability allKeys] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
                    
                    NSString *location = libraries[indexPath.row - 1];
                    NSUInteger available = [mitHoldings inLibraryCountForLocation:location];
                    NSUInteger total = [libraryAvailability[location] count];
                    
                    cell.textLabel.text = location;
                    cell.textLabel.numberOfLines = 0;
                    cell.textLabel.lineBreakMode = NSLineBreakByWordWrapping;
                    
                    cell.detailTextLabel.text = [NSString stringWithFormat:@"%lu of %lu available", (unsigned long)available, (unsigned long)total];
                    cell.detailTextLabel.numberOfLines = 1;
                    cell.detailTextLabel.lineBreakMode = NSLineBreakByTruncatingTail;
                    
                    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                    cell.selectionStyle = UITableViewCellSelectionStyleBlue;
                    break;
                }
            }
            break;
        }
        case kBLCHoldingSection:
            cell.accessoryView = nil;
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            cell.selectionStyle = UITableViewCellSelectionStyleBlue;
            cell.textLabel.text = @"View Holdings";
            break;
        default:
            break;
    }
}

#pragma mark - UITableView Delegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    CGFloat height = tableView.rowHeight;
    switch (indexPath.section) {
        case kInfoSection: {
            if (indexPath.row == 0) {
                // There's probably a better way to do this —
                // one that doesn't require hardcoding expected padding.
                
                // UITableViewCellStyleSubtitle layout differs between iOS 6 and 7
                static UIEdgeInsets labelInsets;
                if (NSFoundationVersionNumber > NSFoundationVersionNumber_iOS_6_1) {
                    labelInsets = UIEdgeInsetsMake(11., 15., 11., 15.);
                } else {
                    labelInsets = UIEdgeInsetsMake(11., 10. + 10., 11., 10. + 39.);
                }
                
                NSString *title = self.bookInfo[indexPath.row][@"label"];
                NSString *detail = self.bookInfo[indexPath.row][@"subtitle"];
                
                CGFloat availableWidth = CGRectGetWidth(UIEdgeInsetsInsetRect(tableView.bounds, labelInsets));
                CGSize titleSize = [title sizeWithFont:[UIFont systemFontOfSize:[UIFont buttonFontSize]] constrainedToSize:CGSizeMake(availableWidth, 2000) lineBreakMode:NSLineBreakByWordWrapping];
                
                CGSize detailSize = [detail sizeWithFont:[UIFont systemFontOfSize:[UIFont smallSystemFontSize]] constrainedToSize:CGSizeMake(availableWidth, 2000) lineBreakMode:NSLineBreakByWordWrapping];
                
                height = titleSize.height + detailSize.height + labelInsets.top + labelInsets.bottom;
            } else {
                if (indexPath.row >= [self.bookInfo count]) {
                    return 10.;
                }
                // There's probably a better way to do this —
                // one that doesn't require hardcoding expected padding.
                
                // UITableViewCellStyleSubtitle layout differs between iOS 6 and 7
                static UIEdgeInsets labelInsets;
                // insets for detailTextLabel of UITableViewCellStyleValue2
                if (NSFoundationVersionNumber > NSFoundationVersionNumber_iOS_6_1) {
                    labelInsets = UIEdgeInsetsMake(4., 90. + 15. + 7., 4., 15.);
                } else {
                    labelInsets = UIEdgeInsetsMake(11., 80. + 10. + 4., 11., 10. + 10.);
                }
                
                NSString *title = self.bookInfo[indexPath.row][@"label"];
                NSString *detail = self.bookInfo[indexPath.row][@"subtitle"];
                
                UIFont *font = [UIFont systemFontOfSize:[UIFont systemFontSize]];
                if (NSFoundationVersionNumber <= NSFoundationVersionNumber_iOS_6_1) {
                    font = [UIFont systemFontOfSize:[UIFont smallSystemFontSize]];
                }
                
                CGFloat availableWidth = CGRectGetWidth(UIEdgeInsetsInsetRect(tableView.bounds, labelInsets));
                CGSize titleSize = [title sizeWithFont:font constrainedToSize:CGSizeMake(90, 2000) lineBreakMode:NSLineBreakByWordWrapping];
                
                CGSize detailSize = [detail sizeWithFont:font constrainedToSize:CGSizeMake(availableWidth, 2000) lineBreakMode:NSLineBreakByWordWrapping];
                
                CGFloat tallestLabelHeight = MAX(titleSize.height, detailSize.height);
                height = tallestLabelHeight + labelInsets.top + labelInsets.bottom;
            }
            break;
        }
        case kMITHoldingSection: {
            if (indexPath.row >= 1) {
                WorldCatHolding *mitHoldings = self.book.holdings[MITLibrariesOCLCCode];
                NSDictionary *libraryAvailability = [mitHoldings libraryAvailability];
                NSArray *libraries = [[libraryAvailability allKeys] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
                
                NSString *location = libraries[indexPath.row - 1];
                NSUInteger available = [mitHoldings inLibraryCountForLocation:location];
                NSUInteger total = [libraryAvailability[location] count];
                
                NSString *detail = [NSString stringWithFormat:@"%lu of %lu available", (unsigned long)available, (unsigned long)total];
                
                CGSize titleSize = [location sizeWithFont:[UIFont boldSystemFontOfSize:CELL_STANDARD_FONT_SIZE]
                                     constrainedToSize:CGSizeMake(tableView.frame.size.width, 2000.0) 
                                         lineBreakMode:NSLineBreakByWordWrapping];
                
                CGSize detailSize = [detail sizeWithFont:[UIFont systemFontOfSize:CELL_DETAIL_FONT_SIZE]
                                       constrainedToSize:CGSizeMake(tableView.frame.size.width, 2000.0) 
                                           lineBreakMode:NSLineBreakByWordWrapping];
                
                height = titleSize.height + detailSize.height + 2.0 * 10.0;
            }
            break;
        }
        default:
            break;
    }
    return height;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    switch (indexPath.section) {
        case kEmailAndCiteSection:
            if ([MFMailComposeViewController canSendMail]) {
                NSString *subject = [NSString stringWithFormat:@"MIT Libraries Item Details for: %@", self.book.title];
                NSString *body = self.book.emailAndCiteMessage;
                
                MFMailComposeViewController *mailView = [[MFMailComposeViewController alloc] init];
                [mailView setMailComposeDelegate:self];
                [mailView setSubject:subject];
                [mailView setMessageBody:body isHTML:YES];
                [self presentViewController:mailView animated:YES completion:NULL];
            }
            break;
        case kMITHoldingSection:
        {
            WorldCatHolding *mitHoldings = self.book.holdings[MITLibrariesOCLCCode];
            
            if (indexPath.row == 0) {
                NSURL *url = [NSURL URLWithString:mitHoldings.url];
                
                if ([[UIApplication sharedApplication] canOpenURL:url]) {
                    [[UIApplication sharedApplication] openURL:url];
                }
                
                [tableView deselectRowAtIndexPath:indexPath animated:YES];
            } else {
                NSDictionary *libraryAvailability = [mitHoldings libraryAvailability];
                NSArray *locations = [[libraryAvailability allKeys] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
                
                NSString *location = locations[indexPath.row - 1];
                NSArray *holdings = libraryAvailability[location];
                
                LibrariesHoldingsDetailViewController *detailVC = [[LibrariesHoldingsDetailViewController alloc] initWithHoldings:holdings];
                detailVC.title = location;
                [self.navigationController pushViewController:detailVC
                                                     animated:YES];
                [tableView deselectRowAtIndexPath:indexPath
                                         animated:YES];
            }
            break;
        }
        case kBLCHoldingSection:
        {
            WorldCatHoldingsViewController *vc = [[WorldCatHoldingsViewController alloc] initWithStyle:UITableViewStyleGrouped];
            vc.book = self.book;
            [self.navigationController pushViewController:vc animated:YES];
            break;
        }
        default:
            break;
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    NSString *title = nil;
    switch (section) {
        case kMITHoldingSection:
            if (self.loadingStatus == BookLoadingStatusCompleted) {
                title = @"MIT Libraries";
            }
            break;
        case kBLCHoldingSection:
            if (self.loadingStatus == BookLoadingStatusCompleted) {
                title = @"Boston Library Consortium";
            }
            break;
        case kEmailAndCiteSection:
        case kInfoSection:
        default:
            break;
    }
	return title;
}

#pragma mark - MFMailComposeViewController Delegate

- (void)mailComposeController:(MFMailComposeViewController*)controller
          didFinishWithResult:(MFMailComposeResult)result
                        error:(NSError*)error {
	[self dismissViewControllerAnimated:YES completion:NULL];
}

@end
