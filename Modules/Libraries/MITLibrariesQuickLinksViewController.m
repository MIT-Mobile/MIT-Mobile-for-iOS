#import "MITLibrariesQuickLinksViewController.h"
#import "MITLibrariesWebservices.h"
#import "MITLibrariesLink.h"
#import "UIKit+MITAdditions.h"

static NSString *const kMITLinksCell = @"kMITLinksCell";

@interface MITLibrariesQuickLinksViewController ()

@end

@implementation MITLibrariesQuickLinksViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = @"Quick Links";
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.links.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kMITLinksCell];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kMITLinksCell];
    }
    
    MITLibrariesLink *link = self.links[indexPath.row];
    cell.textLabel.text = link.title;
    cell.accessoryView = [UIImageView accessoryViewWithMITType:MITAccessoryViewExternal];

    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    
    MITLibrariesLink *link = self.links[indexPath.row];
    NSURL *linkURL = [NSURL URLWithString:link.url];
    
    if ([[UIApplication sharedApplication] canOpenURL:linkURL]) {
        [[UIApplication sharedApplication] openURL:linkURL];
    }
}

@end
