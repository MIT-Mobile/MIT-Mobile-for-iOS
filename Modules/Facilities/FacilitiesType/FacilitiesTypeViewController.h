#import <UIKit/UIKit.h>


@interface FacilitiesTypeViewController : UIViewController <UITableViewDataSource, UITableViewDelegate> {
    NSDictionary *_userData;
    UITableView *_tableView;
}

@property (nonatomic,copy) NSDictionary *userData;
@property (nonatomic,retain) UITableView* tableView;

@end
