#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "MITManagedObject.h"
#import "MITMappedObject.h"

@class MITDiningMeal;

@interface MITDiningMenuItem : MITManagedObject <MITMappedObject>

@property (nonatomic, retain) id dietaryFlags;
@property (nonatomic, retain) NSString *itemDescription;
@property (nonatomic, retain) NSString *name;
@property (nonatomic, retain) NSString *station;
@property (nonatomic, retain) NSSet *meal;

+ (NSString *)pdfNameForDietaryFlag:(NSString *)flag;
+ (NSString *)displayNameForDietaryFlag:(NSString *)flag;
+ (NSArray *)allDietaryFlagsKeys;

- (NSAttributedString *)attributedNameWithDietaryFlagsAtSize:(CGSize)size verticalAdjustment:(CGFloat)verticalAdjustment;
+ (NSAttributedString *)dietaryFlagsDisplayStringForFlags:(NSArray *)dietaryFlags atSize:(CGSize)size verticalAdjustment:(CGFloat)verticalAdjustment;
+ (NSMutableAttributedString *)dietaryFlagsStringForFlags:(NSArray *)flags atSize:(CGSize)size verticalAdjustment:(CGFloat)verticalAdjustment;

@end

@interface MITDiningMenuItem (CoreDataGeneratedAccessors)

- (void)addMealObject:(MITDiningMeal *)value;
- (void)removeMealObject:(MITDiningMeal *)value;
- (void)addMeal:(NSSet *)values;
- (void)removeMeal:(NSSet *)values;

@end
