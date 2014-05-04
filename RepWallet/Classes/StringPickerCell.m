//
//  StringPickerCell.m
//  repWallet
//
//  Created by Alberto Fiore on 3/12/12.
//  Copyright 2012 Alberto Fiore. All rights reserved.
//

#import "StringPickerCell.h"


@implementation StringPickerCell

@synthesize pickerValue;

- (NSString *)pickerView:(UIPickerView *)thePickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component 
{
    return (NSString *)[self.dataSourceArray objectAtIndex:row];
}


- (id)initWithStyle:(UITableViewCellStyle)style andDataSource:(NSArray *)aDataSource reuseIdentifier:(NSString *)reuseIdentifier boundClassName:(NSString *)aClassName dataKey:(NSString *)aDataKey label:(NSString *)aLabel
{
    
    if (self = [super initWithStyle:style andDataSource:aDataSource reuseIdentifier:reuseIdentifier boundClassName:aClassName dataKey:aDataKey label:aLabel]) {	
        
        // customization
        self.pickerValue = nil;
    }
    
    return self;
}

-(void) setControlValue:(id)value
{
    if(value) {

        for(int i = 0; i < [self.dataSourceArray count]; i++)
            if([[self.dataSourceArray objectAtIndex:i] isEqualToString:value]){
                [self.btn setBackgroundImage:nil forState:UIControlStateNormal];
                [self.btn setTitle:value forState:UIControlStateNormal];
                [self.pickerView selectRow:i inComponent:0 animated:NO];
                //NSLog(@"SetControlValue - Selected row %i",i);
                self.pickerValue = [self.dataSourceArray objectAtIndex:i];
                break;
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

-(id) getControlValue
{
    return self.pickerValue;
}

-(void)layoutSubviews {
    
    [super layoutSubviews];
    
    if (!_isAddEditCell && [self getControlValue] != nil && !self.addedUnderline) {
        
        self.addedUnderline = YES;
        
        // aggiungo la riga sotto
        
        float underlinePadding;
        
        if ([(RepWalletAppDelegate *)[[UIApplication sharedApplication] delegate] isIpad]) {
            underlinePadding = IPAD_UNDERLINE_PADDING;
            
        } else {
            underlinePadding = UNDERLINE_PADDING;
            
        }
        
        UIView * v = [[UIView alloc] initWithFrame:CGRectMake(self.btn.frame.origin.x, 
                                                              self.contentView.frame.origin.y
                                                              + self.contentView.frame.size.height
                                                              - underlinePadding, 
                                                              self.btn.frame.size.width, 
                                                              1
                                                              )];
        
        [v setBackgroundColor:[UIColor blackColor]];
        
        self.underline = v;
        
        [self.contentView addSubview:self.underline];
        
        [v release];
    }
}

- (void)dealloc 
{
    [self.pickerValue release];
    [super dealloc];
}


@end
