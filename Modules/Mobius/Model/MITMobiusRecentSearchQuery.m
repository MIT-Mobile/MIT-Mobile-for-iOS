#import "MITMobiusRecentSearchQuery.h"
#import "MITMobiusRecentSearchList.h"
#import "MITMobiusModel.h"
#import "MITAdditions.h"

@implementation MITMobiusRecentSearchQuery

@dynamic date;
@dynamic text;
@dynamic search;
@dynamic options;

- (NSDictionary*)URLParameters {
    NSMutableArray *andConditional = [[NSMutableArray alloc] init];
    [self.options enumerateObjectsUsingBlock:^(MITMobiusSearchOption *searchOption, NSUInteger idx, BOOL *stop) {
        MITMobiusAttribute *attribute = searchOption.attribute;
        NSAssert(attribute, @"search option %@ is missing an associated attribute", searchOption);

        NSMutableDictionary *attributeClause = [[NSMutableDictionary alloc] init];
        attributeClause[@"field"] = @"attribute_values._attribute";
        attributeClause[@"value"] = attribute.identifier;

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

        [andConditional addObject:valueClause];
    }];


    NSMutableDictionary *urlParameters = [[NSMutableDictionary alloc] init];

    NSDictionary *whereClause = nil;
    if (self.text) {
        NSMutableArray *orConditions = [[NSMutableArray alloc] init];
        [@[@"name",@"room",@"dlc",@"status",@"attribute_values.value"] enumerateObjectsUsingBlock:^(NSString *field, NSUInteger idx, BOOL *stop) {
            [orConditions addObject:@{@"field" : field,
                                      @"operator" : @"like",
                                      @"value" : self.text}];
        }];

        whereClause = @{@"1" : @{ @"type" : @"or",
                                  @"conditions" : orConditions },
                        @"2" : @{ @"type" : @"and",
                                  @"conditions" : andConditional }};
    } else {
        whereClause = @{@"1" : @{ @"type" : @"and",
                                  @"conditions" : andConditional }};
    }

    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:@{@"where" : whereClause} options:0 error:nil];

    if (jsonData) {
        NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        urlParameters[@"params"] = jsonString;
    }

    return urlParameters;
}

@end
