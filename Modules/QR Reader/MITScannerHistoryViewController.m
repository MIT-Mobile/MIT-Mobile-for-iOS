//
//  MITScannerHistoryViewController.m
//  MIT Mobile
//

#import "MITScannerHistoryViewController.h"
#import "QRReaderHistoryData.h"
#import "QRReaderDetailViewController.h"
#import "QRReaderResult.h"
#import "CoreDataManager.h"

#import "UIImage+Resize.h"
#import "UIKit+MITAdditions.h"
#import "NSDateFormatter+RelativeString.h"

@interface MITScannerHistoryViewController ()<UITableViewDelegate, UITableViewDataSource, NSFetchedResultsControllerDelegate>

@property (strong) NSFetchedResultsController *fetchController;
@property (strong) NSManagedObjectContext *fetchContext;

@property (strong) QRReaderHistoryData *scannerHistory;

@property (nonatomic, weak) UITableView *tableView;
@property (nonatomic, weak) UIToolbar *multiEditToolbar;
@property (nonatomic, weak) UIBarButtonItem *deleteButton;

@property (strong) NSOperationQueue *renderingQueue;

@end

@implementation MITScannerHistoryViewController

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nil bundle:nil];
    if (self)
    {
        self.renderingQueue = [[NSOperationQueue alloc] init];
        self.renderingQueue.maxConcurrentOperationCount = 1;
        
        NSManagedObjectContext *fetchContext = [[NSManagedObjectContext alloc] init];
        fetchContext.persistentStoreCoordinator = [[CoreDataManager coreDataManager] persistentStoreCoordinator];
        fetchContext.undoManager = nil;
        fetchContext.stalenessInterval = 0;
        
        self.scannerHistory = [[QRReaderHistoryData alloc] initWithManagedContext:fetchContext];
        self.fetchContext = fetchContext;
        
        NSSortDescriptor *dateDescriptor = [[NSSortDescriptor alloc] initWithKey:@"date"
                                                                       ascending:NO];
        
        NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"QRReaderResult"];
        fetchRequest.sortDescriptors = @[dateDescriptor];
        
        self.fetchController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                                                   managedObjectContext:fetchContext
                                                                     sectionNameKeyPath:nil
                                                                              cacheName:nil];
        self.fetchController.delegate = self;
    }
    
    return self;
}

- (void)dealloc
{
    [self.renderingQueue cancelAllOperations];
}

- (void)loadView
{
    UIView *controllerView = [[UIView alloc] initWithFrame:[[UIScreen mainScreen] applicationFrame]];
    controllerView.backgroundColor = [UIColor whiteColor];
    controllerView.autoresizesSubviews = YES;
    controllerView.autoresizingMask = (UIViewAutoresizingFlexibleHeight |
                                       UIViewAutoresizingFlexibleWidth);
    self.view = controllerView;
    
    if ([self.view respondsToSelector:@selector(setTintColor:)]) {
        self.view.tintColor = [UIColor whiteColor];
    }
    
    CGRect tableViewFrame = self.view.bounds;
    tableViewFrame.origin.y = 64.;
    tableViewFrame.size.height -= 64.;
    UITableView *historyView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
    historyView.delegate = self;
    historyView.dataSource = self;
    historyView.rowHeight = [QRReaderResult defaultThumbnailSize].height;
    
    [self.view addSubview:historyView];
    self.tableView = historyView;
    
    self.tableView.allowsMultipleSelectionDuringEditing = YES;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.

    self.navigationItem.rightBarButtonItem = self.editButtonItem;
    self.tableView.tintColor = [UIColor mit_tintColor];
}

- (void)viewWillAppear:(BOOL)animated
{
    [self.fetchController performFetch:nil];
    
    // revert navigation bar back to be visible
    [self.navigationController.navigationBar setBackgroundImage:nil forBarMetrics:UIBarMetricsDefault];
    [self.navigationController.navigationBar setShadowImage:nil];
    [self.navigationController.navigationBar setTranslucent:NO];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [self.renderingQueue cancelAllOperations];
    
    NSError *saveError = nil;
    [self.fetchContext save:&saveError];
    if (saveError)
    {
        DDLogError(@"Error saving scan: %@", [saveError localizedDescription]);
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - UITableViewDataSource
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *reusableCellId = @"HistoryCell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:reusableCellId];
    
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle
                                      reuseIdentifier:reusableCellId];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        cell.selectionStyle = UITableViewCellSelectionStyleGray;
        cell.textLabel.font = [UIFont fontWithName:cell.textLabel.font.fontName size:16.0];
        
        UIView *selectedClearView = [[UIView alloc] initWithFrame:cell.frame];
        selectedClearView.backgroundColor = [UIColor clearColor];
        cell.multipleSelectionBackgroundView = selectedClearView;
    }
    
    [self configureCell:cell atIndexPath:indexPath];
    
    return cell;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [[self.fetchController sections] count];
}

- (NSInteger)tableView:(UITableView *)tableView
 numberOfRowsInSection:(NSInteger)section
{
    NSArray *sections = [self.fetchController sections];
    id<NSFetchedResultsSectionInfo> sectionInfo = sections[section];
    
    return [sectionInfo numberOfObjects];
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    QRReaderResult *result = [self.fetchController objectAtIndexPath:indexPath];
    
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        [self.scannerHistory deleteScanResult:result];
    }
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated
{
    [super setEditing:editing animated:animated];
    
    if( editing )
    {
        [self.tableView setEditing:YES animated:YES];
        [self setMultiEditToolbarHidden:NO];
    }
    else
    {
        [self.tableView setEditing:NO animated:YES];
        [self setMultiEditToolbarHidden:YES];
    }
}

- (void)configureCell:(UITableViewCell*)cell atIndexPath:(NSIndexPath*)indexPath
{
    QRReaderResult *result = [self.fetchController objectAtIndexPath:indexPath];
    
    cell.textLabel.text = result.text;
    cell.textLabel.numberOfLines = 2;
    cell.textLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    cell.detailTextLabel.text = [NSDateFormatter relativeDateStringFromDate:result.date
                                                                     toDate:[NSDate date]];
    
    if (result.thumbnail == nil)
    {
        CGRect imageFrame = cell.imageView.frame;
        imageFrame.size = [QRReaderResult defaultThumbnailSize];
        
        cell.imageView.frame = imageFrame;
        cell.imageView.contentMode = UIViewContentModeScaleToFill;
        cell.imageView.image = [UIImage imageNamed:MITImageNewsImagePlaceholder];
        cell.imageView.autoresizingMask = (UIViewAutoresizingFlexibleHeight |
                                           UIViewAutoresizingFlexibleWidth);
        
        UIImage *scanImage = result.scanImage;
        NSManagedObjectID *scanId = [result objectID];
        if (scanImage)
        {
            [self.renderingQueue addOperationWithBlock:^{
                UIImage *thumbnail = [scanImage resizedImage:[QRReaderResult defaultThumbnailSize]
                                        interpolationQuality:kCGInterpolationDefault];
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    QRReaderResult *scan = (QRReaderResult*)([self.fetchContext objectWithID:scanId]);
                    
                    if (scan.isDeleted == NO)
                    {
                        scan.thumbnail = thumbnail;
                        [self.fetchContext save:nil];
                    }
                });
            }];
        }
    }
    else
    {
        CGRect frame = cell.imageView.frame;
        frame.size = result.thumbnail.size;
        cell.imageView.frame = frame;
        cell.imageView.image = result.thumbnail;
        cell.imageView.contentMode = UIViewContentModeScaleAspectFill;
    }
}

#pragma mark - UITableViewDelegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if( self.tableView.editing )
    {
        [self updateDeleteButtonTitle];
        
        return;
    }
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    QRReaderResult *result = [self.fetchController objectAtIndexPath:indexPath];
    QRReaderDetailViewController *detailView = [QRReaderDetailViewController detailViewControllerForResult:result];
    [self.navigationController pushViewController:detailView animated:YES];
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if( self.tableView.editing )
    {
        [self updateDeleteButtonTitle];
    }
}

#pragma mark - NSFetchedResultsControllerDelegate
- (void)controller:(NSFetchedResultsController *)controller
   didChangeObject:(id)anObject
       atIndexPath:(NSIndexPath *)indexPath
     forChangeType:(NSFetchedResultsChangeType)type
      newIndexPath:(NSIndexPath *)newIndexPath
{
    UITableView *tableView = self.tableView;
    
    switch (type)
    {
        case NSFetchedResultsChangeInsert:
            [tableView insertRowsAtIndexPaths:@[newIndexPath]
                             withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeDelete:
            [tableView deleteRowsAtIndexPaths:@[indexPath]
                             withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeUpdate:
            [tableView reloadRowsAtIndexPaths:@[newIndexPath]
                             withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        default:
            break;
    }
}

#pragma mark - multi edit logic

- (UIToolbar *)multiEditToolbar
{
    if ( _multiEditToolbar == nil )
    {
        UIToolbar *toolbar = [[UIToolbar alloc] initWithFrame:CGRectZero];
        toolbar.barStyle = UIBarStyleDefault;
        toolbar.hidden = YES;
        toolbar.tintColor = [UIColor mit_tintColor];
        
        UIBarButtonItem *deleteItem = [[UIBarButtonItem alloc] initWithTitle:@"Delete" style:UIBarButtonItemStylePlain target:self action:@selector(didTapDelete:)];
        UIBarButtonItem *flexiableItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
        
        toolbar.items = @[flexiableItem, deleteItem, flexiableItem];
        
        [toolbar sizeToFit];
        
        CGRect toolbarFrame = toolbar.frame;
        toolbarFrame.origin.y = self.view.frame.size.height - toolbarFrame.size.height;
        toolbar.frame = toolbarFrame;
        
        [self.view addSubview:toolbar];
        _multiEditToolbar = toolbar;
        _deleteButton = deleteItem;
    }
    
    return _multiEditToolbar;
}

- (void)setMultiEditToolbarHidden:(BOOL)isHidden
{
    [self.multiEditToolbar setHidden:isHidden];
    
    // update tableView content size based on added toolbar at the bottom
    CGFloat updatedContentHeight = isHidden ? (self.tableView.contentSize.height - self.multiEditToolbar.frame.size.height) : (self.tableView.contentSize.height + self.multiEditToolbar.frame.size.height);
    self.tableView.contentSize = CGSizeMake(self.tableView.contentSize.width, updatedContentHeight);
    
    // reset to 'delete all' every time bar gets unhidden
    if( isHidden == NO ) {
        [self updateDeleteButtonTitle];
    }
}

- (void)updateDeleteButtonTitle
{
    NSArray *selectedRows = [self.tableView indexPathsForSelectedRows];
    
    self.deleteButton.title = [selectedRows count] > 0 ? @"Delete" : @"Delete All";
}

- (void)didTapDelete:(id)sender
{
    
}

@end
