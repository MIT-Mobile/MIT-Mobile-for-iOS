#import <UIKit/UIKit.h>

@class MITMapCategory;
@protocol MITMapPlaceSelectionDelegate;

@interface MITMapCategoriesViewController : UITableViewController
@property (nonatomic,copy) NSOrderedSet *categories;
@property (nonatomic,weak) id<MITMapPlaceSelectionDelegate> placeSelectionDelegate;

- (id)init;
- (id)initWithSubcategoriesOfCategory:(MITMapCategory*)category;

- (void)setCategories:(NSOrderedSet *)categories animated:(BOOL)animated;
@end

@protocol MITMapPlaceSelectionDelegate <NSObject>
- (void)mapCategoriesPicker:(MITMapCategoriesViewController*)controller didSelectPlace:(id)place;
@end