#import <Foundation/Foundation.h>

@class MITLibrariesSearchController;
@class MITLibrariesItem;

@protocol MITLibrariesSearchControllerDelegate <NSObject>

- (void)librariesSearchController:(MITLibrariesSearchController *)librariesSearchController didSelectItem:(MITLibrariesItem *)item;

@end

@interface MITLibrariesSearchController : NSObject <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, weak) id<MITLibrariesSearchControllerDelegate> delegate;

- (void)search:(NSString *)searchString;

@end
