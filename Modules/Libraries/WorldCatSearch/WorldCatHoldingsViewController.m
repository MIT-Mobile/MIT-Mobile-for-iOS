#import "WorldCatHoldingsViewController.h"
#import "WorldCatBook.h"
#import "UIKit+MITAdditions.h"
#import "ExplanatorySectionLabel.h"
#import "BookDetailTableViewCell.h"

#define PADDING 10
#define CELL_LABEL_TAG 232

typedef enum {
    TitleSection = 0,
    LinkSection,
    OwnerSection
} HoldingsSectionsEnum;

@interface WorldCatHoldingsViewController ()

- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath;

@end

@implementation WorldCatHoldingsViewController

- (void)setBook:(WorldCatBook *)book {
    if (![_book isEqual:book]) {
        _book = book;
        
        NSPredicate *pred = [NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary *bindings) {
            NSString *code = [(WorldCatHolding *)evaluatedObject code];
            return ![code isEqual:MITLibrariesOCLCCode];
        }];
        
        NSArray *tempHoldings = [[self.book.holdings allValues] filteredArrayUsingPredicate:pred];
        self.holdings = [tempHoldings sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
            NSString *code1 = [(WorldCatHolding *)obj1 code];
            NSString *code2 = [(WorldCatHolding *)obj2 code];
            return [code1 compare:code2];
        }];
    }
}

#pragma mark - View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"BLC Holdings";
    self.tableView.backgroundView = nil;
    if (NSFoundationVersionNumber <= NSFoundationVersionNumber_iOS_6_1) {
        self.tableView.backgroundColor = [UIColor mit_backgroundColor];
    }
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

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 3;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    switch (section) {
        case TitleSection:
            return 1;
        case LinkSection:
            return 1;
        case OwnerSection:
            return [self.holdings count];
    }
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *TitleCellIdentifier = @"title";
    static NSString *DefaultCellIdentifier = @"default";
    
    UITableViewCell *cell = nil;
    
    switch (indexPath.section) {
        case TitleSection: {
            cell = [tableView dequeueReusableCellWithIdentifier:TitleCellIdentifier];
            if (cell == nil) {
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:TitleCellIdentifier];
            }
            break;
        }
        case LinkSection:
        case OwnerSection:
        default: {
            cell = [tableView dequeueReusableCellWithIdentifier:DefaultCellIdentifier];
            if (cell == nil) {
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:DefaultCellIdentifier];
                cell.textLabel.numberOfLines = 0;
                cell.textLabel.lineBreakMode = NSLineBreakByWordWrapping;
            }
            break;
        }
    }
    [self configureCell:(cell) atIndexPath:indexPath];
    
    return cell;
}

- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath {
    switch (indexPath.section) {
        case TitleSection: {
            cell.textLabel.text = self.book.title;
            cell.detailTextLabel.text = [self.book yearWithAuthors];
            cell.detailTextLabel.textColor = [UIColor darkGrayColor];
            cell.textLabel.numberOfLines = 0;
            cell.textLabel.lineBreakMode = NSLineBreakByWordWrapping;
            cell.detailTextLabel.numberOfLines = 0;
            cell.detailTextLabel.lineBreakMode = NSLineBreakByWordWrapping;
            break;
        }
        case LinkSection:
            cell.textLabel.text = @"WorldCat Website";
            cell.accessoryView = [UIImageView accessoryViewWithMITType:MITAccessoryViewExternal];
            cell.selectionStyle = UITableViewCellSelectionStyleBlue;
            break;
        case OwnerSection:
        default: {
            WorldCatHolding *holding = self.holdings[indexPath.row];
            cell.textLabel.text = holding.library;
            cell.accessoryView = nil;
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            break;
        }
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    switch (indexPath.section) {
        case TitleSection: {
            // There's probably a better way to do this —
            // one that doesn't require hardcoding expected padding.
            
            // UITableViewCellStyleSubtitle layout differs between iOS 6 and 7
            static UIEdgeInsets labelInsets;
            if (NSFoundationVersionNumber > NSFoundationVersionNumber_iOS_6_1) {
                labelInsets = UIEdgeInsetsMake(11., 15., 11., 15.);
            } else {
                labelInsets = UIEdgeInsetsMake(11., 10. + 10., 11., 10. + 39.);
            }
            
            NSString *title = self.book.title;
            NSString *detail = [self.book yearWithAuthors];
            
            CGFloat availableWidth = CGRectGetWidth(UIEdgeInsetsInsetRect(tableView.bounds, labelInsets));
            CGSize titleSize = [title sizeWithFont:[UIFont systemFontOfSize:[UIFont buttonFontSize]] constrainedToSize:CGSizeMake(availableWidth, 2000) lineBreakMode:NSLineBreakByWordWrapping];
            
            CGSize detailSize = [detail sizeWithFont:[UIFont systemFontOfSize:[UIFont smallSystemFontSize]] constrainedToSize:CGSizeMake(availableWidth, 2000) lineBreakMode:NSLineBreakByWordWrapping];
            
            return titleSize.height + detailSize.height + labelInsets.top + labelInsets.bottom;
        }
        case LinkSection:
            return self.tableView.rowHeight;
        case OwnerSection:
        default: {
            WorldCatHolding *holding = self.holdings[indexPath.row];
            NSString *labelText = holding.library;
            CGSize textSize = [labelText sizeWithFont:[UIFont boldSystemFontOfSize:[UIFont labelFontSize]] constrainedToSize:CGSizeMake(CGRectGetWidth(tableView.bounds) - (20.0 * 2.0), 2000.0)];
            return textSize.height + 2 * PADDING;
        }
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    switch (section) {
        case OwnerSection: {
            return @"Owned By";
        }
        default:
            return nil;
    }
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
{
    switch (section) {
        case TitleSection: {
            NSString *labelText = @"Items unavailable from MIT may be available from the Boston Library Consortium members listed below. Visit the WorldCat website to request an interlibrary loan.";
            ExplanatorySectionLabel *footerLabel = [[ExplanatorySectionLabel alloc] initWithType:ExplanatorySectionFooter];
            footerLabel.text = labelText;
            return footerLabel;
        }
        default:
            return nil;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    switch (section) {
        case TitleSection: {
            return [ExplanatorySectionLabel heightWithText:@"Items unavailable from MIT may be available from the Boston Library Consortium members listed below. Visit the WorldCat website to request an interlibrary loan."
                                              width:tableView.bounds.size.width
                                               type:ExplanatorySectionFooter];
        }
        default:
            return 0;
    }
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    switch (indexPath.section) {
        case LinkSection: {
            NSURL *url = [NSURL URLWithString:self.book.url];
            if (url && [[UIApplication sharedApplication] canOpenURL:url]) {
                [[UIApplication sharedApplication] openURL:url];
            }
            [tableView deselectRowAtIndexPath:indexPath animated:NO];
            break;
        }
    }
}

@end
