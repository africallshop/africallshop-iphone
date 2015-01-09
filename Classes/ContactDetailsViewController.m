/* ContactDetailsViewController.m
 *
 * Copyright (C) 2012  Belledonne Comunications, Grenoble, France
 *
 *  This program is free software; you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation; either version 2 of the License, or   
 *  (at your option) any later version.                                 
 *                                                                      
 *  This program is distributed in the hope that it will be useful,     
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of      
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the       
 *  GNU General Public License for more details.                
 *                                                                      
 *  You should have received a copy of the GNU General Public License   
 *  along with this program; if not, write to the Free Software         
 *  Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
 */              

#import "ContactDetailsViewController.h"
#import "PhoneMainView.h"

@implementation ContactDetailsViewController

@synthesize tableController;
@synthesize contact;
@synthesize editButton;
@synthesize backButton;
@synthesize cancelButton;


static void sync_address_book (ABAddressBookRef addressBook, CFDictionaryRef info, void *context);

#pragma mark - Lifecycle Functions

- (id)init  {
    self = [super initWithNibName:@"ContactDetailsViewController" bundle:[NSBundle mainBundle]];
    if(self != nil) {
        inhibUpdate = FALSE;
        addressBook = ABAddressBookCreate();
        ABAddressBookRegisterExternalChangeCallback(addressBook, sync_address_book, self);
    }
    return self;
}

- (void)dealloc {
    ABAddressBookUnregisterExternalChangeCallback(addressBook, sync_address_book, self);
    CFRelease(addressBook);
    [tableController release];
    
    [editButton release];
    [backButton release];
    [cancelButton release];
    
    [super dealloc];
}


#pragma mark - 

- (void)resetData {
    [self disableEdit:FALSE];
    if(contact == NULL) {
        ABAddressBookRevert(addressBook);
        return;
    }
    
    [LinphoneLogger logc:LinphoneLoggerLog format:"Reset data to contact %p", contact];
    ABRecordID recordID = ABRecordGetRecordID(contact);
    ABAddressBookRevert(addressBook);
    contact = ABAddressBookGetPersonWithRecordID(addressBook, recordID);
    if(contact == NULL) {
        [[PhoneMainView instance] popCurrentView];
        return;
    }
    [tableController setContact:contact];
}

static void sync_address_book (ABAddressBookRef addressBook, CFDictionaryRef info, void *context) {
    ContactDetailsViewController* controller = (ContactDetailsViewController*)context;
    if(!controller->inhibUpdate && ![[controller tableController] isEditing]) {
        [controller resetData];
    }
}

- (void)removeContact {
    if(contact == NULL) {
//        [[PhoneMainView instance] popCurrentView];
//        return;
        contact=[tableController contact];
    }
    
        
    
    NSString *firstName = (NSString *)ABRecordCopyValue(contact, kABPersonFirstNameProperty) ;
    NSString *lastName = (NSString *)ABRecordCopyValue(contact, kABPersonLastNameProperty) ;
    
    ABMultiValueRef phones = (NSString *)ABRecordCopyValue(contact, kABPersonPhoneProperty) ;
    NSString* mobile=@"";
    NSString* mobileLabel;
    for (CFIndex i = 0; i < ABMultiValueGetCount(phones); i++) {
        mobileLabel = (NSString *)ABMultiValueCopyLabelAtIndex(phones, i);
        NSLog (@"%@",mobileLabel);
        if ([mobileLabel isEqualToString:@"_$!<Mobile>!$_"]) {
            mobile = (NSString*)ABMultiValueCopyValueAtIndex(phones,i);
            break;
        }
      
    }
    NSString *name=nil;
    if ([firstName length]!=0&& [lastName length]!=0)
    {
     name=[NSString stringWithFormat:@"%@ %@",firstName,lastName];
    }
    else if ([lastName length]!=0)
             name=[NSString stringWithFormat:@"%@",lastName];
    else if ([firstName length]!=0)
        name=[NSString stringWithFormat:@"%@",firstName];
    NSLog(@"contact %@,%@",name,mobile);
    // Remove contact from book
    if(ABRecordGetRecordID(contact) != kABRecordInvalidID) {
        NSError* error = NULL;
        ABAddressBookRemoveRecord(addressBook, contact, (CFErrorRef*)&error);
        if (error != NULL) {
            [LinphoneLogger log:LinphoneLoggerError format:@"Remove contact %p: Fail(%@)", contact, [error localizedDescription]];
        } else {
            [LinphoneLogger logc:LinphoneLoggerLog format:"Remove contact %p: Success!", contact];
            // Save address book
            error = NULL;
            inhibUpdate = TRUE;
            ABAddressBookSave(addressBook, (CFErrorRef*)&error);
            inhibUpdate = FALSE;
            if (error != NULL) {
                [LinphoneLogger log:LinphoneLoggerError format:@"Save AddressBook: Fail(%@)", [error localizedDescription]];
            } else {
                [LinphoneLogger logc:LinphoneLoggerLog format:"Save AddressBook: Success!"];
                
                //Remove Contact
                LinphoneAppDelegate *appDelegate = (LinphoneAppDelegate *)[[UIApplication sharedApplication] delegate];
                UserAccount *afriCallUserBal= [[UserAccount alloc] init];
                afriCallUserBal.email = appDelegate.afriCallUser.email;
                afriCallUserBal.firsPasswd=appDelegate.afriCallUser.firsPasswd;
                
                NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
                NSString *email=[defaults objectForKey:@"email"];
                NSString *firsPasswd=[defaults objectForKey:@"firsPasswd"];
                afriCallUserBal.email =email;
                afriCallUserBal.firsPasswd=firsPasswd;
                NSString *post =[[NSString alloc] initWithFormat:@"login=%@&password=%@&nom=%@&numero=%@",email,firsPasswd,name,mobile];
                NSLog(@"PostData: %@",post);
                
                NSURL *url=[NSURL URLWithString:@"https://www.africallshop.com/api/delete_contact_ios.php"];
                
                NSData *postData = [post dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];
                
                NSString *postLength = [NSString stringWithFormat:@"%d", [postData length]];
                
                NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
                [request setURL:url];
                [request setHTTPMethod:@"POST"];
                [request setValue:postLength forHTTPHeaderField:@"Content-Length"];
                [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
                [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
                [request setHTTPBody:postData];
                NSError *error = [[NSError alloc] init];
                NSHTTPURLResponse *response = nil;
                NSData *urlData=[NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
                
                NSLog(@"Response code: %d", [response statusCode]);
                if ([response statusCode] >=200 && [response statusCode] <300)
                {
                    NSString *responseData = [[NSString alloc]initWithData:urlData encoding:NSUTF8StringEncoding];
                    
                    NSLog(@"Response ==> %@", responseData);
                    if ([responseData isEqualToString:@"OK"]) {
                        NSLog(@"Contact removed");
                    }
                }
        }
        
        contact = NULL;
        
       
        }
    }else
    {
        //Remove Contact
        LinphoneAppDelegate *appDelegate = (LinphoneAppDelegate *)[[UIApplication sharedApplication] delegate];
        UserAccount *afriCallUserBal= [[UserAccount alloc] init];
        afriCallUserBal.email = appDelegate.afriCallUser.email;
        afriCallUserBal.firsPasswd=appDelegate.afriCallUser.firsPasswd;
        
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        NSString *email=[defaults objectForKey:@"email"];
        NSString *firsPasswd=[defaults objectForKey:@"firsPasswd"];
        afriCallUserBal.email =email;
        afriCallUserBal.firsPasswd=firsPasswd;
        NSString *post =[[NSString alloc] initWithFormat:@"login=%@&password=%@&nom=%@&numero=%@",email,firsPasswd,name,mobile];
        NSLog(@"PostData: %@",post);
        
        NSURL *url=[NSURL URLWithString:@"https://www.africallshop.com/api/delete_contact_ios.php"];
        
        NSData *postData = [post dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];
        
        NSString *postLength = [NSString stringWithFormat:@"%d", [postData length]];
        
        NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
        [request setURL:url];
        [request setHTTPMethod:@"POST"];
        [request setValue:postLength forHTTPHeaderField:@"Content-Length"];
        [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
        [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
        [request setHTTPBody:postData];
        NSError *error = [[NSError alloc] init];
        NSHTTPURLResponse *response = nil;
        NSData *urlData=[NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
        
        NSLog(@"Response code: %d", [response statusCode]);
        if ([response statusCode] >=200 && [response statusCode] <300)
        {
            NSString *responseData = [[NSString alloc]initWithData:urlData encoding:NSUTF8StringEncoding];
            
            NSLog(@"Response ==> %@", responseData);
            if ([responseData isEqualToString:@"OK"]) {
                NSLog(@"Contact removed");
            }
        }   
    }
}

- (void)saveData {
    if(contact == NULL) {
        [[PhoneMainView instance] popCurrentView];
        return;
    }
    BOOL editMode;
    NSString *name=@"";
    NSString *mobile=@"";
    
    // Add contact to book
    NSError* error = NULL;
    if(ABRecordGetRecordID(contact) == kABRecordInvalidID) {
        ABAddressBookAddRecord(addressBook, contact, (CFErrorRef*)&error);
        if (error != NULL) {
            [LinphoneLogger log:LinphoneLoggerError format:@"Add contact %p: Fail(%@)", contact, [error localizedDescription]];
        } else {
            [LinphoneLogger logc:LinphoneLoggerLog format:"Add contact %p: Success!", contact];
            
            NSString *firstName = (NSString *)ABRecordCopyValue(contact, kABPersonFirstNameProperty) ;
            NSString *lastName = (NSString *)ABRecordCopyValue(contact, kABPersonLastNameProperty) ;
            
            ABMultiValueRef phones = (NSString *)ABRecordCopyValue(contact, kABPersonPhoneProperty) ;
            NSString* mobileLabel;
            for (CFIndex i = 0; i < ABMultiValueGetCount(phones); i++) {
                mobileLabel = (NSString *)ABMultiValueCopyLabelAtIndex(phones, i);
                NSLog (@"%@",mobileLabel);
                if ([mobileLabel isEqualToString:@"_$!<Mobile>!$_"]) {
                    mobile = (NSString*)ABMultiValueCopyValueAtIndex(phones,i);
                    break;
                }
            }
            if ([firstName length]!=0&& [lastName length]!=0)
            {
                name=[NSString stringWithFormat:@"%@ %@",firstName,lastName];
            }
            else if ([lastName length]!=0)
                name=[NSString stringWithFormat:@"%@",lastName];
            else if ([firstName length]!=0)
                name=[NSString stringWithFormat:@"%@",firstName];
            NSLog(@"contact %@,%@",name,mobile);
            editMode=NO;
        }
    }
    else
    {
        editMode=YES;
    }
    
    // Save address book
    error = NULL;
    inhibUpdate = TRUE;
    ABAddressBookSave(addressBook, (CFErrorRef*)&error);
    inhibUpdate = FALSE;
    if (error != NULL) {
        [LinphoneLogger log:LinphoneLoggerError format:@"Save AddressBook: Fail(%@)", [error localizedDescription]];
    } else {
        [LinphoneLogger logc:LinphoneLoggerLog format:"Save AddressBook: Success!"];
        
        if(editMode)
        {
            NSString *firstName = (NSString *)ABRecordCopyValue(contact, kABPersonFirstNameProperty) ;
            NSString *lastName = (NSString *)ABRecordCopyValue(contact, kABPersonLastNameProperty) ;
            
            ABMultiValueRef phones = (NSString *)ABRecordCopyValue(contact, kABPersonPhoneProperty) ;
            NSString* mobileLabel;
            for (CFIndex i = 0; i < ABMultiValueGetCount(phones); i++) {
                mobileLabel = (NSString *)ABMultiValueCopyLabelAtIndex(phones, i);
                NSLog (@"%@",mobileLabel);
                if ([mobileLabel isEqualToString:@"_$!<Mobile>!$_"]) {
                    mobile = (NSString*)ABMultiValueCopyValueAtIndex(phones,i);
                    break;
                }
            }
            if ([firstName length]!=0&& [lastName length]!=0)
            {
                name=[NSString stringWithFormat:@"%@ %@",firstName,lastName];
            }
            else if ([lastName length]!=0)
                name=[NSString stringWithFormat:@"%@",lastName];
            else if ([firstName length]!=0)
                name=[NSString stringWithFormat:@"%@",firstName];
            
            NSLog(@"old contact %@,%@",contactOldNom,contactOldMobile);
            NSLog(@"contact %@,%@",name,mobile);
            editMode=YES;
            
            //Edit Contact
            LinphoneAppDelegate *appDelegate = (LinphoneAppDelegate *)[[UIApplication sharedApplication] delegate];
            UserAccount *afriCallUserBal= [[UserAccount alloc] init];
            afriCallUserBal.email = appDelegate.afriCallUser.email;
            afriCallUserBal.firsPasswd=appDelegate.afriCallUser.firsPasswd;
            
            NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
            NSString *email=[defaults objectForKey:@"email"];
            NSString *firsPasswd=[defaults objectForKey:@"firsPasswd"];
            afriCallUserBal.email =email;
            afriCallUserBal.firsPasswd=firsPasswd;
            NSString *post =[[NSString alloc] initWithFormat:@"login=%@&password=%@&nom=%@&numero=%@&old_nom=%@&old_numero=%@",email,firsPasswd,name,mobile,contactOldNom,contactOldMobile];
            NSLog(@"PostData: %@",post);
            
            NSURL *url=[NSURL URLWithString:@"https://www.africallshop.com/api/edit_contact_ios.php"];
            
            NSData *postData = [post dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];
            
            NSString *postLength = [NSString stringWithFormat:@"%d", [postData length]];
            
            NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
            [request setURL:url];
            [request setHTTPMethod:@"POST"];
            [request setValue:postLength forHTTPHeaderField:@"Content-Length"];
            [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
            [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
            [request setHTTPBody:postData];
            NSError *error = [[NSError alloc] init];
            NSHTTPURLResponse *response = nil;
            NSData *urlData=[NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
            
            NSLog(@"Response code: %d", [response statusCode]);
            if ([response statusCode] >=200 && [response statusCode] <300)
            {
                NSString *responseData = [[NSString alloc]initWithData:urlData encoding:NSUTF8StringEncoding];
                
                NSLog(@"Response ==> %@", responseData);
                if ([responseData isEqualToString:@"OK"]) {
                    NSLog(@"Contact edited");
                }
            }
            
        }
        else
        {
            //Add new Contact
            LinphoneAppDelegate *appDelegate = (LinphoneAppDelegate *)[[UIApplication sharedApplication] delegate];
            UserAccount *afriCallUserBal= [[UserAccount alloc] init];
            afriCallUserBal.email = appDelegate.afriCallUser.email;
            afriCallUserBal.firsPasswd=appDelegate.afriCallUser.firsPasswd;
            
            NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
            NSString *email=[defaults objectForKey:@"email"];
            NSString *firsPasswd=[defaults objectForKey:@"firsPasswd"];
            afriCallUserBal.email =email;
            afriCallUserBal.firsPasswd=firsPasswd;
            NSString *post =[[NSString alloc] initWithFormat:@"login=%@&password=%@&nom=%@&numero=%@",email,firsPasswd,name,mobile];
            NSLog(@"PostData: %@",post);
            
            NSURL *url=[NSURL URLWithString:@"https://www.africallshop.com/api/add_contact_ios.php"];
            
            NSData *postData = [post dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];
            
            NSString *postLength = [NSString stringWithFormat:@"%d", [postData length]];
            
            NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
            [request setURL:url];
            [request setHTTPMethod:@"POST"];
            [request setValue:postLength forHTTPHeaderField:@"Content-Length"];
            [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
            [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
            [request setHTTPBody:postData];
            NSError *error = [[NSError alloc] init];
            NSHTTPURLResponse *response = nil;
            NSData *urlData=[NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
            
            NSLog(@"Response code: %d", [response statusCode]);
            if ([response statusCode] >=200 && [response statusCode] <300)
            {
                NSString *responseData = [[NSString alloc]initWithData:urlData encoding:NSUTF8StringEncoding];
                
                NSLog(@"Response ==> %@", responseData);
                if ([responseData isEqualToString:@"OK"]) {
                    NSLog(@"Contact added");
                }
            }
            
        }
    }
}

- (void)newContact {
    [LinphoneLogger logc:LinphoneLoggerLog format:"New contact"];
    contact = NULL;
    [self resetData];
    contact = ABPersonCreate();
    [tableController setContact:contact];
    [self enableEdit:FALSE];
    [[tableController tableView] reloadData];
}

- (void)newContact:(NSString*)address {
    [LinphoneLogger logc:LinphoneLoggerLog format:"New contact"];
    contact = NULL;
    [self resetData];
    contact = ABPersonCreate();
    [tableController setContact:contact];
    if ([[LinphoneManager instance] lpConfigBoolForKey:@"show_contacts_emails_preference"] == true) {
        LinphoneAddress *linphoneAddress = linphone_address_new([address cStringUsingEncoding:[NSString defaultCStringEncoding]]);
        NSString *username = [NSString stringWithUTF8String:linphone_address_get_username(linphoneAddress)];
        if ([username rangeOfString:@"@"].length > 0) {
            [tableController addEmailField:username];
        } else {
            [tableController addSipField:address];
        }
        linphone_address_destroy(linphoneAddress);
    } else {
        [tableController addNumberField:address];
    }
    [self enableEdit:FALSE];
    [[tableController tableView] reloadData];
}

- (void)editContact:(ABRecordRef)acontact {
    [LinphoneLogger logc:LinphoneLoggerLog format:"Edit contact %p", acontact];
    contact = NULL;
    [self resetData];
    contact = ABAddressBookGetPersonWithRecordID(addressBook, ABRecordGetRecordID(acontact));
    [tableController setContact:contact];
    [self enableEdit:FALSE];
    [[tableController tableView] reloadData];
}

- (void)editContact:(ABRecordRef)acontact address:(NSString*)address {
    [LinphoneLogger logc:LinphoneLoggerLog format:"Edit contact %p", acontact];
    contact = NULL;
    [self resetData];
    contact = ABAddressBookGetPersonWithRecordID(addressBook, ABRecordGetRecordID(acontact));
    if(contact)
    {
        [tableController setContact:contact];
    }
    else
    {
        [tableController setContact:acontact];
    }
    if ([[LinphoneManager instance] lpConfigBoolForKey:@"show_contacts_emails_preference"] == true) {
        LinphoneAddress *linphoneAddress = linphone_address_new([address cStringUsingEncoding:[NSString defaultCStringEncoding]]);
        NSString *username = [NSString stringWithUTF8String:linphone_address_get_username(linphoneAddress)];
        if ([username rangeOfString:@"@"].length > 0) {
            [tableController addEmailField:username];
        } else {
            [tableController addSipField:address];
        }
        linphone_address_destroy(linphoneAddress);
    } else {
        [tableController addSipField:address];
    }
    [self enableEdit:FALSE];
    [[tableController tableView] reloadData];
}


#pragma mark - Property Functions

- (void)setContact:(ABRecordRef)acontact {
    [LinphoneLogger logc:LinphoneLoggerLog format:"Set contact %p", acontact];
    contact = NULL;
    [self resetData];
    contact = ABAddressBookGetPersonWithRecordID(addressBook, ABRecordGetRecordID(acontact));
    if(contact)
    {
        [tableController setContact:contact];
    }
    else
    {
        [tableController setContact:acontact];
    }
    
}


#pragma mark - ViewController Functions

- (void)viewDidLoad{
    [super viewDidLoad];
    
    // Set selected+over background: IB lack !
    [editButton setBackgroundImage:[UIImage imageNamed:@"contact_ok_over.png"]
                forState:(UIControlStateHighlighted | UIControlStateSelected)];
    
    // Set selected+disabled background: IB lack !
    [editButton setBackgroundImage:[UIImage imageNamed:@"contact_ok_disabled.png"]
                forState:(UIControlStateDisabled | UIControlStateSelected)];
    
    [LinphoneUtils buttonFixStates:editButton];

    [tableController.tableView setBackgroundColor:[UIColor clearColor]]; // Can't do it in Xib: issue with ios4
    [tableController.tableView setBackgroundView:nil]; // Can't do it in Xib: issue with ios4
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    if ([[UIDevice currentDevice].systemVersion doubleValue] < 5.0) {
        [tableController viewWillDisappear:animated];
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if([ContactSelection getSelectionMode] == ContactSelectionModeEdit ||
       [ContactSelection getSelectionMode] == ContactSelectionModeNone) {
        [editButton setHidden:FALSE];
    } else {
        [editButton setHidden:TRUE];
    }
    if ([[UIDevice currentDevice].systemVersion doubleValue] < 5.0) {
        [tableController viewWillAppear:animated];
    }   
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if ([[UIDevice currentDevice].systemVersion doubleValue] < 5.0) {
        [tableController viewDidAppear:animated];
    }   
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    if ([[UIDevice currentDevice].systemVersion doubleValue] < 5.0) {
        [tableController viewDidDisappear:animated];
    }  
}


#pragma mark - UICompositeViewDelegate Functions

static UICompositeViewDescription *compositeDescription = nil;

+ (UICompositeViewDescription *)compositeViewDescription {
    if(compositeDescription == nil) {
        compositeDescription = [[UICompositeViewDescription alloc] init:@"ContactDetails" 
                                                                content:@"ContactDetailsViewController" 
                                                               stateBar:nil 
                                                        stateBarEnabled:false 
                                                                 tabBar:@"UIMainBar" 
                                                          tabBarEnabled:true 
                                                             fullscreen:false
                                                          landscapeMode:[LinphoneManager runningOnIpad]
                                                           portraitMode:true];
    }
    return compositeDescription;
}


#pragma mark -

- (void)enableEdit:(BOOL)animated {
    if (contact==NULL) {
        contact=[tableController contact];
    }
    NSString *oldfirstName = (NSString *)ABRecordCopyValue(contact, kABPersonFirstNameProperty) ;
    NSString *oldlastName = (NSString *)ABRecordCopyValue(contact, kABPersonLastNameProperty) ;
    
    ABMultiValueRef phones = (NSString *)ABRecordCopyValue(contact, kABPersonPhoneProperty) ;
    NSString* mobileLabel;
    for (CFIndex i = 0; i < ABMultiValueGetCount(phones); i++) {
        mobileLabel = (NSString *)ABMultiValueCopyLabelAtIndex(phones, i);
        NSLog (@"%@",mobileLabel);
        if ([mobileLabel isEqualToString:@"_$!<Mobile>!$_"]) {
            contactOldMobile = (NSString*)ABMultiValueCopyValueAtIndex(phones,i);
            break;
        }
    }
    if ([oldfirstName length]!=0&& [oldlastName length]!=0)
    {
        contactOldNom=[NSString stringWithFormat:@"%@ %@",oldfirstName,oldlastName];
    }
    else if ([oldlastName length]!=0)
        contactOldNom=[NSString stringWithFormat:@"%@",oldlastName];
    else if ([oldfirstName length]!=0)
        contactOldNom=[NSString stringWithFormat:@"%@",oldfirstName];
    NSLog(@"old contact %@,%@",contactOldNom,contactOldMobile);
    [contactOldNom retain];
    [contactOldMobile retain];
    if(![tableController isEditing]) {
        [tableController setEditing:TRUE animated:animated];
    }
    [editButton setOn];
    [cancelButton setHidden:FALSE];
    [backButton setHidden:TRUE];
}

- (void)disableEdit:(BOOL)animated {
    if([tableController isEditing]) {
        [tableController setEditing:FALSE animated:animated];
    }
    [editButton setOff];
    [cancelButton setHidden:TRUE];
    [backButton setHidden:FALSE];
}


#pragma mark - Action Functions

- (IBAction)onCancelClick:(id)event {
    [self disableEdit:TRUE];
    [self resetData];
}

- (IBAction)onBackClick:(id)event {
    if([ContactSelection getSelectionMode] == ContactSelectionModeEdit) {
        [ContactSelection setSelectionMode:ContactSelectionModeNone];
    }
    [[PhoneMainView instance] popCurrentView];
}

- (IBAction)onEditClick:(id)event {
    if([tableController isEditing]) {
        if([tableController isValid]) {
            [self disableEdit:TRUE];
            [self saveData];
        }
    } else {
        [self enableEdit:TRUE];
    }
}

- (void)onRemove:(id)event {
    //[self disableEdit:FALSE];
    [self disableEdit:TRUE];
    [self removeContact];
    [[PhoneMainView instance] popCurrentView];
}

- (void)onModification:(id)event {
    if(![tableController isEditing] || [tableController isValid]) {
        [editButton setEnabled:TRUE];
    } else {
        [editButton setEnabled:FALSE];
    }
}

@end
