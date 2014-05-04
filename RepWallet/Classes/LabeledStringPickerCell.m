//
//  LabeledStringPickerCell.m
//  repWallet
//
//  Created by Alberto Fiore on 5/4/12.
//  Copyright 2012 Alberto Fiore. All rights reserved.
//

#import "LabeledStringPickerCell.h"

@implementation LabeledStringPickerCell

@synthesize pickerValue;

- (NSString *)pickerView:(UIPickerView *)thePickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component 
{
    NSDictionary *dict = (NSDictionary *)[self.dataSourceArray objectAtIndex:row];
    return (NSString *)[dict valueForKey:@"label"];
}

// aDataSource in this case will be an array of dictionaries, each dictionary will contain:
// [(@"label", aLabel), (@"val", aValue)]

- (id)initWithStyle:(UITableViewCellStyle)style andDataSource:(NSArray *)aDataSource reuseIdentifier:(NSString *)reuseIdentifier boundClassName:(NSString *)aClassName dataKey:(NSString *)aDataKey label:(NSString *)aLabel
{
    if (self = [super initWithStyle:style andDataSource:aDataSource reuseIdentifier:reuseIdentifier boundClassName:aClassName dataKey:aDataKey label:aLabel]) {	

        // customization
        self.pickerValue = nil;
    }
    
    return self;
}

- (void)setControlValue:(id)value
{    
    if(value) { 

        for(int i = 0; i < [self.dataSourceArray count]; i++){
            
            NSDictionary *dict = [self.dataSourceArray objectAtIndex:i];
            
            if([[dict valueForKey:@"val"] isEqualToString:value]){
                
                [self.btn setBackgroundImage:nil forState:UIControlStateNormal];
                [self.btn setTitle:[dict valueForKey:@"label"] forState:UIControlStateNormal];                
                [self.pickerView selectRow:i inComponent:0 animated:NO];
                self.pickerValue = value;
                break;
            }
        }
        
        // notifico altre celle per la disabilitazione

        [[NSNotificationCenter defaultCenter] 
         postNotificationName:[NSString stringWithFormat:@"%@%@", self.boundClassName, self.dataKey] 
         object:nil 
         userInfo:[NSDictionary dictionaryWithObject:self.pickerValue forKey:@"value"]];
            
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

- (NSString *)getLabelValue {
    
    return [self.btn titleForState:UIControlStateNormal];
}

- (id)getControlValue
{
    return self.pickerValue;
}

- (void) setEnabled:(BOOL)enabled 
{
    if (enabled && [self getControlValue]) {
        
        NSString *s = [self getControlValue];
        
        for(int i = 0; i < [self.dataSourceArray count]; i++)
        {
            NSDictionary *dict = [self.dataSourceArray objectAtIndex:i];
            
            if([[dict valueForKey:@"val"] isEqualToString:s])
            {
                [self.btn setBackgroundImage:nil forState:UIControlStateNormal];
                [self.btn setTitle:[dict valueForKey:@"label"] forState:UIControlStateNormal];                
                [self.pickerView selectRow:i inComponent:0 animated:NO];
                break;
            }
        }        
    } 
    
    [super setEnabled:enabled];
    
    [self layoutSubviews];
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

#pragma mark UIActionSheetDelegate

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 0) { // OK
        NSDictionary *dict = (NSDictionary *)[self.dataSourceArray objectAtIndex:[self.pickerView selectedRowInComponent:0]];
        [self setControlValue:[dict valueForKey:@"val"]];
        [self postEndEditingNotification];
    } else if (buttonIndex == 1) { // CANCEL
        ;
    } 
}


@end
