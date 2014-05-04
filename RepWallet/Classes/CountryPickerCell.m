//
//  CountryPickerCell.m
//  repWallet
//
//  Created by Alberto Fiore on 11/16/12.
//  Copyright 2012 Alberto Fiore. All rights reserved.
//

#import "CountryPickerCell.h"
#import "CoreTelephonyUtils.h"

@implementation CountryPickerCell

// aDataSource in this case will be an array of dictionaries, each dictionary will contain:
// [(@"label", aLabel), (@"val", aValue)]

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier boundClassName:(NSString *)aClassName dataKey:(NSString *)aDataKey label:(NSString *)aLabel
{
    NSArray * isoCodes = [NSLocale ISOCountryCodes];
    NSMutableArray * arr = [NSMutableArray arrayWithCapacity:[isoCodes count]];
    for (NSString * iso in isoCodes) {
        NSString *countryName = [CoreTelephonyUtils countryNameByISO:iso];
        [arr addObject:[NSDictionary dictionaryWithObjectsAndKeys:countryName, @"label", iso, @"val", nil]];
    }
    
    arr = [[arr sortedArrayUsingComparator:^(id a, id b) {
        
        NSString *first = [(NSDictionary *)a objectForKey:@"label"];
        NSString *second = [(NSDictionary *)b objectForKey:@"label"];
        
        // in ascending order	
        
        return [first caseInsensitiveCompare:second];
        
    }] mutableCopy];
    
    if (self = [super initWithStyle:style andDataSource:arr reuseIdentifier:reuseIdentifier boundClassName:aClassName dataKey:aDataKey label:aLabel]) {	
        
        NSString * isoByCarr = [CoreTelephonyUtils ISOCountryCodeByCarrier];
        
//        NSLog(@"%@", isoByCarr);
        
        if (isoByCarr) {
            [self setControlValue:[CoreTelephonyUtils countryNameByISO:isoByCarr]];
        }

    }
    
    [arr release];
    
    return self;
}

// control value is a country name
- (void) setControlValue:(id)value 
{
    if(value) { 
        
        NSString * s = value;

        for(int i = 0; i < [self.dataSourceArray count]; i++) {
            
            NSDictionary *dict = [self.dataSourceArray objectAtIndex:i];
            
            if([[dict valueForKey:@"label"] isEqualToString:s]) {
                
                [self.btn setBackgroundImage:nil forState:UIControlStateNormal];
                
                [self.btn setTitle:s forState:UIControlStateNormal];
                
                [self.pickerView selectRow:i inComponent:0 animated:NO];
                
                self.pickerValue = s;
                
                break;
            }
        }
        
    } else {
        
        self.pickerValue = nil;
        [self.btn setBackgroundImage:[UIImage imageNamed:@"chooseElement.png"] forState:UIControlStateNormal];
        [self.underline removeFromSuperview];
        self.underline = nil;
        self.addedUnderline = NO;
        [self.btn setTitle:nil forState:UIControlStateNormal];
        
    }
    
    [self layoutSubviews];
}

- (NSString *) getISOCodeForControlValue {
    
    NSString * s = [self getControlValue];
    
    if (s) {
        
        for(int i = 0; i < [self.dataSourceArray count]; i++){
            NSDictionary *dict = [self.dataSourceArray objectAtIndex:i];
            
            if([[dict valueForKey:@"label"] isEqualToString:s]){
                return [dict valueForKey:@"val"];
            }
        }
    }
    
    return nil;
    
}

#pragma mark UIActionSheetDelegate

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 0) { // OK
        NSDictionary *dict = (NSDictionary *)[self.dataSourceArray objectAtIndex:[self.pickerView selectedRowInComponent:0]];
        [self setControlValue:[dict valueForKey:@"label"]];
        [self postEndEditingNotification];
    } else if (buttonIndex == 1) { // CANCEL
        ;
    } 
}

@end
