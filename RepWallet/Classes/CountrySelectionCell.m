//
//  CountrySelectionCell.m
//  repWallet
//
//  Created by Alberto Fiore on 3/13/12.
//  Copyright 2012 Alberto Fiore. All rights reserved.
//

#import "CountrySelectionCell.h"
#import "CoreTelephonyUtils.h"

@implementation CountrySelectionCell

@synthesize stringValue, stringSelectionVC, dataSourceArray;

// dataSourceArray in this case will be an array of dictionaries, each dictionary will contain:
// [(@"label", aLabel), (@"val", aValue)]

- (void) stringSelectionViewControllerSelectedString:(NSString *)string {
    
    for(int i = 0; i < [self.dataSourceArray count]; i++)
    {
        NSDictionary *dict = [self.dataSourceArray objectAtIndex:i];
        
        if([[dict valueForKey:@"label"] isEqualToString:string]){
            
            [self.btn setBackgroundImage:nil forState:UIControlStateNormal];
            [self.btn setTitle:string forState:UIControlStateNormal];
            self.stringValue = string;
            break;
        }
    }
    
    [self layoutSubviews];
    
    [self postEndEditingNotification];
}


- (void) show {
    
    NSArray *arr = [self.dataSourceArray valueForKey:@"label"];
    
    StringSelectionViewController *mainViewController = [[StringSelectionViewController alloc] initWithStyle:UITableViewStylePlain andDatasource:arr];
    self.stringSelectionVC = mainViewController;
    [mainViewController release];
	self.stringSelectionVC.title = @"Choose";
    self.stringSelectionVC.delegate = self;
    self.stringSelectionVC.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    self.stringSelectionVC.modalPresentationStyle = UIModalPresentationFormSheet;
    
	// Add create and configure the navigation controller.
	UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:self.stringSelectionVC];
    UIColor * c = [UIColor colorWithRed:0.5 green:0.5 blue:0.5 alpha:1.0];
    navigationController.navigationBar.tintColor = c;
    UIViewController *vc = [self viewController];
    
    if ([vc respondsToSelector:@selector(presentViewController:animated:completion:)]) {
        
        [vc presentViewController:navigationController animated:YES completion:NULL];
        
    } else if([vc respondsToSelector:@selector(presentModalViewController:animated:)]) {
        
        [vc presentModalViewController:navigationController animated:YES];
        
    }
	
    [navigationController release];
    
}

- (id) initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier boundClassName:(NSString *)aClassName dataKey:(NSString *)aDataKey label:(NSString *)aLabel
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
    
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier boundClassName:aClassName dataKey:aDataKey label:aLabel]) {
        
        self.stringValue = nil;
        
        self.dataSourceArray = arr;
        
        if([self.dataSourceArray count] == 0)
            [self setEnabled:NO];
        else
            [self setEnabled:YES];

        NSString * isoByCarr = [CoreTelephonyUtils ISOCountryCodeByCarrier];
        
        //        NSLog(@"%@", isoByCarr);
        
        if (isoByCarr) {
            [self setControlValue:[CoreTelephonyUtils countryNameByISO:isoByCarr]];
        }
    }
    
    [arr release];
    
    return self;
}

-(void) setControlValue:(id)value
{
    if (value) {
        
        for(int i = 0; i < [self.dataSourceArray count]; i++){
            
            NSDictionary *dict = [self.dataSourceArray objectAtIndex:i];
            
            if([[dict objectForKey:@"label"] isEqualToString:value])
            {
                [self.btn setBackgroundImage:nil forState:UIControlStateNormal];
                [self.btn setTitle:value forState:UIControlStateNormal];
                self.stringValue = value;
                break;
            }
        }
        
    } else {
        
        self.stringValue = nil;
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
    return self.stringValue;
}

- (NSString *)getLabelValue {
    
    return [self.btn titleForState:UIControlStateNormal];
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

-(void)setEnabled:(BOOL)enabled
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
                self.stringValue = s;
                break;
            }
        }
    }
    
    [super setEnabled:enabled];
    
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

-(void)reload
{
    if([self.dataSourceArray count] == 0)
        [self setEnabled:NO];
    else
        [self setEnabled:YES];
}

- (void)dealloc
{
    if (self.stringSelectionVC) {
        self.stringSelectionVC.delegate = nil;
    }
    
    [self.dataSourceArray release];
    [self.stringValue release];
    [self.stringSelectionVC release];
    [super dealloc];
}

@end
