//
//  AddEditViewController.m
//  repWallet
//
//  Created by Alberto Fiore on 1/31/12.
//  Copyright 2012 Alberto Fiore. All rights reserved.
//

#import "AddEditViewController.h"
#import <objc/runtime.h>
#import "MBProgressHUD.h"
#import "FwdGeocoder.h"
#import "MapController.h"
#import <MessageUI/MessageUI.h>
#import "FirmViewController.h"
#import "BaseDataEntryCell.h"
#import "Firm.h"
#import "UnpaidInvoice.h"
#import "Event.h"
#import "Statistic.h"
#import "Mappable.h"
#import "SwitchCell.h"
#import "DisclosureCell.h"
#import "DatePickerCell.h"
#import "ItemCategorySuggestionCell.h"
#import "BusinessCategorySuggestionCell.h"
#import "FirmSelectionCell.h"
#import "RepWalletAppDelegate.h"
#import "UITableViewController+CustomDrawing.h"
#import "CountrySelectionCell.h"
#import "NSObject+CheckConnectivity.h"
#import "PhotoPickerCell.h"
#import "DocumentPickerCell.h"
#import "EventForFirmViewController.h"
#import "UnpaidForFirmViewController.h"
#import "AppointmentForFirmViewController.h"
#import "Appointment.h"
#import "LabeledStringSelectionCell.h"
#import "StringSelectionCell.h"

static NSMutableSet *openedFirmIDs = nil;
static NSMutableSet *openedEventIDs = nil;
static NSMutableSet *openedUnpaidInvoiceIDs = nil;
static NSMutableSet *openedAppointmentIDs = nil;

@interface AddEditViewController () <UIScrollViewDelegate, FwdGeocoderDelegate, MapControllerDelegate, UIAccelerometerDelegate, UIActionSheetDelegate, MFMessageComposeViewControllerDelegate, MFMailComposeViewControllerDelegate>
{
    BOOL histeresisExcited;
    BOOL addAnotherOne;
}

@property (nonatomic, retain) NSIndexPath *firstVisibleIndexPath;
@property (nonatomic, retain) NSIndexPath *lastVisibleIndexPath;
@property (nonatomic, retain) MapController *mapC;
@property (nonatomic, retain) UIAcceleration* lastAcceleration;
@property (nonatomic, retain) DAO *dao;
@property (nonatomic, retain) NSManagedObject *managedEntity;
@property (nonatomic, retain) NSArray *tableStructure;
@property (nonatomic, retain) NSMutableDictionary* undoDict; 
@property (nonatomic, retain) NSMutableDictionary* cacheDict;
@property (nonatomic, retain) Statistic * statToRemove;
@property (nonatomic, retain) NSMutableDictionary *cells;
@property (nonatomic, retain) MBProgressHUD *progressHUD;
@property (nonatomic, retain) FwdGeocoder * geocoderV2;

- (void) initDictFromEntity: (NSMutableDictionary *) dictio;
- (BOOL) checkMandatoryConstraints;
- (BOOL) checkPKConstraints;
- (BOOL) checkFieldValidationConstraints;
- (void) initTableStructure;
- (void) setEntityProperty:(NSString *)dataKey value:(id)v;
- (void) validateEntity;
- (void) modifyEntity;
- (void) saveEntity;
- (void) undo;
- (void) checkAddress;
- (void) checkDisclosureCellNotification:(NSNotification *)notification;
- (void) showEventsForFirm:(Firm *)firm;
- (void) showUnpaidsForFirm:(Firm *)firm;
- (void) showAppointmentsForFirm:(Firm *)firm;
- (void) viewControllerWillBePopped;
@end

@implementation AddEditViewController

@synthesize lastAcceleration;
@synthesize managedEntity;
@synthesize dao;
@synthesize tableStructure;
@synthesize undoDict;
@synthesize statToRemove;
@synthesize cells;
@synthesize progressHUD;
@synthesize geocoderV2;
@synthesize delegate;
@synthesize mapC;
@synthesize cacheDict;
@synthesize lastVisibleIndexPath;
@synthesize firstVisibleIndexPath;

# pragma mark - Change orientation

- (NSUInteger)supportedInterfaceOrientations
{
    return (1 << UIInterfaceOrientationPortrait) | (1 << UIInterfaceOrientationPortraitUpsideDown) | (1 << UIInterfaceOrientationLandscapeLeft) | (1 << UIInterfaceOrientationLandscapeRight);
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)orientation
{
    return ((orientation == UIInterfaceOrientationPortrait) ||
            (orientation == UIInterfaceOrientationPortraitUpsideDown) ||
            (orientation == UIInterfaceOrientationLandscapeLeft) ||
            (orientation == UIInterfaceOrientationLandscapeRight));
}

-(void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    
    [super willAnimateRotationToInterfaceOrientation:toInterfaceOrientation duration:duration];
    
    int rowHeight, headerHeight, footerHeight;
    
    if([(RepWalletAppDelegate *)[[UIApplication sharedApplication] delegate] isIpad]) {
        rowHeight = 120;
        headerHeight = 156;
        footerHeight = 156;
    }
    
    else {
        rowHeight = 50;
        headerHeight = 65;
        footerHeight = 65;
    }
    
    [self customizeTableViewDrawingWithHeader:nil headerBg:@"bgHeader" footer:nil footerBg:@"bgFooter" background:nil backgroundColor:[UIColor whiteColor] rowHeight:rowHeight headerHeight:headerHeight footerHeight:footerHeight deviceOrientationIsPortrait:UIDeviceOrientationIsPortrait(self.interfaceOrientation)];
}

-(void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    
    self.firstVisibleIndexPath = nil;
    
    self.lastVisibleIndexPath = nil;

    [self.tableView reloadData];
}

#pragma mark - View controller mode

- (BOOL) isInEditingMode {
    
    return [self.title isEqualToString:ADDEDITVIEWCONTROLLER_EDIT_MODE_TITLE];
    
}

#pragma mark - Appointment

- (void) finalizeAppointment:(Appointment *)app {
    
    NSCalendar *calendar = [NSCalendar currentCalendar];
    
    int secondsToSub = -[app.timeLeftToRemind intValue];
    
    NSDateComponents *components = [[[NSDateComponents alloc] init] autorelease];
    [components setSecond:secondsToSub];
    
    app.remindDateTime = [calendar dateByAddingComponents:components toDate:app.dateTime options:0];
    
    NSDate *now = [NSDate date];
    
    if ([app.repeat boolValue]) {
        
        NSCalendar *calendar = calendar = [NSCalendar currentCalendar];
        
        NSDateComponents *components = [[[NSDateComponents alloc] init] autorelease];
        
        if ([app.calendarRepeatUnit isEqualToString:@"day"]) {
            
            components.day = 1;
            
        } else if ([app.calendarRepeatUnit isEqualToString:@"week"]) {
            
            components.week = 1;
            
        } else if ([app.calendarRepeatUnit isEqualToString:@"month"]) {
            
            components.month = 1;
            
        } else if ([app.calendarRepeatUnit isEqualToString:@"year"]) {
            
            components.year = 1;
            
        }
        
        while([now compare:app.dateTime] == NSOrderedDescending) {

            
            app.dateTime = [calendar dateByAddingComponents:components toDate:app.dateTime options:0];
            
        }
        
        while ([now compare:app.remindDateTime] == NSOrderedDescending) {
            
            app.remindDateTime = [calendar dateByAddingComponents:components toDate:app.remindDateTime options:0];
        }
        
    }
}


#pragma mark - MBProgressHUD

- (MBProgressHUD *)createProgressHUDForView:(UIView *)view {
    
    if (!self.progressHUD || ![self.progressHUD.superview isEqual:view]) {
        
        MBProgressHUD * p = [[MBProgressHUD alloc] initWithView:view];
        self.progressHUD = p;
        [p release];
        self.progressHUD.minSize = CGSizeMake(120, 120);
        self.progressHUD.minShowTime = 0.5;
        self.progressHUD.customView = [[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"MWPhotoBrowser.bundle/images/Checkmark.png"]] autorelease];
        [view addSubview:self.progressHUD];
    }
    return self.progressHUD;
}

- (void)showProgressHUDWithMessage:(NSString *)message {
    self.progressHUD.labelText = message;
    self.progressHUD.mode = MBProgressHUDModeIndeterminate;
    [self.progressHUD show:YES];
}

- (void)hideProgressHUD:(BOOL)animated {
    [self.progressHUD hide:animated];
}

- (void)showProgressHUDCompleteMessage:(NSString *)message {
    if (message) {
        if (self.progressHUD.isHidden) [self.progressHUD show:YES];
        self.progressHUD.labelText = message;
        self.progressHUD.mode = MBProgressHUDModeCustomView;
        [self.progressHUD hide:YES afterDelay:1.5];
    } else {
        [self.progressHUD hide:YES];
    }
}

#pragma mark -
#pragma mark Open entities management

+ (BOOL)isEditingFirmWithID:(NSManagedObjectID *)objID 
{
    if (openedFirmIDs) {
        
        return [openedFirmIDs containsObject:objID];
        
    } else
        
        return NO;
}

+ (BOOL)isEditingEventWithID:(NSManagedObjectID *)objID 
{
    if (openedEventIDs) {
        
        return [openedEventIDs containsObject:objID];
        
    } else
        
        return NO;
}

+ (BOOL)isEditingUnpaidInvoiceWithID:(NSManagedObjectID *)objID 
{
    if (openedUnpaidInvoiceIDs) {
        
        return [openedUnpaidInvoiceIDs containsObject:objID];
        
    } else
        
        return NO;
}

+ (BOOL)isEditingAppointmentWithID:(NSManagedObjectID *)objID 
{
    if (openedAppointmentIDs) {
        
        return [openedAppointmentIDs containsObject:objID];
        
    } else
        
        return NO;
}

- (void)openedFirmWithID:(NSManagedObjectID *)objID 
{
    if (![openedFirmIDs containsObject:objID]) {
        
        [openedFirmIDs addObject:objID];
    }
}

- (void)closedFirmWithID:(NSManagedObjectID *)objID 
{
    [openedFirmIDs removeObject:objID];
}

- (void)openedEventWithID:(NSManagedObjectID *)objID 
{
    if (![openedEventIDs containsObject:objID]) {
        
        [openedEventIDs addObject:objID];
    }
}

- (void)closedEventWithID:(NSManagedObjectID *)objID 
{
    [openedEventIDs removeObject:objID];
}

- (void)openedUnpaidInvoiceWithID:(NSManagedObjectID *)objID 
{
    if (![openedUnpaidInvoiceIDs containsObject:objID]) {
        
        [openedUnpaidInvoiceIDs addObject:objID];
    }
}

- (void)closedUnpaidInvoiceWithID:(NSManagedObjectID *)objID 
{
    [openedUnpaidInvoiceIDs removeObject:objID];
}

- (void)openedAppointmentWithID:(NSManagedObjectID *)objID 
{
    if (![openedAppointmentIDs containsObject:objID]) {
        
        [openedAppointmentIDs addObject:objID];
    }
}

- (void)closedAppointmentWithID:(NSManagedObjectID *)objID 
{
    [openedAppointmentIDs removeObject:objID];
}

- (void) closedEntity {
    
    if ([self.managedEntity isMemberOfClass:[Firm class]]) {
        
        [self closedFirmWithID:[self.managedEntity objectID]];
        
        if (self.delegate && [self.delegate respondsToSelector:@selector(addEditViewControllerClosedFirmWithID:)]) {
            [self.delegate addEditViewControllerClosedFirmWithID:[self.managedEntity objectID]];
        }
        
    } else if ([self.managedEntity isMemberOfClass:[Event class]]) {
        
        [self closedEventWithID:[self.managedEntity objectID]];
        
        if (self.delegate && [self.delegate respondsToSelector:@selector(addEditViewControllerClosedEventWithID:)]) {
            [self.delegate addEditViewControllerClosedEventWithID:[self.managedEntity objectID]];
        }
        
    } else if ([self.managedEntity isMemberOfClass:[UnpaidInvoice class]]) {
        
        [self closedUnpaidInvoiceWithID:[self.managedEntity objectID]];
        
        if (self.delegate && [self.delegate respondsToSelector:@selector(addEditViewControllerClosedUnpaidWithID:)]) {
            [self.delegate addEditViewControllerClosedUnpaidWithID:[self.managedEntity objectID]];
        }
        
    }  else if ([self.managedEntity isMemberOfClass:[Appointment class]]) {
        
        [self closedAppointmentWithID:[self.managedEntity objectID]];
        
        if (self.delegate && [self.delegate respondsToSelector:@selector(addEditViewControllerClosedAppointmentWithID:)]) {
            [self.delegate addEditViewControllerClosedAppointmentWithID:[self.managedEntity objectID]];
        }
    }
}

- (void) openedEntity {
    
    if([self.managedEntity isMemberOfClass:[Firm class]]) {
        
        [self openedFirmWithID:[self.managedEntity objectID]];
        
        if (self.delegate && [self.delegate respondsToSelector:@selector(addEditViewControllerOpenedFirmWithID:)]) {
            [self.delegate addEditViewControllerOpenedFirmWithID:[self.managedEntity objectID]];
        }
        
    } else if([self.managedEntity isMemberOfClass:[UnpaidInvoice class]]) {
        
        [self openedUnpaidInvoiceWithID:[self.managedEntity objectID]];
        
        if (self.delegate && [self.delegate respondsToSelector:@selector(addEditViewControllerOpenedUnpaidWithID:)]) {
            [self.delegate addEditViewControllerOpenedUnpaidWithID:[self.managedEntity objectID]];
        }
        
    } else if([self.managedEntity isMemberOfClass:[Event class]]) {
        
        [self openedEventWithID:[self.managedEntity objectID]];
        
        if (self.delegate && [self.delegate respondsToSelector:@selector(addEditViewControllerOpenedEventWithID:)]) {
            [self.delegate addEditViewControllerOpenedEventWithID:[self.managedEntity objectID]];
        }
        
    }  else if([self.managedEntity isMemberOfClass:[Appointment class]]) {
        
        [self openedAppointmentWithID:[self.managedEntity objectID]];
        
        if (self.delegate && [self.delegate respondsToSelector:@selector(addEditViewControllerOpenedAppointmentWithID:)]) {
            [self.delegate addEditViewControllerOpenedAppointmentWithID:[self.managedEntity objectID]];
        }
        
    } else
        NSLog(@"Cannot determine entity type!");
    
}

#pragma mark -
#pragma mark Navigation control

- (void) viewControllerWillBePopped {
    
    if (self.progressHUD && self.progressHUD.superview) {
        
        [self hideProgressHUD:YES];
        
        [(RepWalletAppDelegate *)[[UIApplication sharedApplication] delegate] setNetworkActivityIndicatorVisible:NO force:NO];
    }
    
    if ([self.title isEqualToString:ADDEDITVIEWCONTROLLER_EDIT_MODE_TITLE]) {
        
        [self closedEntity];
        
    }
}

- (void) getBack {
    
    if ([self.title isEqualToString:ADDEDITVIEWCONTROLLER_INSERT_MODE_TITLE]) {
        
        if ([self.managedEntity isMemberOfClass:[Event class]]) {
            
            [[NSNotificationCenter defaultCenter] 
             postNotificationName:DISABLE_INSERTION_OF_ANOTHER_EVENT_NOTIFICATION object:nil];
            
        } else if ([self.managedEntity isMemberOfClass:[UnpaidInvoice class]]) {
            
            [[NSNotificationCenter defaultCenter] 
             postNotificationName:DISABLE_INSERTION_OF_ANOTHER_UNPAID_NOTIFICATION object:nil];
            
        }  else if ([self.managedEntity isMemberOfClass:[Appointment class]]) {
            
            [[NSNotificationCenter defaultCenter] 
             postNotificationName:DISABLE_INSERTION_OF_ANOTHER_APPOINTMENT_NOTIFICATION object:nil];
            
        }
    }
    
    [self viewControllerWillBePopped];
    
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark -
#pragma mark Messaging & Calling

-(void)callNr:(NSString *)nr  {
    
    NSString *cleanedNr = [[nr componentsSeparatedByCharactersInSet:[[NSCharacterSet characterSetWithCharactersInString:@"0123456789-+()"] invertedSet]] componentsJoinedByString:@""];
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:[NSString stringWithFormat:@"telprompt://%@", cleanedNr]]];
    
}

-(void)writeSmsInModalViewToNumber:(NSString *)nr {
    
    MFMessageComposeViewController *controller = [[MFMessageComposeViewController alloc] init];
    controller.body = @"";
    NSString *cleanedNr = [[nr componentsSeparatedByCharactersInSet:[[NSCharacterSet characterSetWithCharactersInString:@"0123456789-+()"] invertedSet]] componentsJoinedByString:@""];
    controller.recipients = [NSArray arrayWithObject:cleanedNr];
    controller.messageComposeDelegate = self;

    if ([self respondsToSelector:@selector(presentViewController:animated:completion:)]) {
        
        [self presentViewController:controller animated:YES completion:NULL];
        
    } else if([self respondsToSelector:@selector(presentModalViewController:animated:)]) {
        
        [self presentModalViewController:controller animated:YES];
        
    }
    
    [controller release];
    
}

-(void) writeEmailInModalViewToAddress:(NSString *)addr {
    
    MFMailComposeViewController *picker = [[MFMailComposeViewController alloc] init];
    picker.mailComposeDelegate = self;
    [picker setSubject:@""];
    [picker setToRecipients:[NSArray arrayWithObject:addr]];
    [picker setMessageBody:@"" isHTML:YES];
    
    if ([self respondsToSelector:@selector(presentViewController:animated:completion:)]) {
        
        [self presentViewController:picker animated:YES completion:NULL];
        
    } else if([self respondsToSelector:@selector(presentModalViewController:animated:)]) {
        
        [self presentModalViewController:picker animated:YES];
        
    }
    
    [picker release];
    
}

- (void)messageComposeViewController:(MFMessageComposeViewController *)controller didFinishWithResult:(MessageComposeResult)result
{
	switch (result) {
		case MessageComposeResultCancelled:
			break;
		case MessageComposeResultFailed: {
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error" message:@"There was a problem while sending the SMS." delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
            [alertView show];
            [alertView release];
			break;
        }
        case MessageComposeResultSent:
			break;
		default:
			break;
	}
    
	if ([self respondsToSelector:@selector(dismissViewControllerAnimated:completion:)]) {
        [self dismissViewControllerAnimated:YES completion:NULL];
    } else if ([self respondsToSelector:@selector(dismissModalViewControllerAnimated:)]) {
        [self dismissModalViewControllerAnimated:YES];
    } 
}

- (void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error
{ 
    // Notifies users about errors associated with the interface
    switch (result)
    {
        case MFMailComposeResultCancelled:
            break;
        case MFMailComposeResultSaved:
            break;
        case MFMailComposeResultSent:
            break;
        case MFMailComposeResultFailed:
        {
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error" message:@"There was a problem while sending the e-mail." delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
            [alertView show];
            [alertView release];
        }
            break;
            
        default:
            break;
    }
    if ([self respondsToSelector:@selector(dismissViewControllerAnimated:completion:)]) {
        [self dismissViewControllerAnimated:YES completion:NULL];
    } else if ([self respondsToSelector:@selector(dismissModalViewControllerAnimated:)]) {
        [self dismissModalViewControllerAnimated:YES];
    } 
}


#pragma mark -
#pragma mark Shake gesture

BOOL L0AccelerationIsShaking(UIAcceleration* last, UIAcceleration* current, double threshold) {
	double
    deltaX = fabs(last.x - current.x),
    deltaY = fabs(last.y - current.y),
    deltaZ = fabs(last.z - current.z);
    
	return
    (deltaX > threshold && deltaY > threshold) ||
    (deltaX > threshold && deltaZ > threshold) ||
    (deltaY > threshold && deltaZ > threshold);
}

- (void) accelerometer:(UIAccelerometer *)accelerometer didAccelerate:(UIAcceleration *)acceleration {
    
	if (self.lastAcceleration) {
        
		if (!histeresisExcited && L0AccelerationIsShaking(self.lastAcceleration, acceleration, 0.7)) {
            
			histeresisExcited = YES;
            
            if([self.managedEntity isMemberOfClass:[Firm class]]) {
                
                Firm * firm = (Firm *)self.managedEntity;
                
                UIActionSheet *a = [[UIActionSheet alloc] initWithTitle:@"Choose an action" delegate:self cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:nil];
                
                int cancelButtonIndex = 0;
                
                if ([self.cells objectForKey:NSStringFromSelector(@selector(phoneNr1))]) {
                    
                    id phone1Cell = [self.cells objectForKey:NSStringFromSelector(@selector(phoneNr1))];
                    
                    if([phone1Cell getControlValue]
                       && [phone1Cell hasValidControlValue]) { 
                        
                        if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"tel://"]]) 
                        {
                            [a addButtonWithTitle:[NSString stringWithFormat:@"%@%@", 
                                                   PHONE_ACTION_SHEET_BTN_PREFIX, 
                                                   [phone1Cell getControlValue]
                                                   ]];
                            cancelButtonIndex++;
                        }
                        
                        if([MFMessageComposeViewController canSendText]) 
                        {
                            
                            [a addButtonWithTitle:[NSString stringWithFormat:@"%@%@", 
                                                   SMS_ACTION_SHEET_BTN_PREFIX, 
                                                   [phone1Cell getControlValue]
                                                   ]];
                            cancelButtonIndex++;
                        }
                        
                    }
                    
                } else if([firm respondsToSelector:@selector(phoneNr1)]
                        && [firm performSelector:@selector(phoneNr1)]) { 
                    
                    if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"tel://"]]) {
                        
                        [a addButtonWithTitle:[NSString stringWithFormat:@"%@%@", 
                                           PHONE_ACTION_SHEET_BTN_PREFIX, 
                                           [firm performSelector:@selector(phoneNr1)]
                                           ]];
                        cancelButtonIndex++;
                    }
                    
                    
                    if([MFMessageComposeViewController canSendText]) {
                        
                        [a addButtonWithTitle:[NSString stringWithFormat:@"%@%@", 
                                               SMS_ACTION_SHEET_BTN_PREFIX, 
                                               [firm performSelector:@selector(phoneNr1)]
                                               ]];
                        cancelButtonIndex++;
                    }
                }
                
                if ([self.cells objectForKey:NSStringFromSelector(@selector(phoneNr2))]) {
                    
                    id phone2Cell = [self.cells objectForKey:NSStringFromSelector(@selector(phoneNr2))];
                    
                    if([phone2Cell getControlValue]
                       && [phone2Cell hasValidControlValue])  { 
                        
                        if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"tel://"]]) {
                            
                            [a addButtonWithTitle:[NSString stringWithFormat:@"%@%@", 
                                                   PHONE_ACTION_SHEET_BTN_PREFIX, 
                                                   [phone2Cell getControlValue]
                                                   ]];
                            cancelButtonIndex++;
                        }
                        
                        if([MFMessageComposeViewController canSendText]) {
                            
                            [a addButtonWithTitle:[NSString stringWithFormat:@"%@%@", 
                                                   SMS_ACTION_SHEET_BTN_PREFIX, 
                                                   [phone2Cell getControlValue]
                                                   ]];
                            cancelButtonIndex++;
                        }
                    }
                    
                } else if([firm respondsToSelector:@selector(phoneNr2)]
                        && [firm performSelector:@selector(phoneNr2)]) { 
                  
                    if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"tel://"]]) {
                        
                        [a addButtonWithTitle:[NSString stringWithFormat:@"%@%@", 
                                               PHONE_ACTION_SHEET_BTN_PREFIX, 
                                               [firm performSelector:@selector(phoneNr2)]
                                               ]];
                        cancelButtonIndex++;
                    }
                    
                    if([MFMessageComposeViewController canSendText]) {
                        
                        [a addButtonWithTitle:[NSString stringWithFormat:@"%@%@", 
                                               SMS_ACTION_SHEET_BTN_PREFIX, 
                                               [firm performSelector:@selector(phoneNr2)]
                                               ]];
                        cancelButtonIndex++;
                    }
                }
                
                if ([self.cells objectForKey:NSStringFromSelector(@selector(eMail))]) {
                    
                    id emailCell = [self.cells objectForKey:NSStringFromSelector(@selector(eMail))];
                    
                    if(
                       [MFMailComposeViewController canSendMail]
                       && [emailCell getControlValue]
                       && [emailCell hasValidControlValue]
                       ) 
                    { 
                        
                        [a addButtonWithTitle:[NSString stringWithFormat:@"%@%@", 
                                               EMAIL_ACTION_SHEET_BTN_PREFIX, 
                                               [emailCell getControlValue]
                                               ]];
                        cancelButtonIndex++;
                        
                    } 
                    
                } else if(
                    [MFMailComposeViewController canSendMail]
                    && [firm respondsToSelector:@selector(eMail)]
                    && [firm performSelector:@selector(eMail)]
                        ) 
                { 
                        
                    [a addButtonWithTitle:[NSString stringWithFormat:@"%@%@", 
                                           EMAIL_ACTION_SHEET_BTN_PREFIX, 
                                           [firm performSelector:@selector(eMail)]]
                                           ];
                    cancelButtonIndex++;
                } 
                
                if (cancelButtonIndex > 0) {
                    
                    [a addButtonWithTitle:@"Cancel"];
                    
                    a.cancelButtonIndex = cancelButtonIndex;
                    
                    [a setActionSheetStyle:UIActionSheetStyleBlackTranslucent];
                    
                    [UIAccelerometer sharedAccelerometer].delegate = nil;
                    
                    [a showFromTabBar:self.tabBarController.tabBar];
                }
                
                [a release];
                
            }
            
            
		} else if (histeresisExcited && !L0AccelerationIsShaking(self.lastAcceleration, acceleration, 0.2)) {
			histeresisExcited = NO;
		}
	}
    
	self.lastAcceleration = acceleration;
}

#pragma mark -
#pragma mark Action sheet

-(void)actionSheet:(UIActionSheet *)actionSheet willDismissWithButtonIndex:(NSInteger)buttonIndex {
    if (actionSheet.cancelButtonIndex == buttonIndex) {
        [UIAccelerometer sharedAccelerometer].delegate = self;
    }
}

-(void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex 
{    
    if ([[actionSheet buttonTitleAtIndex:buttonIndex] hasPrefix:SMS_ACTION_SHEET_BTN_PREFIX]) {
        NSString *nr = [[actionSheet buttonTitleAtIndex:buttonIndex] substringFromIndex:[SMS_ACTION_SHEET_BTN_PREFIX length]];
        [self writeSmsInModalViewToNumber:nr];
    } else if ([[actionSheet buttonTitleAtIndex:buttonIndex] hasPrefix:EMAIL_ACTION_SHEET_BTN_PREFIX]) {
        NSString *addr = [[actionSheet buttonTitleAtIndex:buttonIndex] substringFromIndex:[EMAIL_ACTION_SHEET_BTN_PREFIX length]];
        [self writeEmailInModalViewToAddress:addr];
    } else if ([[actionSheet buttonTitleAtIndex:buttonIndex] hasPrefix:PHONE_ACTION_SHEET_BTN_PREFIX]) {
        NSString *nr = [[actionSheet buttonTitleAtIndex:buttonIndex] substringFromIndex:[PHONE_ACTION_SHEET_BTN_PREFIX length]];
        [self callNr:nr];
    } else
        ;
}

#pragma mark -
#pragma mark Scrolling

-(void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    
    [[NSNotificationCenter defaultCenter] 
     postNotificationName:DRAGGING_STARTED_NOTIFICATION
     object:nil 
     userInfo:nil];
}

#pragma mark -
#pragma mark Initialization

- (id)initWithStyle:(UITableViewStyle)style title:(NSString *)aTitle entity:(NSManagedObject *)anEntity andDao:(DAO *)aDao
{
//    NSLog(@"init for addeditVC %@", self);
    
    self = [super initWithStyle:style];
    
    if (self) {
        
        if (!openedFirmIDs) {
            openedFirmIDs = [[NSMutableSet alloc] initWithCapacity:2];
        }
        
        [openedFirmIDs retain];
        
        if (!openedEventIDs) {
            openedEventIDs = [[NSMutableSet alloc] initWithCapacity:2];
        }
        
        [openedEventIDs retain];
        
        if (!openedUnpaidInvoiceIDs) {
            openedUnpaidInvoiceIDs = [[NSMutableSet alloc] initWithCapacity:2];
        }
        
        [openedUnpaidInvoiceIDs retain];
        
        if (!openedAppointmentIDs) {
            openedAppointmentIDs = [[NSMutableSet alloc] initWithCapacity:2];
        }
        
        [openedAppointmentIDs retain];

        self.title = aTitle;
        
        addAnotherOne = NO;
        
        self.dao = aDao;
 
        if (anEntity) {
            
            self.managedEntity = anEntity;
        }
        
        self.cacheDict = [NSMutableDictionary dictionary];
        
        viewDidDisappear = NO;
    }
    
    return self;
}

- (id)initWithStyle:(UITableViewStyle)style title:(NSString *)aTitle entity:(NSManagedObject *)anEntity andDao:(DAO *)aDao addAnotherOne:(BOOL)haveToAddAnotherOne
{
    self = [self initWithStyle:style title:aTitle entity:anEntity andDao:aDao];
    
    if (self) {
        
        addAnotherOne = haveToAddAnotherOne;
        
    }
    
    return self;
}

- (void) initTableStructure 
{    
    NSString *className = NSStringFromClass([self.managedEntity class]);
    
    NSString *lcClassName = [[[NSMutableString stringWithString:className] lowercaseString] stringByReplacingOccurrencesOfString:@" " withString:@"-"];
    
    NSString *plisStructure = [[NSBundle mainBundle] pathForResource:[NSString stringWithFormat: @"%@-form-structure.plist", lcClassName] ofType:nil];
    
    self.tableStructure = [NSArray arrayWithContentsOfFile:plisStructure]; 
}

#pragma mark -
#pragma mark Geocoder delegate

-(void) geocoderFailedWithError:(NSString *)errorMsg
{
    [(RepWalletAppDelegate *)[[UIApplication sharedApplication] delegate] setNetworkActivityIndicatorVisible:NO force:NO];
//    [self.navigationItem.rightBarButtonItem setEnabled:YES];
    [self hideProgressHUD:YES];
    
    if([self.managedEntity conformsToProtocol:@protocol(Mappable)]) {
        
        id <Mappable> mappable =  (id <Mappable>)self.managedEntity;
        
        NSNumber *lat = [NSNumber numberWithDouble:-360.0];
        NSNumber *lng = [NSNumber numberWithDouble:0.0];
        
        [mappable setLatitude:lat];
        [mappable setLongitude:lng];
        
    }
    
    [self saveEntity];
    
    NSString * s = @"";
    
    if (errorMsg) {
        s = errorMsg;
    }
    
	UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error" message:[NSString stringWithFormat:@"There was a problem while obtaining customer coordinates. %@", s] delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
	[alertView show];
	[alertView release];
}

-(void) geocoderFoundLocation:(CLLocation *)location
{
    [(RepWalletAppDelegate *)[[UIApplication sharedApplication] delegate] setNetworkActivityIndicatorVisible:NO force:NO];
    
    [self hideProgressHUD:YES];
    
    if([self.managedEntity conformsToProtocol:@protocol(Mappable)]) {
        
        id <Mappable> mappable =  (id <Mappable>)self.managedEntity;
        
        NSNumber *lat = [NSNumber numberWithDouble:location.coordinate.latitude];
        NSNumber *lng = [NSNumber numberWithDouble:location.coordinate.longitude];
        
        [mappable setLatitude:lat];
        [mappable setLongitude:lng];
        
        Firm *tmpFirm = [(Firm *)[NSManagedObject alloc] initWithEntity:[self.dao getEntityDescriptionForName:NSStringFromClass([Firm class])] insertIntoManagedObjectContext:nil];
        [tmpFirm setLatitude:lat];
        [tmpFirm setLongitude:lng];
        [tmpFirm setFirmName:[[self.cells objectForKey:@"firmName"] getControlValue]];
        [tmpFirm setStreet:[[self.cells objectForKey:@"street"] getControlValue]];
        [tmpFirm setTown:[[self.cells objectForKey:@"town"] getControlValue]];
        [tmpFirm setState:[[self.cells objectForKey:@"state"] getControlValue]];
        [tmpFirm setCountry:[[self.cells objectForKey:@"country"] getControlValue]];
        
        MapController *mapController = [[MapController alloc] initWithArray:[NSArray arrayWithObjects:tmpFirm, nil] andDao:self.dao isPreSave:YES centerLocation:location.coordinate zoomLvl:0.5 longPressureEnabled:NO];
        self.mapC = mapController;
        [mapController release];
        self.mapC.title = @"Map";
        self.mapC.delegate = self;
        
        [self.navigationItem.rightBarButtonItem setEnabled:YES];
        
        [self.navigationController pushViewController:mapController animated:YES];
        
        [tmpFirm release];
    }
}

#pragma mark -
#pragma mark Validation, Edit and Save

- (BOOL) checkMandatoryConstraints 
{
    for (int row = 0; row < [self.tableStructure count]; row++) {
        
        NSDictionary *cellData = [self.tableStructure objectAtIndex:row];
        
        NSString * mandatory = [cellData objectForKey:@"Mandatory"];
        
        NSString * dk = [cellData objectForKey:@"DataKey"];
        
        if([mandatory isEqualToString:@"Y"]) {
                       
            BaseDataEntryCell *cell = [self.cells objectForKey:dk];
            
            if (cell) {
                
                id v = [cell getControlValue];
                
//                NSLog(@"Checking cell with key: %@, value: %@, mandatory: %@", cell.dataKey, v, [cell isMandatory] ? @"Y" : @"N");
                
                if(v == nil && [cell isMandatory]) {
                    
                    return NO;
                    
                }
                
            } else {
                
//                NSLog(@"Cell with key %@ is mandatory and still not loaded", dk);
                
                // è disabilitabile?
                
                if([cellData objectForKey:@"DisablingCellDataKey"]
                   && [cellData objectForKey:@"DisablingValue"]) {
                    
//                    NSLog(@"entity is %@", self.managedEntity);
                    
                    NSString * disablingDK = [cellData objectForKey:@"DisablingCellDataKey"];
                    NSString * disablingValue = [cellData objectForKey:@"DisablingValue"];
                    
//                    NSLog(@"disabling entity value %@", [self.managedEntity valueForKey:disablingDK]);
                    
                    BaseDataEntryCell *cell = [self.cells objectForKey:disablingDK];
                    
                    if ((cell && [[cell getControlValue] isEqualToString:disablingValue])
                        || ([self.managedEntity valueForKey:disablingDK] && [[self.managedEntity valueForKey:disablingDK] isEqualToString:disablingValue])
                        ) {
                        
                        // la cella disabilitante è caricata e disabilita
                        // oppure il valore dell'entity disabilita,
                        // allora la cella è obbligatoria ma risulterebbe disabilitata
                    
                    } else if (![self.managedEntity valueForKey:dk]) {
                        
                        // se non si verifica cio', allora devo avere la cella caricata ...
                        // se il valore dell'entità non è presente
                        
//                        NSLog(@"not present either disabling cell or entity value");
                        return NO;
                    }
                    
                } else if(![self.managedEntity valueForKey:dk]) {
                    
                    // non è disabilitabile e non c'è un valore per l'entity
                    
//                    NSLog(@"not present disabling value and not present entity value");
                    
                    return NO;
                    
                }

            }
            
        } else {
            
//            NSLog(@"Cell with key %@ is not mandatory", [cellData objectForKey:@"DataKey"]);
            
        }
        
    }
    
    return YES;
}

- (BOOL) checkPKConstraints
{
//    NSLog(@"Checking PK fields... ");
    
    if ([self.managedEntity isMemberOfClass:([Firm class])]) {
        
        Firm *tmpFirm = [(Firm *)[[NSManagedObject alloc] initWithEntity:[self.dao getEntityDescriptionForName:NSStringFromClass([Firm class])] insertIntoManagedObjectContext:nil] autorelease];
        
        [tmpFirm setFirmName:[[self.cells objectForKey:@"firmName"] getControlValue]];
        
        BOOL editingModeCheck;
        
        if ([self.title isEqualToString:ADDEDITVIEWCONTROLLER_EDIT_MODE_TITLE]) {
            editingModeCheck = YES;
        } else {
            editingModeCheck = NO;
        }
        
        BOOL checkBool = [self.dao checkPrimaryKeyOfEntity:tmpFirm ofType:NSStringFromClass([Firm class]) testUsingFakeObj:editingModeCheck]; 
        
        return checkBool;
    }
    
    return YES;
}

- (BOOL) checkFieldValidationConstraints 
{    
//    NSLog(@"Validating fields... ");
    
    for (NSString* dk in self.cells) {
        if (![[self.cells objectForKey:dk] hasValidControlValue]) {
            return NO;
        }
    }
    
    return YES;
}

- (void) validateEntity 
{   
    [self.navigationItem.rightBarButtonItem setEnabled:NO];
    
    BOOL isDataValid = [self checkFieldValidationConstraints];
    
    if(!isDataValid) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Warning" message:@"Some values are not valid." delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
        [alertView show];
        [alertView release];
        [self.navigationItem.rightBarButtonItem setEnabled:YES];
        return;
    }
    
    BOOL isDataComplete = [self checkMandatoryConstraints];
    
    if(!isDataComplete) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Warning" message:@"Some mandatory values are missing." delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
        [alertView show];
        [alertView release];
        [self.navigationItem.rightBarButtonItem setEnabled:YES];
        return;
    }
    
    BOOL isEntityValid = [self checkPKConstraints];
    
    if(!isEntityValid) {
        
        NSString *pkField = @"";
        if([self.managedEntity isMemberOfClass: [Firm class]]) {
            pkField = @"Name";
        }
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Warning" message:[NSString stringWithFormat:@"The field '%@' must be unique.", pkField] delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
        [alertView show];
        [alertView release];
        [self.navigationItem.rightBarButtonItem setEnabled:YES];
        return;
    }
    
    if ([self hasConnectivity] && [self.managedEntity conformsToProtocol:@protocol(Mappable)]) {
        [self checkAddress]; 
        
    } else if (![self hasConnectivity] && [self.managedEntity conformsToProtocol:@protocol(Mappable)]) {
        [(id<Mappable>)self.managedEntity setLatitude:[NSNumber numberWithDouble:-360.0]]; 
        [(id<Mappable>)self.managedEntity setLongitude:[NSNumber numberWithDouble:0]];
        [self saveEntity]; 
        
    } else {
        [self saveEntity]; 
        
    }
}

- (void) modifyEntity 
{    
    for (NSString * dk in self.cells) {
        
        id cell = [self.cells objectForKey:dk];
        
        id v = [cell getControlValue];
            
        if (![cell isMemberOfClass:[DisclosureCell class]]) {
            [self setEntityProperty:dk value:v];
        }
    }
    
    for (NSString * dk in self.cacheDict) {
        
        id cell = [self.cells objectForKey:dk];
        
        if (!cell && ![cell isMemberOfClass:[DisclosureCell class]]) {
            [self setEntityProperty:dk value:[self.cacheDict objectForKey:dk]];
        }
        
    }
    
    if ([self.managedEntity isMemberOfClass:[Appointment class]]) {
        [self finalizeAppointment:(Appointment *)self.managedEntity];
    }
}

- (void) setEntityProperty:(NSString *)prop value:(id)v 
{    
    objc_property_t theProperty = class_getProperty([self.managedEntity class], [prop UTF8String]);
    
    const char * propertyAttrs = property_getAttributes(theProperty);
    
    if (propertyAttrs[0] == 'T' && propertyAttrs[1] == '@') {
        
        // it's another ObjC object type:
        NSString *propAttrStr = [NSString stringWithUTF8String:propertyAttrs];
        
        NSString *regEx = @"T@\"([A-Z0-9]+)\".*";
        
        NSError *error = NULL;
        
        NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:regEx options:NSRegularExpressionCaseInsensitive error:&error];
        
        if (!error) {
            NSString *propType = [regex stringByReplacingMatchesInString:propAttrStr options:0 range:NSMakeRange(0, [propAttrStr length]) withTemplate:@"$1"];
            
//            NSLog(@"proptype is %@", propType);
            
            if (!v && [propType isEqualToString:NSStringFromClass([NSNumber class])]) {
                v = [NSNumber numberWithInt:0];
            }
            
            [self.managedEntity setValue:(v && [v isMemberOfClass:[NSNull class]]) ? nil : v forKey:prop];
        }
    }
}
    
- (void) saveEntity
{    
//    NSLog(@"save entity");
    
    NSString *oldFirmTitle;
    NSString *newFirmTitle;
    
    [self.navigationItem.rightBarButtonItem setEnabled:NO];
    
    BOOL saveStats = NO;
    
    Class firmClass	= [Firm class]; 
    Class unpClass	= [UnpaidInvoice class];
    Class evtClass = [Event class];
    Class appClass = [Appointment class];
    
    if(![self.managedEntity isMemberOfClass: firmClass]
       && ![self.managedEntity isMemberOfClass: appClass])
        saveStats = YES;
    
    BOOL errorWithStats = NO;
    
    // Stats and context management

    if ([self.title isEqualToString:ADDEDITVIEWCONTROLLER_INSERT_MODE_TITLE] && saveStats) {
        
        // 1 - agganciare self.managedEntity al context
        // 2 - modificare con i nuovi valori self.managedEntity
        // 3 - inserire le statistiche (a causa del metodo setFirm in insertStatsForEntity le statistiche dovranno essere agganciate al contesto già in fase di creazione)
        
        // 1
        
        [self.dao.managedObjectContext insertObject:self.managedEntity];
        
        // 2
        
        [self modifyEntity];
        
        // 3
        
        NSMutableDictionary * dict = [self.dao insertStatsForEntity:self.managedEntity];
        int retCode = [(NSNumber *)[dict objectForKey:@"result"] intValue];
        
        // this could result in a new Statistic or in an update of the old one...
        
        if(retCode != 0 && retCode != 1) {
            
            errorWithStats = YES;
            
        } else {

            [self.dao saveContext];
            
        }
        
    } else if ([self.title isEqualToString:ADDEDITVIEWCONTROLLER_EDIT_MODE_TITLE] && saveStats) {
        
        // 1 - modificare con i nuovi valori self.managedEntity
        // 2 - agganciare self.statToRemove al context
        // 3 - impostare la Firm e la ItemCategory per self.statToRemove
        // 4 - fare un merge con le vecchie statistiche
        // 5 - inserire statistiche per l'entità aggiornata
        
        // 1
        
        [self modifyEntity];
        
        // 2
        
        [self.dao.managedObjectContext insertObject:self.statToRemove];
        
        // 3
        
        [self.statToRemove setFirm:[self.undoDict objectForKey:@"firm"]];
        
        [self.statToRemove setItemCategory:[self.undoDict objectForKey:@"itemCategory"]];
        
        // 4
        
        NSMutableDictionary * dict = [self.dao addOrUpdateStatistic:self.statToRemove];
        
        int retCode = [(NSNumber *)[dict objectForKey:@"result"] intValue];
        
//        NSLog(@"Updated the stats for the ORIGINAL entity, ret. code %i", retCode);
        
        if(retCode == 1) { // Update -> stats for the old entity version have been removed
            
            [self.dao saveContext];
            
            // intermediate save
            
            // 5
            
            dict = [self.dao insertStatsForEntity:self.managedEntity];
            
            retCode = [(NSNumber *)[dict objectForKey:@"result"] intValue];
            
//            NSLog(@"Inserted the stats for the MODIFIED entity, ret. code %i", retCode);
            
            // this could result in a new Statistic or in an update of the old one...
            
            if(retCode == 0 || retCode == 1){
                
                [self.dao saveContext]; // final save
                
            } else
                errorWithStats = YES;
            
        } else
            errorWithStats = YES;
        
    } else if ([self.title isEqualToString:ADDEDITVIEWCONTROLLER_EDIT_MODE_TITLE] && !saveStats) {
        
        if ([self.managedEntity isMemberOfClass:firmClass]) {
            oldFirmTitle = [(Firm *)self.managedEntity firmName];
        }

        [self modifyEntity];
        
        if ([self.managedEntity isMemberOfClass:firmClass]) {
            newFirmTitle = [(Firm *)self.managedEntity firmName];
        }
        
        [self.dao saveContext];
        
    } else if ([self.title isEqualToString:ADDEDITVIEWCONTROLLER_INSERT_MODE_TITLE] && !saveStats) {
        
        [self.dao.managedObjectContext insertObject:self.managedEntity];
        
        [self modifyEntity];

        [self.dao saveContext];
        
    } else
        ;
    
    if(errorWithStats) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error" message:@"There was a problem saving the statistics." delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
        [alertView show];
        [alertView release];
        [self.navigationItem.rightBarButtonItem setEnabled:YES];
        return;
    }
    
    if([self.managedEntity isMemberOfClass: firmClass]) {
        
        if ([self.title isEqualToString:ADDEDITVIEWCONTROLLER_EDIT_MODE_TITLE]) {
            
            [[NSNotificationCenter defaultCenter] 
             postNotificationName:ADDED_OR_EDITED_FIRM_NOTIFICATION 
             object:nil
             userInfo:[NSDictionary 
                       dictionaryWithObjectsAndKeys:
                       oldFirmTitle, @"oldTitle",
                       newFirmTitle, @"newTitle",
                       nil]];
            
        } else {
            
            [[NSNotificationCenter defaultCenter] 
             postNotificationName:ADDED_OR_EDITED_FIRM_NOTIFICATION 
             object:nil];

        }
        
        if (self.delegate && [self.delegate respondsToSelector:@selector(addEditViewControllerAsksDataReloadAndUpdateOfMapCenter:)]) {

            [self.delegate addEditViewControllerAsksDataReloadAndUpdateOfMapCenter:[[[CLLocation alloc] initWithLatitude:[[(Firm *)self.managedEntity latitude] doubleValue] longitude:[[(Firm *)self.managedEntity longitude] doubleValue]] autorelease]];
        }
        
        
    } else if([self.managedEntity isMemberOfClass: unpClass]) {

        [[NSNotificationCenter defaultCenter] 
         postNotificationName:ADDED_OR_EDITED_UNPAID_NOTIFICATION 
         object:nil]; 
        
        if(addAnotherOne) {

            [[NSNotificationCenter defaultCenter] 
             postNotificationName:ENABLE_INSERTION_OF_ANOTHER_UNPAID_NOTIFICATION 
             object:nil];
            
        } else
            
            [[NSNotificationCenter defaultCenter] 
             postNotificationName:DISABLE_INSERTION_OF_ANOTHER_UNPAID_NOTIFICATION 
             object:nil];
        
    } else if([self.managedEntity isMemberOfClass: evtClass]) {
        
        [[NSNotificationCenter defaultCenter] 
         postNotificationName:ADDED_OR_EDITED_EVENT_NOTIFICATION 
         object:nil];
        
        if(addAnotherOne) {
            
            [[NSNotificationCenter defaultCenter] 
             postNotificationName:ENABLE_INSERTION_OF_ANOTHER_EVENT_NOTIFICATION 
             object:nil];
        } else
            
            [[NSNotificationCenter defaultCenter] 
             postNotificationName:DISABLE_INSERTION_OF_ANOTHER_EVENT_NOTIFICATION 
             object:nil];
        
    }  else if([self.managedEntity isMemberOfClass: appClass]) {
        
        if ([self.title isEqualToString:ADDEDITVIEWCONTROLLER_INSERT_MODE_TITLE]) {
            
            [[NSNotificationCenter defaultCenter] 
             postNotificationName:ADDED_APPOINTMENT_NOTIFICATION 
             object:nil
             userInfo:[NSDictionary dictionaryWithObject:self.managedEntity forKey:@"value"]];
            
        } else {
            
            [[NSNotificationCenter defaultCenter] 
             postNotificationName:EDITED_APPOINTMENT_NOTIFICATION 
             object:nil
             userInfo:[NSDictionary dictionaryWithObject:self.managedEntity forKey:@"value"]];
            
        }
        
        if(addAnotherOne) {
            
            [[NSNotificationCenter defaultCenter] 
             postNotificationName:ENABLE_INSERTION_OF_ANOTHER_APPOINTMENT_NOTIFICATION 
             object:nil];
        } else
            
            [[NSNotificationCenter defaultCenter] 
             postNotificationName:DISABLE_INSERTION_OF_ANOTHER_APPOINTMENT_NOTIFICATION 
             object:nil];
        
    } else
        NSLog(@"Cannot determine entity type!");
    
    [self.navigationItem.rightBarButtonItem setEnabled:YES];
    
    [self viewControllerWillBePopped];
    
    [self.navigationController popViewControllerAnimated:YES];
   
}

- (void)mapControllerEndedEditingForObjectOfClass:(NSString *)clazz 
{
    if ([clazz isEqualToString:NSStringFromClass([self.managedEntity class])]) {
        [self saveEntity];
    }
}

# pragma mark -
# pragma mark Undo

- (void)mapControllerCanceledEditingForObjectOfClass:(NSString *)clazz
{ 
    if ([clazz isEqualToString:NSStringFromClass([self.managedEntity class])]) {
        [self undo];
    }
}

- (void) undo {
    
    //    NSLog(@"Undoing... ");
    
    for (id prop in self.undoDict) {
        id val = [self.undoDict objectForKey:prop];        
        [self setEntityProperty:prop value:val];
    }
    
    [self.navigationItem.rightBarButtonItem setEnabled:YES];
}

- (void) initDictFromEntity: (NSMutableDictionary *) dictio {
    
    [dictio removeAllObjects];
    
    for (int row = 0; row < [self.tableStructure count]; row++) {
        
        NSDictionary *cellData = [self.tableStructure objectAtIndex:row];
        NSString *dataKey = [cellData objectForKey:@"DataKey"];
        
//        NSLog(@"init dictionary with dataKey %@ value %@", dataKey, [self.managedEntity valueForKey:dataKey]);
        
        [dictio setObject:[self.managedEntity valueForKey:dataKey] ? [self.managedEntity valueForKey:dataKey] : [NSNull null] forKey:dataKey];
    }
    
    if([self.managedEntity conformsToProtocol:@protocol(Mappable)]) {
        
        id <Mappable> mappable =  (id <Mappable>)self.managedEntity;
        [dictio setObject:[mappable latitude] ? [mappable latitude] : [NSNull null] forKey:@"latitude"];
        [dictio setObject:[mappable longitude] ? [mappable longitude] : [NSNull null] forKey:@"longitude"];
    }
}


#pragma mark -
#pragma mark Geocoding

- (void) checkAddress 
{    
//    NSLog(@"checking address");
    
    NSString * newAddress = @"";
    NSString * newTown = @"";
    NSString * newZip = @"";
    NSString * newState = @"";
    NSString * newCountry = @"";
    
    NSString * newCountryISOCode = @"";
    
    // construct the geocode address

    for (int row = 0; row < [self.tableStructure count]; row++) {
        
        NSDictionary *cellData = [self.tableStructure objectAtIndex:row];
        NSString *dataKey = [cellData objectForKey:@"DataKey"];
        
        NSIndexPath* cellPath = [NSIndexPath indexPathForRow:row inSection:0];
        UITableViewCell* tcell = [self tableView:self.tableView cellForRowAtIndexPath:cellPath];
        BaseDataEntryCell *cell = (BaseDataEntryCell *)tcell;
        
        id v = nil;
        
        if(cell)
            v = [cell getControlValue];
        
        if([dataKey isEqualToString:@"street"] && v) {
            
            newAddress = [newAddress stringByAppendingString:v];
        
        } else if([dataKey isEqualToString:@"town"] && v) {
            
            newTown = [newTown stringByAppendingString:v];
        
        } else if([dataKey isEqualToString:@"zip"] && v) {
            
            newZip = [newZip stringByAppendingString:v];
        
        }  else if([dataKey isEqualToString:@"state"] && v) {
            
            newState = [newState stringByAppendingString:v];
            
        } else if([dataKey isEqualToString:@"country"] && v) {
            
            newCountry = [newCountry stringByAppendingString:v];
            newCountryISOCode  = [newCountryISOCode stringByAppendingString:[(CountrySelectionCell *)cell getISOCodeForControlValue]];
        } 
    }
    
    NSString * newFullAddr = [NSString stringWithFormat:@"%@ %@ %@ %@ %@", newAddress, newTown, newZip, newState, newCountry];

//        NSLog(@"newfulladdr %@", newFullAddr);
    
    NSString * oldAddress = @"";
    NSString * oldTown = @"";
    NSString * oldZip = @"";
    NSString * oldState = @"";
    NSString * oldCountry = @"";
    
    if (![[self.undoDict objectForKey:@"street"] isMemberOfClass:[NSNull class]]) {
        
        oldAddress = [oldAddress stringByAppendingString:[self.undoDict objectForKey:@"street"]];
    }
    
    if (![[self.undoDict objectForKey:@"town"] isMemberOfClass:[NSNull class]]) {
        
        oldTown = [oldTown stringByAppendingString:[self.undoDict objectForKey:@"town"]];
        
    }
    
    if (![[self.undoDict objectForKey:@"zip"] isMemberOfClass:[NSNull class]]) {
        
        oldZip = [oldZip stringByAppendingString:[self.undoDict objectForKey:@"zip"]];
        
    }
    
    if (![[self.undoDict objectForKey:@"state"] isMemberOfClass:[NSNull class]]) {
        
        oldState = [oldState stringByAppendingString:[self.undoDict objectForKey:@"state"]];
        
    }
    
    if (![[self.undoDict objectForKey:@"country"] isMemberOfClass:[NSNull class]]) {
        
        oldCountry = [oldCountry stringByAppendingString:[self.undoDict objectForKey:@"country"]];
        
    }
    
    NSString * oldFullAddr = [NSString stringWithFormat:@"%@ %@ %@ %@ %@", oldAddress, oldTown, oldZip, oldState, oldCountry];
    
//        NSLog(@"oldfulladdr %@", oldFullAddr);
    
    double entityLat = [[(id<Mappable>)self.managedEntity latitude] doubleValue];
    double entityLng = [[(id<Mappable>)self.managedEntity longitude] doubleValue];
    
    if (!CLLocationCoordinate2DIsValid(CLLocationCoordinate2DMake(entityLat, entityLng)) 
        || ![newFullAddr isEqualToString:oldFullAddr]) {
        
        [(RepWalletAppDelegate *)[[UIApplication sharedApplication] delegate] setNetworkActivityIndicatorVisible:YES force:NO];

        [self showProgressHUDWithMessage:@"Loading"];

        [self.geocoderV2 startGeocodingWithAddress:newAddress locality:newTown ZIP:newZip adminDistrict:newState countryCode:newCountryISOCode];
        
    } else {
        
        [self saveEntity];
        
    }
}

- (void) mapControllerUpdatedLocation:(CLLocation *)location forObjectOfClass:(NSString *)clazz
{
    if ([clazz isEqualToString:NSStringFromClass([self.managedEntity class])]) {
            
        //    NSLog(@"update of lat %@", [[notification userInfo] objectForKey:@"latitude"]);
        //    NSLog(@"update of lng %@", [[notification userInfo] objectForKey:@"longitude"]);
        
        if([self.managedEntity conformsToProtocol:@protocol(Mappable)]) {
            
            id <Mappable> mappable =  (id <Mappable>)self.managedEntity;
            
            [mappable setLatitude:[NSNumber numberWithDouble:location.coordinate.latitude]];
            [mappable setLongitude:[NSNumber numberWithDouble:location.coordinate.longitude]];

        }
    }
}


#pragma mark -
#pragma mark View lifecycle

- (void) showTabBar:(UITabBarController *) tabbarcontroller 
{   
    CGRect screenRect = [[UIScreen mainScreen] bounds];
    float fHeight = screenRect.size.height - self.tabBarController.tabBar.frame.size.height;
    
    if(  UIDeviceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation) )
    {
        fHeight = screenRect.size.width - self.tabBarController.tabBar.frame.size.height;
    }
    
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:0.2];
    for(UIView *view in tabbarcontroller.view.subviews)
    {
        if([view isKindOfClass:[UITabBar class]])
        {
            [view setFrame:CGRectMake(view.frame.origin.x, fHeight, view.frame.size.width, view.frame.size.height)];            
        } 
        else 
        {
            [view setFrame:CGRectMake(view.frame.origin.x, view.frame.origin.y, view.frame.size.width, fHeight)];
        }       
    }
    
    [UIView commitAnimations]; 
}

-(void)viewDidAppear:(BOOL)animated {
   
    [super viewDidAppear:animated];
    [self.navigationController setToolbarHidden:YES animated:animated];
    [self showTabBar:self.tabBarController];
    if([self.managedEntity isMemberOfClass:[Firm class]]) {
        [UIAccelerometer sharedAccelerometer].delegate = self;
    }
}

-(void)viewWillAppear:(BOOL)animated {

    [super viewWillAppear:animated];
    
    [[NSNotificationCenter defaultCenter]
     addObserver:self
     selector:@selector(cellHasBeenEdited:)
     name:CELL_ENDEDIT_NOTIFICATION_NAME
     object:nil];
    
    if (viewDidDisappear
        && self.interfaceOrientation != lastOrientation) {
        
        int rowHeight, headerHeight, footerHeight;
        
        if([(RepWalletAppDelegate *)[[UIApplication sharedApplication] delegate] isIpad]) {
            rowHeight = 120;
            headerHeight = 156;
            footerHeight = 156;
        }
        
        else {
            rowHeight = 50;
            headerHeight = 65;
            footerHeight = 65;
        }
        
        [self customizeTableViewDrawingWithHeader:nil headerBg:@"bgHeader" footer:nil footerBg:@"bgFooter" background:nil backgroundColor:[UIColor whiteColor] rowHeight:rowHeight headerHeight:headerHeight footerHeight:footerHeight deviceOrientationIsPortrait:UIDeviceOrientationIsPortrait(self.interfaceOrientation)];

        self.firstVisibleIndexPath = nil;
        
        self.lastVisibleIndexPath = nil;
        
        [self.tableView reloadData];
        
    }
}

-(void)viewWillDisappear:(BOOL)animated {
    
    NSArray *viewControllers = self.navigationController.viewControllers;
    
    if (viewControllers.count > 1 && [viewControllers objectAtIndex:viewControllers.count-2] == self) {
        // View is disappearing because a new view controller was pushed onto the stack
    } else if ([viewControllers indexOfObject:self] == NSNotFound) {
        // View is disappearing because it was popped from the stack
//        NSLog(@"View controller was popped");
        [self viewControllerWillBePopped];
    }
    
    [[NSNotificationCenter defaultCenter] 
     removeObserver:self 
     name:CELL_ENDEDIT_NOTIFICATION_NAME 
     object:nil];
    
    if([UIAccelerometer sharedAccelerometer].delegate) {
        [UIAccelerometer sharedAccelerometer].delegate = nil;
    }

    [super viewWillDisappear:animated];
    
}


-(void)viewDidDisappear:(BOOL)animated {
    
    viewDidDisappear = YES;
    
    [super viewDidDisappear:animated];
}


- (void) viewDidLoad {
    
//    NSLog(@"viewDidLoad for addeditVC %@", self);
    
    [super viewDidLoad];
    
    self.firstVisibleIndexPath = nil;
    
    self.lastVisibleIndexPath = nil;

    self.cells = [NSMutableDictionary dictionary];
    
    self.undoDict = [NSMutableDictionary dictionary];
    
    // set table structure
    
    [self initTableStructure];
    
    // set values for undoing
    
    [self initDictFromEntity:self.undoDict];
    
    // init geocoder
    
    FwdGeocoder * geo = [[FwdGeocoder alloc] init];
    
    self.geocoderV2 = geo;
    
    [geo release];
    
    self.geocoderV2.delegate = self;
    
    // in case of editing
    
    if ([self.title isEqualToString:ADDEDITVIEWCONTROLLER_EDIT_MODE_TITLE]) {
        
        // set values for stats update
        
        self.statToRemove = [self.dao insertStatsToRemoveForEntity:self.managedEntity];
        
        // save the id
        
        [self openedEntity];
        
    }

    UIBarButtonItem *btn = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(validateEntity)]; 
    
    self.navigationItem.rightBarButtonItem = btn;
    
    [btn release];
    
    btn = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(getBack)];
    
    self.navigationItem.leftBarButtonItem = btn;
    
    [btn release];
    
    int rowHeight, headerHeight, footerHeight;
    
    if([(RepWalletAppDelegate *)[[UIApplication sharedApplication] delegate] isIpad]) {
        rowHeight = 120;
        headerHeight = 156;
        footerHeight = 156;
    }
        
    else {
        rowHeight = 50;
        headerHeight = 65;
        footerHeight = 65;
    }
        
    
    [self customizeTableViewDrawingWithHeader:nil headerBg:@"bgHeader" footer:nil footerBg:@"bgFooter" background:nil backgroundColor:[UIColor whiteColor] rowHeight:rowHeight headerHeight:headerHeight footerHeight:footerHeight deviceOrientationIsPortrait:UIDeviceOrientationIsPortrait(self.interfaceOrientation)];
    
    [self createProgressHUDForView:self.tableView];
    
}

#pragma mark -
#pragma mark Cell notification

- (void) cellHasBeenEdited:(NSNotification *) notification 
{
//    NSLog(@"inserted value %@", (NSString *)[[notification userInfo] objectForKey:@"value"]);
    
    BaseDataEntryCell * cell = [[notification userInfo] objectForKey:@"value"];
    
    if([[self.tableView indexPathForCell:cell] row] == [self.tableStructure count]) {
    
        if ([cell getControlValue] && [@"YES" isEqualToString:[cell getControlValue]]) {
            
            addAnotherOne = YES;
        
        } else {
            
            addAnotherOne = NO;

        }
    }
}

- (void) checkDisclosureCellNotification:(NSNotification *)notification 
{
    if ([[notification name] isEqualToString:SHOW_EVENTS_FOR_FIRM]) {
        [self showEventsForFirm:(Firm *)self.managedEntity];
    } else if ([[notification name] isEqualToString:SHOW_UNPAIDS_FOR_FIRM]) {
        [self showUnpaidsForFirm:(Firm *)self.managedEntity];
    }  else if ([[notification name] isEqualToString:SHOW_APPOINTMENTS_FOR_FIRM]) {
        [self showAppointmentsForFirm:(Firm *)self.managedEntity];
    } else {
        ;
    }
}

- (void) showEventsForFirm:(Firm *)firm 
{
    EventForFirmViewController *viewController = [[EventForFirmViewController alloc] initWithStyle:UITableViewStylePlain firm:firm andDao:self.dao];
    viewController.title = [NSString stringWithFormat:@"Events - %@", firm.firmName];
    [self.navigationController pushViewController:viewController animated:YES];
    [viewController release];
}

- (void) showUnpaidsForFirm:(Firm *)firm 
{
    UnpaidForFirmViewController *viewController = [[UnpaidForFirmViewController alloc] initWithStyle:UITableViewStylePlain firm:firm andDao:self.dao];
    viewController.title = [NSString stringWithFormat:@"Unpaid Invoices - %@", firm.firmName];
    [self.navigationController pushViewController:viewController animated:YES];
    [viewController release];
}

- (void) showAppointmentsForFirm:(Firm *)firm 
{
    AppointmentForFirmViewController *viewController = [[AppointmentForFirmViewController alloc] initWithStyle:UITableViewStylePlain firm:firm andDao:self.dao];
    viewController.title = [NSString stringWithFormat:@"Appointments - %@", firm.firmName];
    [self.navigationController pushViewController:viewController animated:YES];
    [viewController release];
}

#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView 
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section 
{
    Class firmClass	= [Firm class]; 
    Class unpClass	= [UnpaidInvoice class];
    Class evtClass = [Event class];
    Class appClass = [Appointment class];
    
    if([self.managedEntity isMemberOfClass: firmClass]) {
        return [self.tableStructure count];   
    } 
    else if([self.managedEntity isMemberOfClass: unpClass] && [self.title isEqualToString:ADDEDITVIEWCONTROLLER_INSERT_MODE_TITLE]) {
        return [self.tableStructure count] + 1;   
    } 
    else if([self.managedEntity isMemberOfClass: unpClass] && [self.title isEqualToString:ADDEDITVIEWCONTROLLER_EDIT_MODE_TITLE]) {
        return [self.tableStructure count];   
    } 
    else if([self.managedEntity isMemberOfClass: evtClass] && [self.title isEqualToString:ADDEDITVIEWCONTROLLER_INSERT_MODE_TITLE]) {
        return [self.tableStructure count] + 1;   
    } 
    else if([self.managedEntity isMemberOfClass: evtClass] && [self.title isEqualToString:ADDEDITVIEWCONTROLLER_EDIT_MODE_TITLE]) {
        return [self.tableStructure count];   
    } 
    else if([self.managedEntity isMemberOfClass: appClass] && [self.title isEqualToString:ADDEDITVIEWCONTROLLER_INSERT_MODE_TITLE]) {
        return [self.tableStructure count] + 1;   
    } 
    else if([self.managedEntity isMemberOfClass: appClass] && [self.title isEqualToString:ADDEDITVIEWCONTROLLER_EDIT_MODE_TITLE]) {
        return [self.tableStructure count];   
    } 
    else
        ;
    
    return [self.tableStructure count];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath 
{ 
    BOOL dequeued = NO;
    
    NSString * className = NSStringFromClass([self.managedEntity class]);
    
    if(indexPath.row == [self.tableStructure count]) {
        
        NSString *cellId = [NSString stringWithFormat:@"%@%@", className, NSStringFromClass([SwitchCell class])];
        
        SwitchCell * oneMoreSwitchCell = (SwitchCell *)[tableView dequeueReusableCellWithIdentifier:cellId];
        
        if (oneMoreSwitchCell != nil) {
            
            dequeued = YES;
            
        } else {
            
            oneMoreSwitchCell  = [[[SwitchCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellId leftText:@"YES" rightText:@"NO" boundClassName:className dataKey:nil label:@"Add Another?"] autorelease];
            [[oneMoreSwitchCell switchField] setOn:addAnotherOne];
        }
        
        [self customizeDrawingForFormCell:oneMoreSwitchCell dequeued:dequeued deviceOrientationIsPortrait:UIDeviceOrientationIsPortrait(self.interfaceOrientation)];
        
        return oneMoreSwitchCell;
        
    } else {
        
        // dynamically clear background for less memory footprint
        
        NSArray *visibleIPath = [[tableView indexPathsForVisibleRows] sortedArrayUsingSelector:@selector(compare:)];
        
        if(self.lastVisibleIndexPath
           && ![visibleIPath containsObject:self.lastVisibleIndexPath]
           ) {
            
            NSInteger row = self.lastVisibleIndexPath.row;
            
            if(row < self.tableStructure.count) {
                
                [[self.cells objectForKey:
                  [[self.tableStructure objectAtIndex:row] objectForKey:@"DataKey"]]
                 setBackgroundView:nil];
                
            }
            
        } else if(self.firstVisibleIndexPath
            && ![visibleIPath containsObject:self.firstVisibleIndexPath]
            ) {
                
                NSInteger row = self.firstVisibleIndexPath.row;
                
                if(row < self.tableStructure.count) {
                    
                    [[self.cells objectForKey:
                      [[self.tableStructure objectAtIndex:row] objectForKey:@"DataKey"]]
                     setBackgroundView:nil];

                }
        }
        
        self.firstVisibleIndexPath = [visibleIPath objectAtIndex:0];
        self.lastVisibleIndexPath = [visibleIPath lastObject];
        
        NSDictionary *cellData = [self.tableStructure objectAtIndex:indexPath.row];
        
        NSString *dataKey = [cellData objectForKey:@"DataKey"];
        NSString *cellType = [cellData objectForKey:@"CellType"];
        
//        NSLog(@"getting cell for data key: %@ ... ", dataKey);
        
        BaseDataEntryCell *cell = (BaseDataEntryCell *)[self.cells objectForKey:dataKey];
        
        if (cell != nil) {
            
            dequeued = YES;
            
//            NSLog(@"... returning cell with address <%x>", cell);
            
            [self customizeDrawingForFormCell:cell dequeued:dequeued deviceOrientationIsPortrait:UIDeviceOrientationIsPortrait(self.interfaceOrientation)];
            
            return cell;
            
        } else if ([cellType isEqualToString:NSStringFromClass([ItemCategorySuggestionCell class])] || [cellType isEqualToString:NSStringFromClass([BusinessCategorySuggestionCell class])]) {
            
            cell = [[[NSClassFromString(cellType) alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil boundClassName:className dataKey:dataKey label:[cellData objectForKey:@"Label"] dao:self.dao] autorelease];
            
        } else if ([cellType isEqualToString:NSStringFromClass([FirmSelectionCell class])]) {
            
            cell = [[[NSClassFromString(cellType) alloc] initWithStyle:UITableViewCellStyleDefault dao:self.dao reuseIdentifier:nil boundClassName:className dataKey:dataKey label:[cellData objectForKey:@"Label"]] autorelease];
            
        } else if ([cellType isEqualToString:NSStringFromClass([PhotoPickerCell class])]
                   || [cellType isEqualToString:NSStringFromClass([DocumentPickerCell class])]) {
            
            cell = [[[NSClassFromString(cellType) alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil boundClassName:className dataKey:dataKey label:[cellData objectForKey:@"Label"] dao:self.dao] autorelease];
            
        } else if ([cellType isEqualToString:NSStringFromClass([SwitchCell class])]) {
            
            cell = [[[NSClassFromString(cellType) alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil leftText:[cellData objectForKey:@"LeftValue"] rightText:[cellData objectForKey:@"RightValue"] boundClassName:className dataKey:dataKey label:[cellData objectForKey:@"Label"]] autorelease];
            
        } else if ([cellType isEqualToString:NSStringFromClass([LabeledStringSelectionCell class])]
                   || [cellType isEqualToString:NSStringFromClass([StringSelectionCell class])]) {
            
            NSArray *dataSourceArray = [cellData objectForKey:@"DataSource"];
            
            cell = [[[NSClassFromString(cellType) alloc] initWithStyle:UITableViewCellStyleDefault dataSource:dataSourceArray reuseIdentifier:nil boundClassName:className dataKey:dataKey label:[cellData objectForKey:@"Label"]] autorelease];
            
        } else if ([cellType isEqualToString:NSStringFromClass([DatePickerCell class])]) {
            
            UIDatePickerMode mode;
            
            NSString *dateMode = [cellData objectForKey:@"DateMode"];
            
            if (dateMode && [dateMode isEqualToString:@"dateTime"]) {
                mode = UIDatePickerModeDateAndTime;
            } else {
                mode = UIDatePickerModeDate;
            }
            
            cell = [[[NSClassFromString(cellType) alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil datePickerMode:mode boundClassName:className dataKey:dataKey label:[cellData objectForKey:@"Label"]] autorelease];
            
        } else if ([cellType isEqualToString:NSStringFromClass([DisclosureCell class])] && [self.title isEqualToString:ADDEDITVIEWCONTROLLER_EDIT_MODE_TITLE]) {

            cell = [[[NSClassFromString(cellType) alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil notificationName:[cellData objectForKey:@"NotificationName"] boundClassName:className dataKey:dataKey label:[cellData objectForKey:@"Label"]] autorelease];
            
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(checkDisclosureCellNotification:) name:[cellData objectForKey:@"NotificationName"] object:nil];
            
        } else if ([cellType isEqualToString:NSStringFromClass([DisclosureCell class])] && [self.title isEqualToString:ADDEDITVIEWCONTROLLER_INSERT_MODE_TITLE]) {
            
            cell = [[[NSClassFromString(cellType) alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil notificationName:[cellData objectForKey:@"NotificationName"] boundClassName:className dataKey:dataKey label:[cellData objectForKey:@"Label"]] autorelease];
            
            [cell setEnabled: NO];
            
        } else {
            
            cell = [[[NSClassFromString(cellType) alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil boundClassName:className dataKey:dataKey label:[cellData objectForKey:@"Label"]] autorelease];
        }
        
//        NSLog(@"... created a new cell with address <%x> for datakey %@", cell, dataKey);
        
        NSString * mandatory = [cellData objectForKey:@"Mandatory"];
        
        if([mandatory isEqualToString:@"Y"]) {
            
            [cell changeMandatoryStatusTo:YES];
            
        } else {
            
            [cell changeMandatoryStatusTo:NO];
            
        }
        
        id val = [self.cacheDict objectForKey:dataKey] ? [self.cacheDict objectForKey:dataKey] : [self.undoDict objectForKey:dataKey];
        
//        NSLog(@"... setting control value to %@", val);
        
        if([val isMemberOfClass:[NSNull class]]) 
            
            [cell setControlValue:nil]; 
        
        else
            
            [cell setControlValue:val];
        
        if ([cellType isEqualToString:NSStringFromClass([DatePickerCell class])]) {
            
            if([cellData objectForKey:@"After"]) {
                
                NSString * dk = [cellData objectForKey:@"After"];
                NSString * controlMode = @"After";
                
                [cell setConnectedDatePickerWithDK:dk controlMode:controlMode]; 
                
            } else if([cellData objectForKey:@"Before"]) {
                
                NSString * dk = [cellData objectForKey:@"Before"];
                NSString * controlMode = @"Before";
                
                [cell setConnectedDatePickerWithDK:dk controlMode:controlMode];
                
            } else
                ;
        }

        // è una cella disabilitabile?
        if([cellData objectForKey:@"DisablingCellDataKey"]
           && [cellData objectForKey:@"DisablingValue"]) {
            
            NSString * disablingDK = [cellData objectForKey:@"DisablingCellDataKey"];
            NSString * disablingValue = [cellData objectForKey:@"DisablingValue"];
            
            [cell setDisablingDK:disablingDK forValue:disablingValue];
            
            id val = nil;
            
            if ([self.cells objectForKey:disablingDK]) {
                
                val = [[self.cells objectForKey:disablingDK] getControlValue];
                
            } else if([self.cacheDict objectForKey:disablingDK]) {
                
                val = [self.cacheDict objectForKey:disablingDK];
                
            } else if([self.undoDict objectForKey:disablingDK]) {
                
                val = [self.undoDict objectForKey:disablingDK];
                
            } 
            
            if (val && ![val isMemberOfClass:[NSNull class]] && [val isEqualToString:disablingValue]) {
                [cell setEnabled:NO];
            }
        }
        
        [self.cells setObject:cell forKey:dataKey];
        
        [self customizeDrawingForFormCell:cell dequeued:dequeued deviceOrientationIsPortrait:UIDeviceOrientationIsPortrait(self.interfaceOrientation)];

        return cell;
    }
}

- (TextCell *) prevTextCellForIndexpath:(NSIndexPath *)indexPath {
    
    int i = 1;
    
    TextCell *textCell = nil;
    
    NSIndexPath * ip;
    
    while (YES) {
        
        if (indexPath.row - i < 0) {
            break;
        }
        
        ip = [NSIndexPath indexPathForRow:indexPath.row - i inSection:indexPath.section];
        
        id cell = [self tableView:self.tableView cellForRowAtIndexPath:ip];
        
        if ([(BaseDataEntryCell *)cell enabledCell]
            && [cell isKindOfClass:([TextCell class])] 
            && ![cell isMemberOfClass:([BusinessCategorySuggestionCell class])]
            && ![cell isMemberOfClass:([ItemCategorySuggestionCell class])]) {
            textCell = cell;
            break;
        }
        
        i += 1;
    }
    
    if (textCell) {
        [self.tableView scrollToRowAtIndexPath:ip atScrollPosition:UITableViewScrollPositionTop animated:YES];
    }
    
    return textCell;
}

- (TextCell *) nextTextCellForIndexpath:(NSIndexPath *)indexPath {
    
    int i = 1;
    
    TextCell *textCell = nil;
    
    NSIndexPath * ip;
    
    while (YES) {
        
        if (indexPath.row + i > [self tableView:self.tableView numberOfRowsInSection:indexPath.section] - 1) {
            break;
        }
        
        ip = [NSIndexPath indexPathForRow:indexPath.row + i inSection:indexPath.section];
        
        id cell = [self tableView:self.tableView cellForRowAtIndexPath:ip];
        
        if ([(BaseDataEntryCell *)cell enabledCell]
            && [cell isKindOfClass:([TextCell class])] 
            && ![cell isMemberOfClass:([BusinessCategorySuggestionCell class])]
            && ![cell isMemberOfClass:([ItemCategorySuggestionCell class])]) {
            textCell = cell;
            break;
        }
        
        i += 1;
        
    }
    
    if (textCell) {
        [self.tableView scrollToRowAtIndexPath:ip atScrollPosition:UITableViewScrollPositionBottom animated:YES];
    }
    
    return textCell;
}


#pragma mark -
#pragma mark Memory management

- (void)didReceiveMemoryWarning {
    
//    NSLog(@"didReceiveMemoryWarning for addeditVC %@", self);
    
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // only want to do this on iOS 6
    if ([[[UIDevice currentDevice] systemVersion] compare:@"6.0" options:NSNumericSearch] != NSOrderedAscending) {
        //  Don't want to rehydrate the view if it's already unloaded
        BOOL isLoaded = [self isViewLoaded];
        
        //  We check the window property to make sure that the view is not visible
        if (isLoaded && self.view.window == nil) {
            
            //  Give a chance to implementors to get model data from their views
            [self performSelectorOnMainThread:@selector(viewWillUnload)
                                   withObject:nil
                                waitUntilDone:YES];
            
            //  Detach it from its parent (in cases of view controller containment)
            [self.view removeFromSuperview];
            self.view = nil;    //  Clear out the view.  Goodbye!
            
            //  The view is now unloaded...now call viewDidUnload
            [self performSelectorOnMainThread:@selector(viewDidUnload)
                                   withObject:nil
                                waitUntilDone:YES];
        }
    }
}

- (void)viewDidUnload {
    
//    NSLog(@"viewDidUnload for addeditVC %@", self);
    
    if (self.mapC) {
        self.mapC.delegate = nil;
    }
    
    if (self.geocoderV2) {
        self.geocoderV2.delegate = nil;
    }
    
    // save modified props into the cache
    
    [self.cacheDict removeAllObjects];
    
    for (int row = 0; row < [self.tableStructure count]; row++) {
        
        NSDictionary *cellData = [self.tableStructure objectAtIndex:row];
        NSString *dataKey = [cellData objectForKey:@"DataKey"];
        
        BaseDataEntryCell *cell = [self.cells objectForKey:dataKey];
        
        id val = [cell getControlValue] ? [cell getControlValue] : [NSNull null];
        
        id undoVal = [self.undoDict objectForKey:dataKey];
        
        if (![undoVal isMemberOfClass:[NSNull class]]
            && ![val isMemberOfClass:[NSNull class]]
            && ![undoVal isEqual:val]
            && ![cell isMemberOfClass:[DisclosureCell class]]
            ) 
        {
//            NSLog(@"cache: setting object %@ for datakey %@", val, dataKey);
            
            [self.cacheDict setObject:val forKey:dataKey];
        }
        
        else if (((![undoVal isMemberOfClass:[NSNull class]]
                 && [val isMemberOfClass:[NSNull class]])
                 ||
                 ([undoVal isMemberOfClass:[NSNull class]]
                  && ![val isMemberOfClass:[NSNull class]]))
                 && ![cell isMemberOfClass:[DisclosureCell class]]
                 ) 
        {
//            NSLog(@"cache: setting object %@ for datakey %@", val, dataKey);
            
            [self.cacheDict setObject:val forKey:dataKey];
        }
        
    }
    
    self.progressHUD = nil;
    self.mapC = nil;
    self.cells = nil;
    self.undoDict = nil;
    self.tableStructure = nil;
    self.statToRemove = nil;
    self.geocoderV2 = nil;
    
    [super viewDidUnload];
}


- (void)dealloc {

//    NSLog(@"dealloc for addeditVC %@", self);
    
    [openedFirmIDs release];
    if (openedFirmIDs.retainCount == 1) {
        [openedFirmIDs release];
        openedFirmIDs = nil;
    }
    
    [openedEventIDs release];
    if (openedEventIDs.retainCount == 1) {
        [openedEventIDs release];
        openedEventIDs = nil;
    }
    
    [openedUnpaidInvoiceIDs release];
    if (openedUnpaidInvoiceIDs.retainCount == 1) {
        [openedUnpaidInvoiceIDs release];
        openedUnpaidInvoiceIDs = nil;
    }
    
    [openedAppointmentIDs release];
    if (openedAppointmentIDs.retainCount == 1) {
        [openedAppointmentIDs release];
        openedAppointmentIDs = nil;
    }
    
    if (self.mapC) {
        self.mapC.delegate = nil;
    }
    
    if (self.geocoderV2) {
        self.geocoderV2.delegate = nil;
    }
    
    [[NSNotificationCenter defaultCenter] removeObserver:self]; 
    
    [self.lastVisibleIndexPath release];
    [self.firstVisibleIndexPath release];
    [self.cacheDict release];
    [self.mapC release];
    [self.lastAcceleration release];
    [self.progressHUD release];
    [self.cells release];
    [self.undoDict release];
    [self.tableStructure release];
    [self.managedEntity release];
    [self.dao release];
    [self.statToRemove release];
    [self.geocoderV2 release];
    [super dealloc];
}


@end
