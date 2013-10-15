#import <Foundation/Foundation.h>

@interface MITMapCategory : NSObject <NSSecureCoding,NSCopying>
@property (copy) NSString *name;
@property (copy) NSString *identifier;
@property (copy) NSOrderedSet *subcategories;
@property (copy) MITMapCategory *parent;

- (id)initWithDictionary:(NSDictionary*)placeDictionary;
- (BOOL)hasSubcategories;

/** Returns an array of category names as strings.
 *  The zeroth index is the name of the first category in the
 *  tree and the last index is the receiver.
 */
- (NSArray*)pathComponents;
@end
