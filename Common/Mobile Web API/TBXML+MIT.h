#import "TBXML.h"

@interface TBXML (MitAdditions)
+ (TBXMLElement*) childElementWithId:(NSString*)aId
                       parentElement:(TBXMLElement*)aParentXMLElement
                     recursiveSearch:(BOOL)isRecursiveSearch;

+ (NSArray*) elementsWithPath:(NSArray*)aPath parentElement:(TBXMLElement*)aParentXMLElement;
@end
