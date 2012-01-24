#import "WorldCatHoldingsViewController.h"
#import "WorldCatBook.h"
#import "UIKit+MITAdditions.h"
#import "MITUIConstants.h"
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

@synthesize book = _book,
            holdings = _holdings;

- (id)initWithStyle:(UITableViewStyle)style {
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)dealloc {
    self.book = nil;
    self.holdings = nil;
    [super dealloc];
}

- (void)setBook:(WorldCatBook *)book {
    if (book != _book) {
        [_book release];
        _book = [book retain];
        
        NSPredicate *pred = [NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary *bindings) {
            NSString *code = [(WorldCatHolding *)evaluatedObject code];
            return ![code isEqualToString:MITLibrariesOCLCCode];
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
    self.tableView.backgroundColor = [UIColor clearColor];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 3;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    switch (section) {
        case TitleSection:
            return 2;
        case LinkSection:
            return 1;
        case OwnerSection:
            return self.holdings.count;
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
                cell = [[[BookDetailTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:TitleCellIdentifier] autorelease];
            }
            break;
        }
        case LinkSection:
        case OwnerSection:
        default: {
            cell = [tableView dequeueReusableCellWithIdentifier:DefaultCellIdentifier];
            if (cell == nil) {
                cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:DefaultCellIdentifier] autorelease];
                cell.textLabel.numberOfLines = 0;
                cell.textLabel.lineBreakMode = UILineBreakModeWordWrap;
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
            NSAttributedString *displayString = nil;
            switch (indexPath.row) {
                case 0:
                    displayString = [BookDetailTableViewCell 
                                     displayStringWithTitle:self.book.title
                                     subtitle:nil
                                     separator:nil
                                     fontSize:BookDetailFontSizeTitle];
                    break;
                case 1:
                    displayString = [BookDetailTableViewCell 
                                     displayStringWithTitle:nil
                                     subtitle:[self.book yearWithAuthors]
                                     separator:nil
                                     fontSize:BookDetailFontSizeDefault];
                    break;
                default:
                    break;
            }
            ((BookDetailTableViewCell *)cell).displayString = displayString;
            cell.backgroundColor = [UIColor greenColor];
            break;
        }
        case LinkSection:
            cell.textLabel.text = @"WorldCat Website";
            cell.accessoryView = [UIImageView accessoryViewWithMITType:MITAccessoryViewExternal];
            cell.selectionStyle = UITableViewCellSelectionStyleBlue;
            break;
        case OwnerSection:
        default: {
            WorldCatHolding *holding = [self.holdings objectAtIndex:indexPath.row];
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
            NSAttributedString *displayString = nil;
            switch (indexPath.row) {
                case 0:
                    displayString = [BookDetailTableViewCell 
                                     displayStringWithTitle:self.book.title
                                     subtitle:nil
                                     separator:nil
                                     fontSize:BookDetailFontSizeTitle];
                    break;
                case 1:
                    displayString = [BookDetailTableViewCell 
                                     displayStringWithTitle:nil
                                     subtitle:[self.book yearWithAuthors]
                                     separator:nil
                                     fontSize:BookDetailFontSizeDefault];
                    break;
                default:
                    break;
            }
            CGSize size = [BookDetailTableViewCell sizeForDisplayString:displayString tableView:tableView];
            return size.height + 8.0;
        }
        case LinkSection:
            return self.tableView.rowHeight;
        case OwnerSection:
        default: {
            WorldCatHolding *holding = [self.holdings objectAtIndex:indexPath.row];
            NSString *labelText = holding.library;
            CGSize textSize = [labelText sizeWithFont:[UIFont boldSystemFontOfSize:[UIFont labelFontSize]] constrainedToSize:CGSizeMake(CGRectGetWidth(tableView.bounds) - (20.0 * 2.0), 2000.0)];
            return textSize.height + 2 * PADDING;
        }
    }
}

- (UIView *)tableView: (UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    switch (section) {
        case LinkSection: {
            NSString *labelText = @"Items unavailable from MIT may be available from the Boston Library Consortium members listed below. Visit the WorldCat website to request an interlibrary loan.";
            ExplanatorySectionLabel *footerLabel = 
            [[[ExplanatorySectionLabel alloc] initWithType:ExplanatorySectionHeader] autorelease];
            footerLabel.text = labelText;
            return footerLabel;
        }
        case OwnerSection: {
            NSString *headerTitle = @"Owned By";
            return [UITableView groupedSectionHeaderWithTitle:headerTitle];
        }
    }
    return nil;
}

- (CGFloat)tableView: (UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    switch (section) {
        case LinkSection: {
            NSString *labelText = @"Items unavailable from MIT may be available from the Boston Library Consortium members listed below. Visit the WorldCat website to request an interlibrary loan.";
            CGFloat height = [ExplanatorySectionLabel heightWithText:labelText 
                                                               width:CGRectGetWidth(tableView.bounds)
                                                                type:ExplanatorySectionHeader];
            return height;
        }
        case OwnerSection:
            return GROUPED_SECTION_HEADER_HEIGHT;
    }
    return 0;
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
