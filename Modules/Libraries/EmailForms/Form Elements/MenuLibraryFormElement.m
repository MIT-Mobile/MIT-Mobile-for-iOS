#import "MenuLibraryFormElement.h"

@implementation MenuLibraryFormElement
@dynamic value;

- (id)initWithKey:(NSString *)aKey displayLabel:(NSString *)aDisplayLabel required:(BOOL)isRequired values:(NSArray *)theValues displayValues:(NSArray *)theDisplayValues {
    self = [super initWithKey:aKey displayLabel:aDisplayLabel required:isRequired];
    if (self) {
        self.options = theValues;
        self.displayOptions = theDisplayValues;
        self.currentOptionIndex = 0;
    }
    return self;
}


- (id)initWithKey:(NSString *)aKey displayLabel:(NSString *)aDisplayLabel required:(BOOL)isRequired values:(NSArray *)theValues {
    return [self initWithKey:aKey displayLabel:aDisplayLabel required:isRequired values:theValues displayValues:theValues];
}


- (void)updateCell:(UITableViewCell *)tableViewCell {
    tableViewCell.detailTextLabel.text = self.displayOptions[self.currentOptionIndex];
}

- (UITableViewCell *)tableViewCell {
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:self.key];
    cell.textLabel.text = self.displayLabel;
    cell.detailTextLabel.text = self.displayOptions[self.currentOptionIndex];
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    return cell;
}

- (CGFloat)heightForTableViewCell {
    return 50;
}

- (void)setCurrentOptionIndex:(NSInteger)currentOptionIndex {
    if (currentOptionIndex != _currentOptionIndex) {
        _currentOptionIndex = currentOptionIndex;
        [self.delegate valueChangedForElement:self];
    }
}

- (NSString *)value {
    return self.options[self.currentOptionIndex];
}

- (void)setValue:(NSString *)value {
    NSInteger index = [self.options indexOfObject:value];
    
    if (index == NSNotFound) {
        DDLogError(@"Unable to set field to '%@' as it does not exist among possible options: %@", value, self.options);
    } else {
        self.currentOptionIndex = index;
    }
}

@end