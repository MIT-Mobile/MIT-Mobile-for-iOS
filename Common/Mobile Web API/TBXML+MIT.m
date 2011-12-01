#import "TBXML.h"

@implementation TBXML (MitAdditions)
+ (TBXMLElement*) childElementWithId:(NSString*)aId
                       parentElement:(TBXMLElement*)aParentXMLElement
                     recursiveSearch:(BOOL)isRecursiveSearch 
{
    if (([aId length] == 0) || (aParentXMLElement == NULL)) {
        return NULL;
    }
    
	TBXMLElement * xmlElement = aParentXMLElement;
    while (xmlElement) {
        NSString *attribute = [TBXML valueOfAttributeNamed:@"id"
                                                forElement:xmlElement];

        if (attribute && [aId isEqualToString:attribute]) {
            return xmlElement;
        }
        
        if (isRecursiveSearch) {
            TBXMLElement *matchElement = [TBXML childElementWithId:aId
                                                     parentElement:xmlElement->firstChild
                                                   recursiveSearch:isRecursiveSearch];
            if (matchElement) {
                return matchElement;
            }
        }
        
        xmlElement = xmlElement->nextSibling;
    }
    
    return NULL;
}

+ (NSArray*) elementsWithPath:(NSArray*)aPath parentElement:(TBXMLElement*)aParentXMLElement {
    if (aParentXMLElement == NULL) {
        return [NSArray array];
    }
    
    NSMutableArray *elements = [NSMutableArray array];
    TBXMLElement *xmlElement = aParentXMLElement->firstChild;
    const char *path = [[aPath objectAtIndex:0] UTF8String];
    
    while(xmlElement) {
        if (strcmp(path, xmlElement->name) == 0) {
            if ([aPath count] == 1) {
                [elements addObject:[NSValue valueWithPointer:xmlElement]];
            } else {
                [elements addObjectsFromArray:[TBXML elementsWithPath:[aPath subarrayWithRange:NSMakeRange(1, [aPath count] - 1)]
                                                        parentElement:xmlElement]];
            }
        }
        
        xmlElement = xmlElement->nextSibling;
    }
    
    return (([elements count] > 0) ? elements : [NSArray array]);
}

@end