//
//  KNSelectorItem.m
//  KNFBFriendSelectorDemo
//
//  Created by Kent Nguyen on 4/6/12.
//  Copyright (c) 2012 Kent Nguyen. All rights reserved.
//

#import "KNSelectorItem.h"

@implementation KNSelectorItem

@synthesize displayValue = _displayValue,
            displayDetail = _displayDetail,
            selectValue = _selectValue,
            imageUrl = _imageUrl,
            image = _image,
            selected = _selected;

-(id)initWithDisplayValue:(NSString*)displayVal {
  return [self initWithDisplayValue:displayVal displayDetail:@"" selectValue:displayVal];
}

-(id)initWithDisplayValue:(NSString*)displayVal
            displayDetail: (NSString*)displayDet
              selectValue:(NSString*)selectVal {
    if ((self=[super init])) {
        self.displayValue = displayVal;
        self.displayDetail = displayDet;
    self.selectValue = selectVal;
  }
  return self;
}

-(id)initWithDisplayValue:(NSString*)displayVal
              selectValue:(NSString*)selectVal
                    image:(UIImage*)image {
    self = [self initWithDisplayValue:displayVal displayDetail:@"" selectValue:selectVal];
    if (self) {
        self.image = image;
    }
    return self;
}

#pragma mark - Sort comparison

-(NSComparisonResult)compareByDisplayValue:(KNSelectorItem*)other {
  return [self.displayValue compare:other.displayValue];
}

-(NSComparisonResult)compareBySelectedValue:(KNSelectorItem*)other {
  return [self.selectValue compare:other.selectValue];
}
@end
