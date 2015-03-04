#import "AboutMITVC.h"
#import "UIKit+MITAdditions.h"
#import "MITUIConstants.h"

@implementation AboutMITVC

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.tableView applyStandardColors];

    self.tableView.backgroundView = nil;
    self.tableView.backgroundColor = [UIColor mit_backgroundColor];
    self.navigationItem.title = @"About MIT";
}

#pragma mark Table view methods

// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 1;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSDictionary *infoDictionary = [[NSBundle mainBundle] infoDictionary];
    NSString *aboutText = infoDictionary[@"MITAboutMITText"];
    UIFont *aboutFont = [UIFont systemFontOfSize:15.0];
    NSParagraphStyle *paragraphStyle = [NSParagraphStyle defaultParagraphStyle];
    CGSize aboutSize = [aboutText boundingRectWithSize:CGSizeMake(270, 2000) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName: aboutFont, NSParagraphStyleAttributeName: paragraphStyle} context:nil].size;
    return aboutSize.height;
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        cell.backgroundColor = [UIColor whiteColor];
        cell.textLabel.backgroundColor = [UIColor clearColor];
        cell.detailTextLabel.backgroundColor = [UIColor clearColor];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    
    NSDictionary *infoDictionary = [[NSBundle mainBundle] infoDictionary];
    cell.textLabel.text = infoDictionary[@"MITAboutMITText"];
    cell.textLabel.font = [UIFont systemFontOfSize:15.0];
    cell.textLabel.textColor = CELL_STANDARD_FONT_COLOR;
    cell.textLabel.lineBreakMode = NSLineBreakByWordWrapping;
    cell.textLabel.numberOfLines = 0;
	
    return cell;
}

@end

