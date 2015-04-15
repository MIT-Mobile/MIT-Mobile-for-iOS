#import "MITMobiusRecentSearchQuery.h"
#import "MITMobiusRecentSearchList.h"
#import "MITMobiusModel.h"
#import "MITAdditions.h"

@implementation MITMobiusRecentSearchQuery

@dynamic date;
@dynamic text;
@dynamic search;
@dynamic options;

- (NSString*)URLParameterString {
    NSMutableDictionary *parameters = [[NSMutableDictionary alloc] init];

    parameters[@"or"] = @"true";

    NSMutableArray *whereClause = [[NSMutableArray alloc] init];

    if (self.text) {
        NSArray *fields = @[@"dlc",@"status",@"attributes_values.value"];
        [fields enumerateObjectsUsingBlock:^(NSString *fieldName, NSUInteger idx, BOOL *stop) {
            NSDictionary *likeClause = @{@"field" : fieldName,
                                            @"operator" : @"like",
                                            @"value" : self.text};
            [whereClause addObject:likeClause];
        }];
    }

    [self.options enumerateObjectsUsingBlock:^(MITMobiusSearchOption *searchOption, NSUInteger idx, BOOL *stop) {
        MITMobiusAttribute *attribute = searchOption.attribute;
        NSAssert(attribute, @"search option %@ is missing an associated attribute", searchOption);

        NSMutableDictionary *attributeClause = [[NSMutableDictionary alloc] init];
        attributeClause[@"field"] = @"attribute_values._attribute";
        attributeClause[@"value"] = attribute.identifier;

        /* [{"field":"attribute_values._attribute","value":"5475e4979147112657976a4d"},{"field":"attribute_values.value","operator":"in","value":["straight cuts","angled cuts"]}]}*/
        NSMutableDictionary *valueClause = [[NSMutableDictionary alloc] init];
        valueClause[@"field"] = @"attribute_values.value";

        switch (searchOption.attribute.type) {
            case MITMobiusAttributeTypeNumeric: {
                valueClause[@"operator"] = @"eq";
                valueClause[@"value"] = searchOption.value;
            } break;

            case MITMobiusAttributeTypeAutocompletion:
            case MITMobiusAttributeTypeText:
            case MITMobiusAttributeTypeString: {
                valueClause[@"operator"] = @"like";
                valueClause[@"value"] = searchOption.value;
            } break;

            case MITMobiusAttributeTypeOptionSingle:
            case MITMobiusAttributeTypeOptionMultiple: {
                valueClause[@"operator"] = @"in";
                valueClause[@"value"] = [[searchOption.values array] mapObjectsUsingBlock:^NSString*(MITMobiusAttributeValue *value, NSUInteger idx) {
                    return value.value;
                }];
            } break;

                
            default:
                break;
        }

        [whereClause addObjectsFromArray:@[attributeClause,valueClause]];
    }];

    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:whereClause options:0 error:nil];
    if (jsonData) {
        return [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    } else {
        return nil;
    }
}

@end
