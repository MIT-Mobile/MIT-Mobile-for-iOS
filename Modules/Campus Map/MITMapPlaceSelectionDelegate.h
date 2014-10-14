#import <Foundation/Foundation.h>

@class MITMapPlace;
@class MITMapCategory;
@protocol MITMapPlaceSelector;

@protocol MITMapPlaceSelectionDelegate <NSObject>

@optional
- (void)placeSelectionViewController:(UIViewController <MITMapPlaceSelector>*)viewController didSelectPlace:(MITMapPlace *)place;
- (void)placeSelectionViewController:(UIViewController<MITMapPlaceSelector> *)viewController didSelectCategory:(MITMapCategory *)category;
- (void)placeSelectionViewController:(UIViewController <MITMapPlaceSelector>*)viewController didSelectQuery:(NSString *)query;

@end
