
#import <UIKit/UIKit.h>

@class MITMapPlace;

@interface MITMapDetailViewController : UIViewController
@property (nonatomic,strong) NSManagedObjectContext *managedObjectContext;

@property (nonatomic, strong) MITMapPlace* place;
@property (nonatomic, copy) NSString* queryText;
@property int startingTab;

- (instancetype)initWithPlace:(MITMapPlace*)mapPlace;

// user tapped on the map thumbnail
-(IBAction) mapThumbnailPressed:(id)sender;

// user tapped the bookmark/favorite button
-(IBAction) bookmarkButtonTapped;

@end
