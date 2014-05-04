//
//  AddEditViewController.h
//  repWallet
//
//  Created by Alberto Fiore on 1/31/12.
//  Copyright 2012 Alberto Fiore. All rights reserved.
//

#define DRAGGING_STARTED_NOTIFICATION @"draggingStarted"

#define ADDED_OR_EDITED_FIRM_NOTIFICATION @"addedOrEditedFirm"
#define ADDED_OR_EDITED_EVENT_NOTIFICATION @"addedOrEditedEvent"
#define ADDED_OR_EDITED_UNPAID_NOTIFICATION @"addedOrEditedUnpaid"
#define ADDED_APPOINTMENT_NOTIFICATION @"addedAppointment"
#define EDITED_APPOINTMENT_NOTIFICATION @"editedAppointment"

#define ENABLE_INSERTION_OF_ANOTHER_UNPAID_NOTIFICATION @"newUnpaidEnable"
#define DISABLE_INSERTION_OF_ANOTHER_UNPAID_NOTIFICATION @"newUnpaidDisable"
#define ENABLE_INSERTION_OF_ANOTHER_EVENT_NOTIFICATION @"newEventEnable"
#define DISABLE_INSERTION_OF_ANOTHER_EVENT_NOTIFICATION @"newEventDisable"
#define ENABLE_INSERTION_OF_ANOTHER_APPOINTMENT_NOTIFICATION @"newAppointmentEnable"
#define DISABLE_INSERTION_OF_ANOTHER_APPOINTMENT_NOTIFICATION @"newAppointmentDisable"

#define SHOW_APPOINTMENTS_FOR_FIRM @"showAppointmentsForFirm"
#define SHOW_EVENTS_FOR_FIRM @"showEventsForFirm"
#define SHOW_UNPAIDS_FOR_FIRM @"showUnpaidsForFirm"

#define ADDEDITVIEWCONTROLLER_INSERT_MODE_TITLE @"Insert"
#define ADDEDITVIEWCONTROLLER_EDIT_MODE_TITLE @"Modify"

#define SMS_ACTION_SHEET_BTN_PREFIX @"SMS: "
#define EMAIL_ACTION_SHEET_BTN_PREFIX @"e-mail: "
#define PHONE_ACTION_SHEET_BTN_PREFIX @"call: "

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>
#import "DAO.h"
#import "AddEditViewControllerDelegate.h"
#import "Firm.h"
#import "TextCell.h"


@interface AddEditViewController : UITableViewController
{
    BOOL viewDidDisappear;
    UIInterfaceOrientation lastOrientation;
}

@property (nonatomic, assign) id<AddEditViewControllerDelegate> delegate;

- (BOOL) isInEditingMode;
- (void) closedEntity;

+ (BOOL)isEditingFirmWithID:(NSManagedObjectID *)objID;
+ (BOOL)isEditingEventWithID:(NSManagedObjectID *)objID;
+ (BOOL)isEditingUnpaidInvoiceWithID:(NSManagedObjectID *)objID;
+ (BOOL)isEditingAppointmentWithID:(NSManagedObjectID *)objID;

- (id) initWithStyle:(UITableViewStyle)style title:(NSString *)aTitle entity:(NSManagedObject *)anEntity andDao:(DAO *)dao;
- (id) initWithStyle:(UITableViewStyle)style title:(NSString *)aTitle entity:(NSManagedObject *)anEntity andDao:(DAO *)aDao addAnotherOne:(BOOL)haveToAddAnotherOne;

- (TextCell *) prevTextCellForIndexpath:(NSIndexPath *)indexPath;
- (TextCell *) nextTextCellForIndexpath:(NSIndexPath *)indexPath;

@end
